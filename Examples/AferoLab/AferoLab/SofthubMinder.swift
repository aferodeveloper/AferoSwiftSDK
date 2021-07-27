//
//  AferoSofthubMinder.swift
//  iTokui
//
//  Created by Justin Middleton on 11/18/15.
//  Copyright © 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import CocoaLumberjack
import Afero

extension UserDefaults {
    
    var enableSofthub: Bool {
        get {
            return bool(forKey: "enableSofthub") 
        }
        
        set {
            set(newValue, forKey: "enableSofthub")
        }
    }
    
    
}

extension DeviceModelable {
    
    var isLocalSofthub: Bool {
        return deviceId == Softhub.shared.deviceId
    }
    
}

@objcMembers class SofthubMinder: NSObject {
    
    static let sharedInstance = SofthubMinder()
    
    fileprivate var shouldStopAferoSofthubInBackground: Bool = true {

        didSet {
            if !shouldStopAferoSofthubInBackground { return }
            
            if UIApplication.shared.applicationState == .background {
                stopAferoSofthub()
            }
        }
    }
    
    fileprivate var backgroundNotificationObserver: NSObjectProtocol? = nil {
        willSet {
            if let backgroundNotificationObserver = backgroundNotificationObserver {
                NotificationCenter.default.removeObserver(backgroundNotificationObserver)
            }
        }
    }

    fileprivate var foregroundNotificationObserver: NSObjectProtocol? = nil {
        willSet {
            if let foregroundNotificationObserver = foregroundNotificationObserver {
                NotificationCenter.default.removeObserver(foregroundNotificationObserver)
            }
        }
    }
    
    fileprivate var preferencesChangedObserver: NSObjectProtocol? = nil {
        willSet {
            if let preferencesChangedObserver = preferencesChangedObserver {
                NotificationCenter.default.removeObserver(preferencesChangedObserver)
            }
        }
    }
    
    fileprivate var otaStateObs: NSKeyValueObservation?
    
    var TAG: String { return "AferoSofthubMinder" }

    @available(*, deprecated, message: "Use start(withAccountId:apiHost:mode:logLevel:hardwareIdentifier:setupModeDeviceDetectedHandler) instead.")
    // TODO: When removing this, remove the below extension on SofthubProfileType as well.
    func start(
        withAccountId accountId: String,
        cloud: SofthubProfileType = .prod,
        mode: SofthubType = .enterprise,
        logLevel: SofthubLogLevel = .verbose,
        hardwareIdentifier: String? = UserDefaults.standard.clientIdentifier,
        setupModeDeviceDetectedHandler: @escaping SofthubSetupModeDeviceDetectedHandler = {
            deviceId, associationId, profileVersion in
            DDLogInfo("Softhub detected setup mode deviceId:\(deviceId) associationId:\(associationId) profileVersion:\(profileVersion)");
            },
        associationNeededHandler: @escaping SofthubAssociationHandler
        ) throws {
        
        try start(
            withAccountId: accountId,
            apiHost: cloud.apiHost,
            mode: mode,
            profileType: cloud,
            logLevel: logLevel,
            hardwareIdentifier: hardwareIdentifier,
            setupModeDeviceDetectedHandler: setupModeDeviceDetectedHandler,
            associationNeededHandler: associationNeededHandler
        )
    }
    
    /// Start the softhub.
    ///
    /// - parameter accountId: The `id` of the account to which to associate.
    /// - parameter mode: How the softhub should behave. **NOTE: Unless explicitly instructed
    ///   by Afero, this must be `.enterprise` (the default).
    /// - parameter logLevel: The verbosity level of logging.
    /// - parameter hardwareIdentifier: A UUID uniquely identifying this client. Note that
    ///   this should be the same as the `clientIdentifier` used to log in to Conclave.
    /// - parameter associationNeededHandler: A callback used by the softhub to associate
    ///   the softhub to the account if needed.
    ///
    /// > **NOTE:**
    /// >
    /// > See `AccountViewController.softhubEnabled { didSet }` for an example of implementing
    /// > the `associationNeededHandler`.
    
    func start(
        withAccountId accountId: String,
        apiHost: String,
        mode: SofthubType = .enterprise,
        profileType: SofthubProfileType = .prod,
        logLevel: SofthubLogLevel = .info,
        hardwareIdentifier: String? = UserDefaults.standard.clientIdentifier,
        setupModeDeviceDetectedHandler: @escaping SofthubSetupModeDeviceDetectedHandler = {
            deviceId, associationId, profileVersion in
            DDLogInfo("Softhub detected setup mode deviceId:\(deviceId) associationId:\(associationId) profileVersion:\(profileVersion)");
            },
        associationNeededHandler: @escaping SofthubAssociationHandler
        ) throws {
        
        otaStateObs = Softhub.shared.observe(\.activeOTACount) {
            [weak self] hub, chg in
            self?.shouldStopAferoSofthubInBackground = (hub.activeOTACount == 0)
        }
        
        backgroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main) {
                [weak self] _ in
                if self?.shouldStopAferoSofthubInBackground ?? false {
                    self?.stopAferoSofthub()
                }
                self?.preferencesChangedObserver = nil
        }
        
        foregroundNotificationObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil, queue: .main) {
            
            [weak self] _ in
            
            self?.startAferoSofthub(withAccountId: accountId, apiHost: apiHost, using: profileType, mode: mode, logLevel: logLevel, associationNeededHandler: associationNeededHandler)
            
            self?.preferencesChangedObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                
                [weak self] _ in
                
                if UserDefaults.standard.enableSofthub {
                    self?.startAferoSofthub(withAccountId: accountId, apiHost: apiHost, using: profileType, logLevel: logLevel, associationNeededHandler: associationNeededHandler, setupModeDeviceDetectedHandler: setupModeDeviceDetectedHandler)
                    return
                }
                self?.stopAferoSofthub()
            }
        }
        
        startAferoSofthub(
            withAccountId: accountId,
            apiHost: apiHost,
            using: profileType,
            mode: mode,
            logLevel: logLevel,
            hardwareIdentifier: hardwareIdentifier,
            associationNeededHandler: associationNeededHandler,
            setupModeDeviceDetectedHandler: setupModeDeviceDetectedHandler
        )

    }
    
    /// Tell the softhub that association has been completed.
    ///
    /// This is required after a successful call to the Afero Client API to associate
    /// on behalf of the softhub (notably in cases where the softhub performs a live
    /// reassociate if its cloud representation is deleted.
    ///
    /// - note: This simply proxies the vended API on `Softhub`.

    func notifyAssociationCompleted(with status: SofthubAssociationStatus) {
        Softhub.shared.notifyAssociationCompleted(with: status)
    }
    
    func stop() {
        backgroundNotificationObserver = nil
        foregroundNotificationObserver = nil
        self.stopAferoSofthub()
    }
    
    fileprivate var hubbyStarted: Bool {
        return Softhub.shared.state ∈ [.starting, .started]
    }
    
    fileprivate func startAferoSofthub(
        withAccountId accountId: String,
        apiHost: String,
        using profileType: SofthubProfileType = .prod,
        mode behavingAs: SofthubType = .enterprise,
        logLevel: SofthubLogLevel,
        hardwareIdentifier: String? = nil,
        associationNeededHandler: @escaping SofthubAssociationHandler,
        setupModeDeviceDetectedHandler: @escaping SofthubSetupModeDeviceDetectedHandler = {
            deviceId, associationId, profileVersion in
            DDLogInfo("Softhub detected setup mode deviceId:\(deviceId) associationId:\(associationId) profileVersion:\(profileVersion)");
        }
    ) {
        
        if hubbyStarted { return }
        
        if !UserDefaults.standard.enableSofthub {
            DDLogInfo("Softhub disabled; not starting hubby.")
            return
        }
        
        Softhub.shared.start(
            with: accountId,
            apiHost: apiHost,
            using: profileType,
            behavingAs: behavingAs,
            identifiedBy: hardwareIdentifier,
            logLevel: logLevel,
            associationHandler: associationNeededHandler,
            setupModeDeviceDetectedHandler: setupModeDeviceDetectedHandler,
            completionHandler: {
            completionReason in
                DDLogInfo("Softhub stopped with status \(String(reflecting: completionReason))")
            }
        )
        
    }
    
    fileprivate func stopAferoSofthub() {
        Softhub.shared.stop()
    }
    
}

extension SofthubProfileType {
    public var apiHost: String {
        switch self {
        case .prod: return "api.afero.io"
        case .dev: return "api.dev.afero.io"
        }
    }
}

