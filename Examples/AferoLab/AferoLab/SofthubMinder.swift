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
import AferoSofthub
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

extension AferoSofthubCompleteReason: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .stopCalled:
            return "Stop called (\(rawValue))."
            
        case .missingSofthubSetupPath:
            return "Missing softhub setup path (\(rawValue))."
            
        case .unhandledService:
            return "Unhandled/unsupported Afero service (\(rawValue))."
            
        case .fileIOError:
            return "FileIO error loading config values (\(rawValue))"
            
        case .setupFailed:
            return "Setup/association failed (\(rawValue))"
        }
    }
}

extension DeviceModelable {
    
    var isLocalSofthub: Bool {
        return softhubHardwareInfo?.contains(UserDefaults.standard.clientIdentifier) ?? false
    }
    
}

class SofthubMinder: NSObject {
    
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
    
    fileprivate var otaProgressObserver: NSObjectProtocol? = nil {
        willSet {
            if let otaProgressObserver = otaProgressObserver {
                NotificationCenter.default.removeObserver(otaProgressObserver)
            }
        }
    }

    fileprivate var otaCompleteObserver: NSObjectProtocol? = nil {
        willSet {
            if let otaCompleteObserver = otaCompleteObserver {
                NotificationCenter.default.removeObserver(otaCompleteObserver)
            }
        }
    }
    
    var TAG: String { return "AferoSofthubMinder" }
    
    func start(
        withAccountId accountId: String,
        logLevel: AferoSofthubLogLevel = .info,
        hardwareIdentifier: String? = UserDefaults.standard.clientIdentifier,
        associationNeededHandler: @escaping AferoSofthubSecureHubAssociationHandler
        ) throws {
        
        otaProgressObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: AferoSofthubOTAInProgressNotification),
            object: nil, queue: .main) {
                [weak self] _ in
                self?.shouldStopAferoSofthubInBackground = false
        }
        
        otaCompleteObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: AferoSofthubOTACompleteNotification),
            object: nil, queue: .main) {
                [weak self] _ in
                self?.shouldStopAferoSofthubInBackground = true
        }

        backgroundNotificationObserver = NotificationCenter.default.addObserver(
            forName: .UIApplicationDidEnterBackground,
            object: nil, queue: .main) {
                [weak self] _ in
                if self?.shouldStopAferoSofthubInBackground ?? false {
                    self?.stopAferoSofthub()
                }
                self?.preferencesChangedObserver = nil
        }
        
        foregroundNotificationObserver = NotificationCenter.default.addObserver(
        forName: .UIApplicationWillEnterForeground,
        object: nil, queue: .main) {
            
            [weak self] _ in
            
            self?.startAferoSofthub(withAccountId: accountId, logLevel: logLevel, associationNeededHandler: associationNeededHandler)
            
            self?.preferencesChangedObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) {
                
                [weak self] _ in
                
                if UserDefaults.standard.enableSofthub {
                    self?.startAferoSofthub(withAccountId: accountId, logLevel: logLevel, associationNeededHandler: associationNeededHandler)
                    return
                }
                self?.stopAferoSofthub()
            }
        }
        
        startAferoSofthub(
            withAccountId: accountId,
            logLevel: logLevel,
            hardwareIdentifier: hardwareIdentifier,
            associationNeededHandler: associationNeededHandler
        )

    }
    
    func stop() {
        backgroundNotificationObserver = nil
        foregroundNotificationObserver = nil
        otaProgressObserver = nil
        otaCompleteObserver = nil
        self.stopAferoSofthub()
    }
    
    fileprivate var hubbyStarted: Bool {
        return AferoSofthub.state() ∈ [.starting, .started]
    }
    
    fileprivate func startAferoSofthub(
        withAccountId accountId: String,
        logLevel: AferoSofthubLogLevel,
        hardwareIdentifier: String? = nil,
        associationNeededHandler: @escaping AferoSofthubSecureHubAssociationHandler
        ) {
        
        if hubbyStarted { return }
        
        if !UserDefaults.standard.enableSofthub {
            DDLogInfo("Softhub disabled; not starting hubby.")
            return
        }
        
        AferoSofthub.start(
            withAccountId: accountId,
            logLevel: logLevel,
            hardwareIdentifier: hardwareIdentifier,
            associationHandler: associationNeededHandler
        ) {
            cr in
            DDLogInfo("Softhub stopped with status \(cr.rawValue)")
        }
        
    }
    
    fileprivate func stopAferoSofthub() {
        if !hubbyStarted { return }
        AferoSofthub.stop()
    }
    
}

