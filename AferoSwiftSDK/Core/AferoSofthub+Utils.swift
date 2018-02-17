//
//  AferoSofthub+Utils.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 1/29/18.
//

import Foundation
import AferoSofthub


extension AferoSofthubError:  Error {

    public var localizedDescription: String {
        switch self {
        case .conclaveAccessEncoding: return "Conclave access token uses unrecognized encoding."
        case .invalidRSSIDecibelValue: return "Unrecognized RSSI decibel value"
        case .invalidStateForCmd: return "The softhub was asked to perform a command while in an invalid state. See AferoSofthub.state for current value."
        }
    }
    
}

extension AferoSofthubState: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .starting: return "Softhub starting."
        case .started: return "Softhub started."
        case .stopping: return "Softhub stopping."
        case .stopped: return "Softhub stopped."
        }
    }
    
    public var debugDescription: String {
        return "<AferoSofthubState> \(rawValue): \(description)"
    }
    
}

extension AferoSofthubCompleteReason: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .stopCalled: return "Softhub stopped as requested."
        case .missingSofthubSetupPath: return "Run was called without the ConfigName::SOFT_HUB_SETUP_PATH config value being set."
        case .setupFailed: return "The setup process for the embedded softhub has failed. (no other reason given)."
        case .fileIOError: return "I/O Error reading config values."
        case .unhandledService: return "Asked to start with an unrecognized Afero cloud."
        }
    }
    
    public var debugDescription: String {
        return "<AferoSofthubCompleteReason> \(rawValue): \(description)"
    }
    
}

extension AferoService: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .prod: return "Afero production cloud"
        case .dev: return "Afero development cloud"
        }
    }

    public var debugDescription: String {
        return "<AferoService> \(rawValue): \(description)"
    }

}

/// The Afero cloud to which a softhub should attempt to connect.
/// For production applications, this should always be `.prod`.
///
/// # Cases
///
/// * `.prod`: The Afero production cloud. Third parties should always use this.
/// * `.dev`: The Afero development cloud. Production apps and third parties should never use this.

@objc public enum SofthubCloud: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
    /// The Afero production cloud. Third parties should always use this.
    case prod = 0
    
    /// The Afero development cloud. Production apps and third parties should never use this.
    case dev = 1
    
    /// A unique identifier to use to identify the cloud setting (for, say, storage in UserDefaults).
    public var stringIdentifier: String {
        switch self {
        case .prod: return "prod"
        case .dev: return "dev"
        }
    }
    
    /// Initialize with an optional StringIdentifier. If the `stringIdentifier` is nil,
    /// or does not match a known `SofthubCloud.stringIdentifier`, fail initialization.
    public init?(stringIdentifier: String?) {
        guard let stringIdentifier = stringIdentifier else { return nil }
        switch stringIdentifier {
        case SofthubCloud.prod.stringIdentifier: self = .prod
        case SofthubCloud.dev.stringIdentifier: self = .dev
        default: return nil
        }
    }
    
    var aferoService: AferoService {
        return AferoService(rawValue: rawValue)!
    }
    
    public var description: String {
        return aferoService.description
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
    public static let allValues: [SofthubCloud] = [.prod, .dev]
    
}

@objc public enum SofthubType: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
    case consumer
    case enterprise
    
    var aferoSofthubType: AferoSofthubType {
        switch self {
        case .consumer: return .consumer
        case .enterprise: return .enterprise
        }
    }

    public var description: String {
        return aferoSofthubType.rawValue
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) (\(rawValue)): \(description)"
    }
    
}

/// The level at which the Softhub should log.

@objc public enum SofthubLogLevel: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
    case none = 0
    case error
    case warning
    case info
    case debug
    case verbose
    case trace
    
    var aferoSofthubLogLevel: AferoSofthubLogLevel {
        return AferoSofthubLogLevel(rawValue: rawValue)!
    }
    
    init(_ level: AferoSofthubLogLevel) {
        self.init(rawValue: level.rawValue)!
    }
    
    public var description: String {
        return "\(self)"
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
}

/// The current state of the softhub.

@objc public enum SofthubState: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
    case stopping = 0
    case stopped
    case starting
    case started
    
    var aferoSofthubState: AferoSofthubState {
        return AferoSofthubState(rawValue: rawValue)!
    }
    
    init(_ state: AferoSofthubState) {
        self.init(rawValue: state.rawValue)!
    }
    
    public var description: String {
        return aferoSofthubState.description
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
}

/// Reasons for the Softhub to stop running.

@objc public enum SofthubCompletionReason: Int, CustomStringConvertible, CustomDebugStringConvertible {

    case none = -1
    case stopCalled = 0
    case missingSetupPath
    case unhandledService
    case fileIOError
    case setupFailed
    
    var aferoSofthubCompleteReason: AferoSofthubCompleteReason {
        return AferoSofthubCompleteReason(rawValue: rawValue)!
    }
    
    init(_ cr: AferoSofthubCompleteReason) {
        self.init(rawValue: cr.rawValue)!
    }
    
    public var description: String {
        return aferoSofthubCompleteReason.description
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
}

/// A Swift wrapper around the Afero softhub software. This is the lowest-level
/// interface available to non-Afero developers.

@objcMembers public class Softhub: NSObject {
    
    /// The softhub is a shared singleton; this gives access to it.
    
    public static let shared = Softhub()
    
    /// The current state of the softhub. KVO-compliant.
    
    private(set) public dynamic var state: SofthubState = .stopped
    private var _softhubStateObs: NSKeyValueObservation?
    
    /// The reason the softhub most recently stopped (for the current process).
    /// - note Ideally this would be an `Optional<SofthubCompletionReason>` rather than
    ///        a `SofthubCompletionReason` with case `.none`. However, ints are bridged to
    ///        primitive types in objc, and primitives can't be nil.
    private(set) public dynamic var completionReason: SofthubCompletionReason = .none
    
    /// The required association id, if any. This will only be present
    /// when the softhub requires association; once we have a deviceId, this
    /// will revert to `nil`.
    private(set) public dynamic var associationId: String?
    
    /// The current deviceId, if any, of the softhub. KVO-compliant.
    ///
    /// This value can be used to identify the local softhub among devices
    /// in a `DeviceCollection`.
    
    /// - note: This value will be `nil` if the softhub is in any state
    ///         other than `.started`
    
    private(set) public dynamic var deviceId: String?
    private var _softhubDeviceIdObs: NSKeyValueObservation?
    
    /// The number of Over-The-Air peripheral device updates (firmware or profile)
    /// that are currently happening via this softhub.
    ///
    /// The Softhub can act as a conduit for OTA updates to peripheral
    /// devices. While the softhub not intended to run in the background
    /// normally, it is often desirable to allow it to run int he background
    /// when OTAs are active, and to stop it once they've completed.
    ///
    /// This value can be observed so that whichever class is managing the
    /// softhub lifecycle can determine if and when it's appropriate to
    /// keep the hub running or shut it down depending upon application state.
    ///
    /// - seealso: `SofthubMinder.swift` in the AferoLab example app.
    
    private(set) public dynamic var activeOTACount: Int = 0
    private var _softhubActiveOTACountObs: NSKeyValueObservation?
    
    private override init() {
        super.init()
        startObservingSofthubProperties()
    }
    
    private func startObservingSofthubProperties() {

        _softhubStateObs = AferoSofthub.sharedInstance().observe(\.state) {
            [weak self] hub, chg in
            self?.state = SofthubState(hub.state)
        }
        
        _softhubDeviceIdObs = AferoSofthub.sharedInstance().observe(\.deviceId) {
            [weak self] hub, chg in
            self?.associationId = nil
            self?.deviceId = hub.deviceId
        }

        _softhubDeviceIdObs = AferoSofthub.sharedInstance().observe(\.otaCount) {
            [weak self] hub, chg in
            self?.activeOTACount = hub.otaCount
        }

    }
    
    /// Ask the softhub to start.
    ///
    /// - parameter accountId: A string that is unique to the account to which the
    ///             softhub will be associated. An actual Afero account id is sufficient,
    ///             but any string unique to a given account will do. See **Associating**.
    ///
    /// - parameter cloud: The cloud to which to connect. Defaults to `.prod`, and should not
    ///             be changed for production applications.
    ///
    /// - parameter softhubType: Identifies the behavior a softhub should declar when it associates
    ///             with the service. Unless otherwise instructed by Afero, this should be
    ///             `.consumer`, the default. **This cannot be changed after a hub has been
    ///             associated**.
    ///
    /// - parameter identifier: A string which, if present, is added to the HUBBY_HARDWARE_INFO
    ///             attribute of the softhub's device representation. It can be used to distinguish
    ///             the local softhub from others.
    ///
    /// - parameter associationhandler: A callback which takes an `associationId` in the form of
    ///             a string, and performs a call against the appropriate Afero REST API
    ///             to associate.
    ///
    /// - parameter completionHandler: A callback called when the softhub stops. The reason
    ///             for stopping is provided as the sole parameter.
    ///
    /// # Overview
    ///
    /// The Afero Softhub runs on its own queue and provides a means for Afero peripheral devices
    /// to communicate with the Afero cloud using a mobile device's network connection
    /// (WiFi or cellular). It operates independent of other Afero SDK components,
    /// and the implementor need only start and stop the Softhub as appropriate.
    ///
    /// # Lifecycle
    ///
    /// The Afero Softhub attaches to an Afero account by acting as another device, and therefor
    /// must be associated with an account before it is able to communicate with
    /// physical Afero peripheral devices. Once associated, it saves its configuration
    /// so that subsequent starts against the same account do not require an association step.
    ///
    /// To accomplish association, the Softhub delegates device association to the caller
    /// of `start(with:using:identifiedBy:loglevel:associationHandler:completionHandler)`,
    /// via the `associationHandler: @escaping (String)->Void` parameter. It is expected
    /// that this invocation will result in a POST to the Afero client API:
    ///
    ///
    /// ```
    ///     POST https://api.afero.io/v1/accounts/$accountId$/devices
    /// ```
    ///
    /// The body of this request should be JSON-formatted, as such:
    /// ```
    /// { associationId: "ASSOCIATION_ID" }
    /// ```
    ///
    /// If an `AferoAPIClient` implementor is being used, such as `AFNetworkingAferoAPIClient`,
    /// then `associateDevice(with:to:locatedAt:ownershipTransferVerified:expansions)` can be used
    /// for this purpose. See `AferoAPIClient+Device.swift` for more info.
    ///
    /// Once a softhub has associated with an account,
    /// it saves its configuration info locally to a path determined in part by
    /// hashing the `accountId` value. Upon subsequent starts using the same `accountId`,
    /// the softhub will connect directly to the Afero service requiring association.
    /// For this reason, its highly desirable that the `accountId` parameter be the same
    /// for each account, and that it differ from one account to another. Afero recommends
    /// using an actual Afero account id, which is a UUID.
    
    public func start(
        with accountId: String,
        using cloud: SofthubCloud = .prod,
        behavingAs softhubType: SofthubType = .consumer,
        identifiedBy identifier: String? = nil,
        logLevel: SofthubLogLevel,
        associationHandler: @escaping (String)->Void,
        completionHandler: @escaping (SofthubCompletionReason)->Void
        ) {
        
        if [.starting, .started].contains(state) { return }
        
        let localAssociationHandler: AferoSofthubSecureHubAssociationHandler = {
            [weak self] associationId in
            self?.associationId = associationId
            associationHandler(associationId)
        }
        
        let localCompletionHandler: AferoSofthubCompleteReasonHandler = {
            [weak self] rawCompleteReason in
            let cr = SofthubCompletionReason(rawCompleteReason)
            self?.completionReason = cr
            completionHandler(cr)
        }
        
        completionReason = .none
        
        AferoSofthub.start(
            withAccountId: accountId,
            cloud: cloud.aferoService,
            softhubType: softhubType.aferoSofthubType,
            logLevel: logLevel.aferoSofthubLogLevel,
            hardwareIdentifier: identifier,
            associationHandler: localAssociationHandler,
            completionHandler: localCompletionHandler
        )
    }
    
    /// Stop the Softhub. The Softub will terminate immediately,
    /// and the `completionHandler` passed to `start(_:_:_:_:_:_:)` will be
    /// invoked with `SofthubCompletionReason.stopCalled`.
    ///
    /// Immediately upon calling this, `state` will change to `.stopping`, and
    /// once the `completionHandler` is called, `.stopped`.
    ///
    /// - seealso: `var state: SofthubState`
    
    public func stop() {
        if ![.started, .starting].contains(state) { return }
        AferoSofthub.stop()
    }
    
    
}
