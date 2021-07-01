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

        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoSofthubError case \(rawValue)"
        #endif
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

        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoSofthubState case \(rawValue)"
        #endif
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
        case .setupFailedTransient: return "The setup process for the embedded softhub has failed due to a temporary issue."
        case .setupFailedPermanent: return "The setup process for the embedded softhub has failed permanently."
        case .fileIOError: return "I/O Error reading config values."
        case .unhandledService: return "Asked to start with an unrecognized Afero cloud."
        case .serviceIssue: return "There was a problem communicating with the Afero cloud."
        case .notSupported: return "The installed softhub is not compatible with the Afero cloud, and must be updated."
            
        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoSofthubCompleteReason case \(rawValue)"
        #endif
        }
    }
    
    public var debugDescription: String {
        return "<AferoSofthubCompleteReason> \(rawValue): \(description)"
    }
    
}

extension AferoSofthubProfileType: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .prod: return "Afero production cloud"
        case .dev: return "Afero development cloud"
        case .GKEHD: return "THD"
        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoService case \(rawValue)"
        #endif
            
        }
    }
    
    public var debugDescription: String {
        return "<AferoService> \(rawValue): \(description)"
    }
    
}

@available(*, deprecated, renamed: "SofthubProfileType")
public typealias SofthubCloud = SofthubProfileType

/// The Afero cloud to which a softhub should attempt to connect.
/// For production applications, this should always be `.prod`.
///
/// # Cases
///
/// * `.prod`: The Afero production cloud. Third parties should always use this.
/// * `.dev`: The Afero development cloud. Production apps and third parties should never use this.

@objc public enum SofthubProfileType: Int, CustomStringConvertible, CustomDebugStringConvertible {
    
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
        switch stringIdentifier.lowercased() {
        case SofthubProfileType.prod.stringIdentifier.lowercased(): self = .prod
        case SofthubProfileType.dev.stringIdentifier.lowercased(): self = .dev
        default: return nil
        }
    }
    
    var aferoProfileType: AferoSofthubProfileType {
        return AferoSofthubProfileType(rawValue: rawValue)!
    }
    
    public var description: String {
        return aferoProfileType.description
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
    public static let allValues: [SofthubProfileType] = [.prod, .dev]
    
}

@objc public enum SofthubType: Int, CustomStringConvertible, CustomDebugStringConvertible {

    /// NOTE: This is a deprecated case; unless explicitly instructed by Afero,
    /// use `.enterprise`.
    case consumer

    case enterprise
    
    var aferoSofthubType: AferoSofthubType { .enterprise }
    
    public var description: String {
        return aferoSofthubType.rawValue
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) (\(rawValue)): \(description)"
    }
    
}

/// The level at which the Softhub should log.

public typealias SofthubLogLevel = AferoSofthubLogLevel

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
    case setupFailedTransient
    case setupFailedPermanent
    case serviceIssue
    case notSupported
    
    private var aferoSofthubCompleteReason: AferoSofthubCompleteReason {
        return AferoSofthubCompleteReason(rawValue: rawValue)!
    }
    
    init(_ cr: AferoSofthubCompleteReason) {
        self.init(rawValue: cr.rawValue)!
    }
    
    public var description: String {
        switch self {
        case .none: return "<none>"
        default: return aferoSofthubCompleteReason.description
        }
        
    }
    
    public var debugDescription: String {
        return "\(type(of: self)) \(rawValue): \(description)"
    }
    
}

public typealias SofthubAssociationHandler = (String) -> Void
public typealias SofthubAssociationStatus = AferoSofthubAssociationStatus

public typealias SofthubSetupModeDeviceDetectedHandler = AferoSofthubSetupModeDeviceDetectedHandler

/// A Swift wrapper around the Afero softhub software. This is the lowest-level
/// interface available to non-Afero developers.

@objcMembers public class Softhub: NSObject {
    
    /// The softhub is a shared singleton; this gives access to it.
    
    public static let shared = Softhub()
    
    /// The internal build version of the softhub. This relates to and internal Afero
    /// build number, and may differ from release tag identified in distribution
    /// version control.
    
    public var version: String { return AferoSofthubVersion }
    
    /// The internal build version of the softhub. This relates to and internal Afero
    /// build number, and may differ from release tag identified in distribution
    /// version control.
    
    public static var Version: String { return AferoSofthubVersion }
    
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
        
        _softhubActiveOTACountObs = AferoSofthub.sharedInstance().observe(\.otaCount) {
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
    /// - parameter apiHost: The hostname of the Afero ClientAPI.
    ///
    /// - parameter profileType: The type of profile to use. Unless otherwise stated, this should
    ///             always be `.prod` (the default).
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
    /// - parameter associationHandler: A callback in the form `(String associationId, ()->Void onDone) -> Void`.
    ///             * The `associationId` is to be used in a call to the
    ///             appropriate Afero REST API to associate a device.
    ///             * **AFTER** that has completed with a 2XX response from the
    ///             Afero REST API, the provided `onDone` must be called
    ///             to complete association.
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
    /// Upon a successful (2XX) response from the client, the callback must call
    /// the provided `onDone()` handler to signal the softhub to complete its association.
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
        apiHost: String,
        using profileType: SofthubProfileType = .prod,
        behavingAs softhubType: SofthubType = .enterprise,
        identifiedBy identifier: String? = nil,
        logLevel: AferoSofthubLogLevel,
        associationHandler: @escaping SofthubAssociationHandler,
        setupModeDeviceDetectedHandler: @escaping SofthubSetupModeDeviceDetectedHandler = { _, _, _ in },
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
            apiHost: apiHost,
            profileType: profileType.aferoProfileType,
            logLevelName: logLevel,
            hardwareIdentifier: identifier,
            associationHandler: localAssociationHandler,
            setupModeDeviceDetectedHandler: setupModeDeviceDetectedHandler,
            completionHandler: localCompletionHandler
        )
        
    }
    
    /// Tell the softhub that association has been completed.
    ///
    /// This is required after a successful call to the Afero Client API to associate
    /// on behalf of the softhub (notably in cases where the softhub performs a live
    /// reassociate if its cloud representation is deleted.
    
    public func notifyAssociationCompleted(with status: SofthubAssociationStatus) {
        AferoSofthub.notifyAssociationCompleted(with: status);
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
