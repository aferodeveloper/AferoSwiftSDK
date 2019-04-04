//
//  WifiSetupManager.swift
//  iTokui
//
//  Created by Justin Middleton on 8/4/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result
import CocoaLumberjack
import AferoSofthub

extension AferoSofthubSetupWifiCommandState: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return description + " (\(rawValue))"
    }
    
    public var description: String {
        switch self {
        case .start: return "AferoSofthubSetupWifiCommandState.Start"
        case .available: return "AferoSofthubSetupWifiCommandState.Available"
        case .connected: return "AferoSofthubSetupWifiCommandState.Connected"
        case .done: return "AferoSofthubSetupWifiCommandState.Done"
        case .cancelled: return "AferoSofthubSetupWifiCommandState.Cancelled"
        case .timedOut: return "AferoSofthubSetupWifiCommandState.TimedOut"
        case .timedOutCommunicating: return "AferoSofthubSetupWifiCommandState.TimedOutCommunicating"
        case .timedOutConnect: return "AferoSofthubSetupWifiCommandState.TimedOutConnect"
        case .timedOutNotAvailable: return "AferoSofthubSetupWifiCommandState.TimedOutNotAvailable"
        case .failed: return "AferoSofthubSetupWifiCommandState.Failed"
            
        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoSofthubSetupWifiCommandState case \(rawValue)"
        #endif
        }
            
    }
    
    var isTerminal: Bool {
        return self ∈ [ .failed, .timedOut, .timedOutCommunicating, .timedOutConnect, .timedOutNotAvailable, .done, .cancelled ]
    }
    
    var isError: Bool {
        return self ∈ [ .failed, .timedOut, .timedOutCommunicating, .timedOutConnect, .timedOutNotAvailable, ]
    }
    
}

extension AferoSofthubWifiState: CustomStringConvertible, CustomDebugStringConvertible {

    public var debugDescription: String {
        return description + " (\(rawValue))"
    }
    
    public var description: String {
        
        switch self {
        case .notConnected: return "AferoSofthubWifiState.NotConnected"
        case .pending: return "AferoSofthubWifiState.Pending"
        case .associationFailed: return "AferoSofthubWifiState.AssociationFailed"
        case .handshakeFailed: return "AferoSofthubWifiState.HandshakeFailed"
        case .echoFailed: return "AferoSofthubWifiState.EchoFailed"
        case .connected: return "AferoSofthubWifiState.Connected"
        case .ssidNotFound: return "AferoSofthubWifiState.SSIDNotFound"
        case .unknownFailure: return "AferoSofthubWifiState.UnknownFailure"
            
        #if compiler(>=5)
        @unknown default:
            return "Unknown AferoSofthubWifiState case \(rawValue)"
        #endif

        }
    }
    
}

/// Errors related to wifi setup.
///
/// ## Errors originating from the Softhub
///
/// Each of the errors below map to errors forwarded to the
/// setup manager from the `AferoSofthub`, and their `rawValues` are the relevant
/// integer values of those enumeration cases.
///
/// For a full list of the values whence these come, see `AferoSofthubSetupWifiCommandState`
/// in `AferoSofthub.h`, in the `AferoSofthub` module.
///
/// * `.hubbyCommandTimedOutNotAvailable (0x05)`: The setup process has timed out because
///    the remote hasn't shown up within BLE range of this hub
///    (`AferoSofthubSetupWifiCommandStateTimedOutNotAvailable`).
///
/// * `.hubbyCommandTimedOutConnect (0x06)`: The setup process has timed out because we
///   couldn't connect to the remote (`AferoSofthubSetupWifiCommandStateTimedOutConnect`).
///
/// * `.hubbyCommandTimedOutCommunicating (0x07)`: The setup process has timed out because
///   we couldn't finish our communication with the remote
///   (`AferoSofthubSetupWifiCommandStateTimedOutCommunicating`).
///
/// * `.hubbyCommandTimedOut (0x08)`: The setup process has timed out for some other reason
///   (`AferoSofthubSetupWifiCommandStateTimedOut`).
///
/// * `.hubbyCommandFailed (0x09)`: The setup process has failed for an unknown reason
///   (`AferoSofthubSetupWifiCommandStateFailed`)
///
/// ## WifiSetupManager internal errors
///
/// * `invalidManagerState (0xF0 / 240)`: The manager was not in a valid state to
///   perform an operation. This likely indicates a programming error
///   in the caller.

public enum WifiSetupError: Int, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {
    
    static var Domain: String { return "WifiSetupError" }
    
    /// The setup process has timed out because
    /// the remote hasn't shown up within BLE range of this hub
    /// (`AferoSofthubSetupWifiCommandStateTimedOutNotAvailable`).
    case hubbyCommandTimedOutNotAvailable = 0x5
    
    /// The setup process has timed out because we
    ///  couldn't connect to the remote (`AferoSofthubSetupWifiCommandStateTimedOutConnect`).
    case hubbyCommandTimedOutConnect = 0x6
    
    /// The setup process has timed out because
    /// we couldn't finish our communication with the remote
    /// (`AferoSofthubSetupWifiCommandStateTimedOutCommunicating`).
    case hubbyCommandTimedOutCommunicating = 0x7
    
    /// The setup process has timed out for some other reason
    /// (`AferoSofthubSetupWifiCommandStateTimedOut`).
    case hubbyCommandTimedOut = 0x8
    
    /// The setup process has failed for an unknown reason
    /// (`AferoSofthubSetupWifiCommandStateFailed`)
    case hubbyCommandFailed = 0x9
    
    /// The manager was not in a valid state to
    /// perform an operation. This likely indicates a programming error
    /// in the caller.
    case invalidManagerState = 0xF0
    
    public var description: String {
        switch self {
        case .hubbyCommandFailed: return "WifiSetupError.hubbyCommandFailed"
        case .hubbyCommandTimedOut: return "WifiSetupError.hubbyCommandTimedOut"
        case .hubbyCommandTimedOutConnect: return "WifiSetupError.hubbyCommandTimedOutConnect"
        case .hubbyCommandTimedOutNotAvailable: return "WifiSetupError.hubbyCommandTimedOutNotAvailable"
        case .hubbyCommandTimedOutCommunicating: return "WifiSetupError.hubbyCommandTimedOutCommunicating"
        case .invalidManagerState: return "WifiSteupError.invalidManagerState"
        }
    }
    
    public var localizedDescription: String {
        switch self {
            
        case .hubbyCommandFailed:
            return String(format: NSLocalizedString("Command unsuccessful (%d).", comment: "WifiSetupError.hubbyCommandFailed description"), rawValue)
            
        case .hubbyCommandTimedOut:
            return String(format: NSLocalizedString("Command timed out (%d).", comment: "WifiSetupError.hubbyCommandTimedOut description"), rawValue)
            
        case .hubbyCommandTimedOutNotAvailable:
            return String(format: NSLocalizedString("Timed out waiting for device to become available (%d).", comment: "WifiSetupError.hubbyCommandTimedOut description"), rawValue)
            
        case .hubbyCommandTimedOutCommunicating:
            return String(format: NSLocalizedString("Timed out communicating with device (%d).", comment: "WifiSetupError.hubbyCommandTimedOut description"), rawValue)
            
        case .hubbyCommandTimedOutConnect:
            return String(format: NSLocalizedString("Timed out attempting to connect to device (%d).", comment: "WifiSetupError.hubbyCommandTimedOut description"), rawValue)
            
        case .invalidManagerState:
            return String(format: NSLocalizedString("Manager in invalid state for command (%d)", comment: "WifiSetupError.hubbyCommandTimedOut description"), rawValue)
            
        }
    }
    
    public var debugDescription: String {
        return "\(description)(\(rawValue))"
    }
    
    public init?(hubbyCommandState: WifiSetupManaging.CommandState) {
        switch hubbyCommandState {
        case .timedOut: self = .hubbyCommandTimedOut
        case .failed: self = .hubbyCommandFailed
        case .timedOutCommunicating: self = .hubbyCommandTimedOutCommunicating
        case .timedOutNotAvailable: self = .hubbyCommandTimedOutNotAvailable
        case .timedOutConnect: self = .hubbyCommandTimedOutConnect
        default:
            return nil
        }
    }
    
    init?(nsError: NSError) {

        guard nsError.domain == type(of: self).Domain else {
            return nil
        }
        
        self.init(rawValue: nsError.code)
    }
    
    public var nsError: NSError {
        return NSError(wifiSetupError: self)
    }
    
    // MARK: LocalizedError
    
    public var errorDescription: String? {
        return localizedDescription
    }
    
}
extension NSError {
    
    convenience init(wifiSetupError: WifiSetupError, userInfo: [AnyHashable: Any]? = nil) {
        self.init(domain: WifiSetupError.Domain, code: wifiSetupError.rawValue, userInfo: [
            NSLocalizedDescriptionKey: wifiSetupError.localizedDescription
            ])
    }
    
    var wifiSetupError: WifiSetupError? {
        return WifiSetupError(nsError: self)
    }
    
}

/// Describes the types of media supported by a peripheral.

public struct ConnectionMediaTypes: OptionSet, CustomStringConvertible {
    
    // MARK: Actual values
    
    /// Emtpy Set
    
    public static var None: ConnectionMediaTypes { return allZeros }
    public static var All: ConnectionMediaTypes { return [.BLE, .WiFi, .LTE] }
    
    /// The device supports Bluetooth Low Energy
    public static var BLE: ConnectionMediaTypes { return self.init(bitIndex: 0) }
    
    /// The device supports Wifi
    public static var WiFi: ConnectionMediaTypes { return self.init(bitIndex: 1) }
    
    /// The device supports LTE
    public static var LTE: ConnectionMediaTypes { return self.init(bitIndex: 2) }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        var atoms: [String] = []
        
        if contains(.BLE) { atoms.append("BLE") }
        if contains(.WiFi) { atoms.append("WiFi") }
        if contains(.LTE) { atoms.append("LTE") }
        
        return "[\(atoms.joined(separator: ","))]"
    }
    
    public var debugDescription: String {
        return "<ConnectionMediaTypes> \(description)"
    }

    // Yes, this is what a bitfield looks like in Swift :(
    
    public typealias RawValue = UInt
    
    fileprivate var value: RawValue = 0
    
    // MARK: NilLiteralConvertible
    
    public init(nilLiteral: Void) {
        self.value = 0
    }
    
    // MARK: RawLiteralConvertible
    
    public init(rawValue: RawValue) {
        self.value = rawValue
    }
    
    static func fromRaw(_ raw: UInt) -> ConnectionMediaTypes {
        return self.init(rawValue: raw)
    }
    
    public init(bitIndex: UInt) {
        self.init(rawValue: 0x01 << bitIndex)
    }
    
    public var rawValue: RawValue { return self.value }
    
    // MARK: BooleanType
    
    public var boolValue: Bool {
        return value != 0
    }
    
    // MARK: BitwiseOperationsType
    
    public static var allZeros: ConnectionMediaTypes {
        return self.init(rawValue: 0)
    }
    
    public static func fromMask(_ raw: UInt) -> ConnectionMediaTypes {
        return self.init(rawValue: raw)
    }
    
}

public protocol ConnectionMediaSupporting: DeviceModelable {

    /// The media types this deviceModel supports.
    var connectionMediaTypes: ConnectionMediaTypes { get }

}

extension ConnectionMediaSupporting {
    
    /// The connection media types (BLE, WiFi, LTE, etc) that
    /// this device supports.
    
    public var connectionMediaTypes: ConnectionMediaTypes {
        
        var ret: ConnectionMediaTypes = .None
        
        if true {
            // Placeholder. Right now, everything supports BLE. In the future? maybe not.
            ret.formUnion(.BLE)
        }
        
        if descriptorForAttributeId(AferoSofthubWifiAttributeId.setupState.rawValue) != nil {
            ret.formUnion(.WiFi)
        }
        
        // Ideally we'd get this from attribute presence, as with .WiFi,
        // but unfortunately we don't have that yet.
        
        if case .some(.bento) = profile?.enumeratedDeviceType {
            ret.formUnion(.LTE)
        }
        
        return ret
        
    }
}

// MARK: -
// MARK: <WifiConfigurable>
// MARK: -

public protocol WifiConfigurable: ConnectionMediaSupporting {
    
    var TAG: String { get }
    
    var hachiState: HachiState { get }
    
    /// Whether this `WifiConfigurable` is _really_ _wifiConfigurable_.
    var isWifiConfigurable: Bool { get }
    
    /// Whether the device can be configured in its current state.
    var currentStateAllowsWifiConfiguration: Bool { get }
    
    /// The wifi setup manager to use for this device. If `isWifiConfigurable == false`, then
    func getWifiSetupManager() -> WifiSetupManaging?
    
    /// The callback that `AferoSofthub` will use to write attributes for this device.
    func writeAttributeCallback() -> (_ deviceId: String, _ attributeId: Int, _ type: String, _ hexData: String) -> Bool
    
    /// If `isWifiConfigurable`, `SSID` to which the receiver is currently connected, if any.
    var wifiCurrentSSID: String? { get }
    
    /// If `isWifiConfigurable`, the current network type used by the receiver.
    var wifiCurrentNetworkType: WifiSetupManaging.NetworkType? { get }
    
    /// If `isWifiConfigurable`, the `AferoSofthubWifiState` for the setup process.
    var wifiSetupState: WifiSetupManaging.WifiState? { get }
    
    /// If `isWifiConfigurable`, the `AferoSofthubWifiState` for normal operation.
    var wifiSteadyState: WifiSetupManaging.WifiState? { get }
    
    /// If `isWifiConfigurable`, the current `RSSI` in db.
    var wifiRSSI: Int? { get }
    
    /// If `isWifiConfigurable`, the current number of RSSI bars that should be shown
    /// in any user interface.
    var wifiRSSIBars: Int? { get }
    
}

extension WifiConfigurable {
    
    public var isWifiConfigurable: Bool {
        return connectionMediaTypes.contains(.WiFi)
    }
    
    public var currentStateAllowsWifiConfiguration: Bool {
        // Uncomment this once we can rely upon this.
        //        return hachiState == .linked
        return isAvailable
    }
    
    public func getWifiSetupManager() -> WifiSetupManaging? {
//        if !isWifiConfigurable { return nil }
        return LiveWifiSetupManager(deviceModel: self, writeAttributeCallback: writeAttributeCallback())
    }
    
    public func writeAttributeCallback() -> ((_ deviceId: String, _ attributeId: Int, _ type: String, _ hexData: String) -> Bool) {

        let TAG = self.TAG
        let accountId = self.accountId

        return {
            [weak self] deviceId, attributeId, type, hexData in
            DDLogDebug("writeAttribute hubId: \(deviceId) attributeId: \(attributeId) type: \(type) hexData \(hexData)", tag: TAG)

            let data: [UInt8] = Data(hexEncoded: hexData)?.bytes ?? []

            DDLogDebug("writeAttribute will write \(data)", tag: TAG)
            
            let attributeValue = AttributeValue.rawBytes(data)

            self?.write(attributeId, attributeValue: attributeValue) {
                maybeInstance, maybeError in
                
                if let error = maybeError {
                    DDLogError("Error trying to write attribute \(attributeId) deviceId: \(deviceId) accountId: \(accountId) error: \(error)", tag: TAG)
                }
                
                if let instance =  maybeInstance {
                    DDLogDebug("Wrote \(instance.debugDescription) deviceId: \(deviceId) accountId: \(accountId)")
                }
            }

            return true
        }
        
    }
    
    public var wifiCurrentSSID: String? {
        return valueForAttributeId(AferoSofthubWifiAttributeId.currentSSID.rawValue)?.stringValue
    }
    
    public func rawValueForAferoSofthubWifiAttribute(_ attribute: AferoSofthubWifiAttributeId) -> AttributeValue? {
        return valueForAttributeId(attribute.rawValue)
    }
    
    public var wifiCurrentNetworkType: AferoSofthubWifiNetworkType? {
        guard let v = rawValueForAferoSofthubWifiAttribute(.networkType)?.intValue else {
            return nil
        }
        return AferoSofthubWifiNetworkType(rawValue: v)
    }
    
    public var wifiSetupState: AferoSofthubWifiState? {
        guard let v = rawValueForAferoSofthubWifiAttribute(.setupState)?.intValue else {
            return nil
        }

        return AferoSofthubWifiState(rawValue: v)
    }
    
    public var wifiSteadyState: AferoSofthubWifiState? {
        guard let v = rawValueForAferoSofthubWifiAttribute(.steadyState)?.intValue else {
            return nil
        }
        
        return AferoSofthubWifiState(rawValue: v)
    }
    
    public var wifiRSSI: Int? {
        return rawValueForAferoSofthubWifiAttribute(.RSSI)?.intValue
    }
    
    public var wifiRSSIBars: Int? {
        
        guard let wifiRSSI = wifiRSSI else { return nil }
        
        do {
            return try AferoSofthub.bars(forRSSI: wifiRSSI).intValue
        } catch {
            DDLogError("Unable to calculate RSSI bars for given RSSI \(wifiRSSI)", tag: TAG)
            return nil
        }
        
    }
    
    /// The state of the wifi network when setup is not in progress.
    public var steadyStateWifiNetwork: WifiNetwork? {
        
        guard
            let state = wifiSteadyState,
            let ssid = wifiCurrentSSID,
            let rssi = wifiRSSI,
            let rssiBars = wifiRSSIBars else {
                return nil
        }
        
        return WifiNetwork(ssid: ssid, rssi: rssi, rssiBars: rssiBars, state: state)
    }
    
    /// The state of the wifi network when setup is in progress.
    public var setupWifiNetwork: WifiNetwork? {
        
        guard
            let state = wifiSetupState,
            let ssid = wifiCurrentSSID,
            let rssi = wifiRSSI,
            let rssiBars = wifiRSSIBars else {
                return nil
        }
        
        return WifiNetwork(ssid: ssid, rssi: rssi, rssiBars: rssiBars, state: state)
    }

}

extension DeviceModel: WifiConfigurable { }

/// The manager's current state.
/// - `notReady`: Initial state. The manager isn't ready to manage anything (e.g. the target device isn't available)
/// - `ready`: The manager is ready!
/// - `managing`: Wifi setup in progress.
/// - `completed`: Terminal state. Wifi setup has completed. If there's an error, it will be associated.
///
/// State transitions:
///
/// - `notReady` ↔ `ready`
/// - `ready` → `managing`
/// - `managing` → `completed(nil)`
/// - `managing` → `completed(error)`

public enum WifiSetupManagerState: Equatable, CustomDebugStringConvertible {

    /// The manager isn't ready to manage anything (e.g. the target device isn't available)
    case notReady
    
    /// The manager is ready!
    case ready
    
    /// The manager is currently managing a device.
    case managing
    
    case completed(error: Error?)
    
    // MARK: <Equatable>
    
    /// Test equality for `WifiSetupManagerState`s.
    /// - note: `.completed` checks ignore associated `error` values.
    
    public static func ==(lhs: WifiSetupManagerState, rhs: WifiSetupManagerState) -> Bool {
        switch (lhs, rhs) {
        case (.notReady, .notReady): fallthrough
        case (.ready, .ready): fallthrough
        case (.managing, .managing): fallthrough
        case (.completed, .completed):
            return true
        default:
            return false
        }
    }
    
    // MARK: <CustomDebugStringConvertible
    
    public var debugDescription: String {
        switch self {
        case .notReady: return "WifiSetupManagerState.notReady"
        case .ready: return "WifiSetupmanagerState.ready"
        case .managing: return "WifiSetupManagerState.managing"
        case .completed(let error):
            if let error = error {
                return "WifiSetupManagerState.completed with error: \(error.localizedDescription)"
            }
            return "WifiSEtupManagerState.completed"
        }
    }


}


// MARK: -
// MARK: WifiSetupEvent
// MARK: -

/// Events emitted by the WifiSetupManager during the setup process.
/// The state of a previously-submitted wifi management command has changed.
/// A new SSID list has arrived
/// - `managerStateChange`: The manager
/// - `commandStateChange`: The managed device's live network type has changed.
/// - `ssidListChanged`: The managed device's association status has changed.
/// - `networkTypeChanged`: The managed device's IP status has changed.
/// - `wifiAssociationStatusChanged`: The managed device's scan state has changed.
/// - `wifiIPStatusChanged`: The managed device's IP status has changed.
/// - `wifiScanStateChanged`: The managed device's scan state has changed.
/// - `wifiCurrentSSIDChanged`: The managed device's currently-associated SSID has changed.

public enum WifiSetupEvent {
    
    /// The wifi setup manager's state changed.
    case managerStateChange(newState: WifiSetupManagerState)
    
    /// The state of a previously-submitted wifi management command has changed.
    case commandStateChange(newState: WifiSetupManaging.CommandState)
    
    /// A new SSID list has arrived
    case ssidListChanged(newList: WifiSetupManaging.WifiNetworkList)
    
    /// The managed device's live network type has changed.
    case networkTypeChanged(newType: AferoSofthubWifiNetworkType)
    
    /// A password has been sent to the hub.
    case wifiPasswordCommitted
    
    /// The managed device's currently-associated SSID has changed.
    case wifiCurrentSSIDChanged(newSSID: String)
    
    /// The managed device's state setup process wifi state changed.
    case wifiSetupStateChanged(newState: WifiSetupManaging.WifiState)
    
    /// The managed device's steady (configured) wifi state changed.
    case wifiSteadyStateChanged(newState: WifiSetupManaging.WifiState)
    
    /// The managed device's signal strength changed (in decibels)
    case wifiRSSIChanged(newRSSI: Int)
    
    /// The managed device's signal strength changed (in bars)
    case wifiRSSIBarsChanged(newRSSIBars: Int)
}

extension WifiSetupEvent: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
            
        case .managerStateChange(let newState):
            return "WifiSetupEvent.managerStateChange(\(newState.debugDescription))"
            
        case .commandStateChange(let newState):
            return "WifiSetupEvent.commandStateChange(\(newState.debugDescription))"
            
        case .ssidListChanged(let newList):
            return "WifiSetupEvent.ssidListChanged(\(newList.debugDescription))"
            
        case .networkTypeChanged(let newType):
            return "WifiSetupEvent.networkTypeChanged(\(newType))"
            
        case .wifiPasswordCommitted:
            return "WifiSetupEvent.wifiPasswordCommitted"
            
        case .wifiCurrentSSIDChanged(let newSSID):
            return "WifiSetupEvent.wifiCurrentSSIDChanged(\(newSSID))"
            
        case .wifiSetupStateChanged(let newState):
            return "WifiSetupEvent.wifiSetupStateChanged(newState: \(newState))"

        case .wifiSteadyStateChanged(let newState):
            return "WifiSetupEvent.wifiSteadyStateChanged(newState: \(newState))"

        case .wifiRSSIChanged(let newRSSI):
            return "WifiSetupEvent.wifiRSSIChanged(newRSSI: \(newRSSI))"

        case .wifiRSSIBarsChanged(let newRSSIBars):
            return "WifiSetupEvent.wifiRSSIChanged(newRSSI: \(newRSSIBars))"

        }
    }
}

// MARK: -
// MARK: <WifiSetupManaging>
// MARK: -

/// For clients of a `<WifiSetupManaging>` instance, the signal type
/// for setup event emissions.

public typealias WifiSetupEventSignal = Signal<WifiSetupEvent, NoError>

public protocol WifiNetworkProto: Hashable {

    var ssid: String { get }
    var rssi: Int { get }
    var rssiBars: Int { get }
    var isSecure: Bool? { get }
    var isConnected: Bool { get }
    
    typealias State = AferoSofthubWifiState
    var state: State { get }

}

/// Protocol for anything which manages a wifi-configurable device.

public struct WifiNetwork: WifiNetworkProto {
    
    public var ssid: String
    public var rssi: Int = -99
    public var rssiBars: Int = 0
    public var isSecure: Bool? = false
    
    public var isConnected: Bool {
        return state == .connected
    }
    
    public var state: WifiNetworkProto.State = .notConnected
    
    public init(ssid: String, rssi: Int = -99, rssiBars: Int = 0, isSecure: Bool? = nil, state: WifiNetworkProto.State = .notConnected) {
        self.ssid = ssid
        self.rssi = rssi
        self.rssiBars = rssiBars
        self.isSecure = isSecure
        self.state = state
    }
    
    init(from wifiNetworkWrapper: AferoSofthubWifiSSIDEntryWrapper) {
        self.init(
            ssid: wifiNetworkWrapper.ssid,
            rssi: wifiNetworkWrapper.rssi,
            rssiBars: wifiNetworkWrapper.rssiBars,
            isSecure: wifiNetworkWrapper.isSecure,
            state: wifiNetworkWrapper.isConnected ? .connected : .notConnected
        )
    }
    
    public func hash(into h: inout Hasher) {
        h.combine(ssid)
        h.combine(rssi)
    }
    
    public static func ==(lhs: WifiNetwork, rhs: WifiNetwork) -> Bool {
        return lhs.ssid == rhs.ssid
            && lhs.rssi == rhs.rssi
            && lhs.rssiBars == rhs.rssiBars
            && lhs.isSecure == rhs.isSecure
            && lhs.isConnected == rhs.isConnected
    }
    
}

public protocol WifiSetupManaging: class {
    

    typealias WifiNetwork = Afero.WifiNetwork
    typealias WifiNetworkList = [WifiNetwork]
    typealias WifiState = AferoSofthubWifiState
    typealias CommandState = AferoSofthubSetupWifiCommandState
    typealias NetworkType = AferoSofthubWifiNetworkType
    
    var wifiSetupEventSignal: WifiSetupEventSignal { get }
    
    var state: WifiSetupManagerState { get }
    
    func start()
    func stop()
    func scan() throws
    func scan(timeout: TimeInterval) throws
    func cancelScan() throws
    func attemptAssociate(_ SSID: String, password: String) throws
    func attemptAssociate(_ SSID: String, password: String, timeout: TimeInterval) throws
    func cancelAttemptAssociate() throws

}

// MARK: -
// MARK: LiveWifiSetupManager

/// A `<WifiSetupManaging>` which actually interacts with a hub.

private class LiveWifiSetupManager: WifiSetupManaging, CustomDebugStringConvertible {
    
    var debugDescription: String {
        return TAG
    }
    
    var TAG: String {
        return "WifiSetupManager/\(Unmanaged.passUnretained(self).toOpaque())(\(deviceModel.deviceId)"
    }
    
    fileprivate(set) var deviceModel: DeviceModelable
    fileprivate var writeAttributeCallback: AferoSofthubWriteAttributeCallback
    
    var deviceId: String { return deviceModel.deviceId }
    
    init(deviceModel: DeviceModelable, writeAttributeCallback: @escaping AferoSofthubWriteAttributeCallback) {
        self.deviceModel = deviceModel
        self.writeAttributeCallback = writeAttributeCallback
    }
    
    deinit {
        unsubscribeFromWifiAttributes()
        stop()
    }
    
    // MARK: - State Management
    
    private(set) var state: WifiSetupManagerState = .notReady {
        didSet {
            if oldValue == state { return }
            wifiSetupEventSink.send(value: .managerStateChange(newState: state))
        }
    }

    /// Called by the `deviceAvailabiltyDisposable` handler, *whenever device state changes*. This
    /// may or may not be due to availability change; as of now we don't have a separate event for
    /// that. We only care about this when we haven't started managing; once we have started managing,
    /// we've implicitly handed off to AferoSofthub.
    
    private func deviceStateChanged(deviceState: DeviceState) {
        switch self.state {
        case .notReady: fallthrough
        case .ready:
            DDLogInfo("Manager in a pending state, device isAvailable: \(deviceState.isAvailable)")
            self.state = deviceState.isAvailable ? .ready : .notReady
        default:
            DDLogInfo("Manager no longer in pending state; ignoring device availability")
            
        }
    }

    // MARK: -
    // MARK: Signaling
    
    fileprivate typealias WifiSetupEventSink = Signal<WifiSetupEvent, NoError>.Observer
    fileprivate typealias WifiSetupEventPipe = (output: WifiSetupEventSignal, input: WifiSetupEventSink)
    
    lazy fileprivate var wifiSetupEventPipe: WifiSetupEventPipe = {
        return WifiSetupEventSignal.pipe()
    }() 
    
    /**
     A combined signal for all wifi-setup related attribute events.
     */
    
    var wifiSetupEventSignal: WifiSetupEventSignal {
        return wifiSetupEventPipe.0
    }
    
    /**
     The `Sink` to which WifiSetup events are broadcast after being chaned.
     */
    
    fileprivate final var wifiSetupEventSink: WifiSetupEventSink {
        return wifiSetupEventPipe.1
    }
    
    fileprivate final var wifiAttributesDisposable: Disposable? {
        willSet {  wifiAttributesDisposable?.dispose() }
    }
    
    fileprivate var deviceAvailabilityDisposable: Disposable? {
        willSet { deviceAvailabilityDisposable?.dispose() }
    }
    
    fileprivate final func unsubscribeFromWifiAttributes() {
        wifiAttributesDisposable = nil
        deviceAvailabilityDisposable = nil
    }
    
    fileprivate final func emit(_ event: WifiSetupEvent) {
        DDLogDebug("Emitting WIFI_SETUP_EVENT \(event)", tag: TAG)
        wifiSetupEventSink.send(value: event)
    }
    
    /// Subscribes to all of the pertinent attributes related to hub wifi configuration,
    /// translates those changes into `WifiSetupEvent` instances, and forwards them to
    /// `wifiSetupEventSignal` subscribers.
    
    fileprivate final func subscribeToWifiAttributes() {
        
        let TAG = self.TAG
        
        DDLogDebug("Subscribing to wifi attributes (\(AferoSofthub.allWifiSetupAttributes()) for deviceModel \(deviceModel)", tag: TAG)
        
        // All of these map to emit() calls, which go straight to the event pipe...
        // it's cool to keep them on a non-main queue.
        
        wifiAttributesDisposable = deviceModel
            .eventSignalForAttributeIds(AferoSofthub.allWifiSetupAttributes())?
            .observeValues {
                [weak self] event in
                
                switch event {
                    
                case let .update(_, _, attribute):
                    
                    let attributeId = attribute.config.descriptor.id
                    
                    guard let wifiAttributeId = AferoSofthubWifiAttributeId(rawValue: attributeId) else {
                        DDLogDebug("Unrecognized attributeId \(attributeId) for wifi setup; ignoring.")
                        return
                    }
                    
                    switch wifiAttributeId {
                        
                    case .networkType:
                        
                        guard
                            let typeValue = attribute.value.intValue,
                            let networkType = AferoSofthubWifiNetworkType(rawValue: typeValue) else {
                                DDLogError("\(attribute.value) cannot coerce to int for network type.", tag: TAG)
                                return
                        }
                        
                        self?.emit(.networkTypeChanged(newType: networkType))
                        
                    case .currentSSID:
                        
                        guard let newSSID = attribute.value.stringValue else {
                            DDLogError("\(attribute.value) cannot coerce to string for SSID", tag: TAG)
                            return
                        }
                        
                        self?.emit(.wifiCurrentSSIDChanged(newSSID: newSSID))
                        
                    case .setupState:
                        
                        guard
                            let intState = attribute.value.intValue,
                            let newState = AferoSofthubWifiState(rawValue: intState) else {
                                DDLogError("Invalid integer value for setup state (\(attribute.value))", tag: TAG)
                                return
                        }
                        
                        self?.emit(.wifiSetupStateChanged(newState: newState))
                        
                    case .steadyState:
                        
                        guard
                            let intState = attribute.value.intValue,
                            let newState = AferoSofthubWifiState(rawValue: intState) else {
                                DDLogError("Invalid integer value for steady state (\(attribute.value))", tag: TAG)
                                return
                        }
                        
                        self?.emit(.wifiSteadyStateChanged(newState: newState))
                        
                    case .RSSI:
                        
                        guard let newRSSI = attribute.value.intValue else {
                            DDLogError("Invalid integer value for RSSI (\(attribute.value))", tag: TAG)
                            return
                        }
                        
                        self?.emit(.wifiRSSIChanged(newRSSI: newRSSI))
                        
                    #if compiler(>=5)
                    @unknown default:
                        let msg = "Unknown wifi attribute ID \(wifiAttributeId) for event \(event)."
                        assert(false, msg)
                        DDLogError(msg, tag: TAG)
                        return
                    #endif
                    }
                    
                }
        }
        
        // This, on the other hand, actually modifies the manager's state. We'll keep it
        // on the main queue.
        
        deviceAvailabilityDisposable = deviceModel.eventSignal
            .observe(on: QueueScheduler.main)
            .observeValues {
                [weak self] event in
                switch event {
                case .stateUpdate(let deviceState):
                    self?.deviceStateChanged(deviceState: deviceState)
                default: break
                }
        }
        
        deviceStateChanged(deviceState: deviceModel.currentState)
        
    }
    
    // MARK: -
    // MARK: Public
    
    func start() {
        subscribeToWifiAttributes()
        deviceModel.notifyViewing(true)
    }
    
    func stop() {
        deviceModel.notifyViewing(false)

        do {
            try cancelAttemptAssociate()
            try cancelScan()
        } catch {
            DDLogError("Error attempting to stop; ignoring: \(String(describing: error))", tag: TAG)
        }
        
        unsubscribeFromWifiAttributes()
        state = .completed(error: nil)
    }

    func scan() throws {
        try scan(timeout: 60.0)
    }
    
    /// Start a scan for SSIDs (In the sim, this just causes us to reload some sample SSIDs.)
    
    func scan(timeout: TimeInterval = 60.0) throws {
        
        let TAG = self.TAG
        
        if state ∉ [.ready, .managing] {
            let msg = "Invalid manager state for scan: \(state)"
            DDLogError(msg, tag: TAG)
            throw msg
        }
        
        state = .managing
        
        DDLogDebug("Telling AferoSofthub to tell \(deviceId) to scan.", tag: TAG)

        let fireBlock: (Timer?)->Void = {
            [weak self] ltimer in
            ltimer?.invalidate()
            try! self?.cancelScan()
            self?.emit(.commandStateChange(newState: .timedOut))
        }
        
        var timer = Timer.schedule(timeout, handler: fireBlock)

        let onCommandStateChange: (String, AferoSofthubSetupWifiCommandState) -> Void = {
            
            [weak self] hubId, state in
            DDLogInfo("\(state.debugDescription) for \(hubId)", tag: TAG)
            self?.emit(.commandStateChange(newState: state))
            
            asyncMain {
                timer?.invalidate()
                if !state.isTerminal {
                    timer = Timer.schedule(timeout, handler: fireBlock)
                }
            }
        }
        
        do {
            try AferoSofthub.getWifiSSIDListFromDevice(
                withId: deviceId,
                commandStateChangeCallback: onCommandStateChange,
                writeAttributeCallback: writeAttributeCallback
            ) {
                [weak self] deviceId, SSIDWrapperList in
                
                timer?.invalidate()
                
                let SSIDList = SSIDWrapperList.map( { WifiNetwork(from: $0) } )
                
                guard let expectedDeviceId = self?.deviceId else {
                    DDLogDebug("Looks like we've been deallocated; bailing.")
                    return
                }
                
                guard deviceId == expectedDeviceId else {
                    DDLogDebug("Got SSID list result for deviceId \(deviceId) but was expecting \(expectedDeviceId)", tag: TAG)
                    return
                }
                
                self?.emit(.ssidListChanged(newList: SSIDList))
            }
        } catch {
            DDLogError("Error attempting scan: \(String(describing: error))", tag: TAG)
            throw error
        }
        
    }
    
    /// Cancel a previous scan request.
    
    func cancelScan() throws {

        if state ∉ [.ready, .managing] {
            let msg = "Invalid manager state for cancelScan: \(state)"
            DDLogError(msg, tag: TAG)
            throw msg
        }
        
        DDLogDebug("Canceling scan for hub \(deviceId)", tag: TAG)
        
        do {
            try AferoSofthub.cancelGetWifiSSIDListFromDevice(withId: deviceId)
        } catch {
            DDLogError("Error attempting to cancel scan: \(String(describing: error))", tag: TAG)
            throw error
        }
    }
    
    func attemptAssociate(_ SSID: String, password: String) throws {
        try attemptAssociate(SSID, password: password, timeout: 60.0)
    }
    
    /// Forward an SSID/password pair to AferoSofthub to attempt association.

    func attemptAssociate(_ SSID: String, password: String, timeout: TimeInterval) throws {
        
        let TAG = self.TAG
        
        if state ∉ [.ready, .managing] {
            let msg = "Invalid manager state for attemptAssociate: \(state)"
            DDLogError(msg, tag: TAG)
            throw msg
        }
        
        state = .managing
        
        DDLogDebug("Attempting associate for SSID \(SSID), password: \(password)", tag: TAG)
        
        emit(.wifiPasswordCommitted)

        let fireBlock: (Timer?)->Void = {
            [weak self] ltimer in
            ltimer?.invalidate()
            try! self?.cancelAttemptAssociate()
            self?.emit(.commandStateChange(newState: .timedOut))
        }

        var timer = Timer.schedule(timeout, handler: fireBlock)
        
        let onCommandStateChange: (String, AferoSofthubSetupWifiCommandState) -> Void = {
            [weak self] hubId, state in
            DDLogInfo("\(state.debugDescription) for \(hubId)", tag: TAG)
            self?.emit(.commandStateChange(newState: state))
            
            asyncMain {
                timer?.invalidate()
                if !state.isTerminal {
                    timer = Timer.schedule(timeout, handler: fireBlock)
                }
            }
            
        }
        
        do {
            try AferoSofthub.sendWifiCredentialToHub(
                withId: deviceId,
                ssid: SSID,
                password: password,
                commandStateChangeCallback: onCommandStateChange,
                writeAttributeCallback: writeAttributeCallback
            )
        } catch {
            DDLogError("Error attempting to cancel scan: \(String(describing: error))", tag: TAG)
            throw error
        }
        
        // Simulate success

//        after(1.0) {
//            [weak self] in self?.wifiSetupEventSink.sendNext(.WifiAssociateFailed)
//        }
//        
//        after(2.0) {
//            [weak self] in self?.wifiSetupEventSink.sendNext(.WifiHandshakeFailed)
//        }
//
//        after(3.0) {
//            [weak self] in self?.wifiSetupEventSink.sendNext(.WifiEchoFailed)
//        }
//        
//        after(4.0) {
//            [weak self] in self?.wifiSetupEventSink.sendNext(.WifiConnected)
//        }
        

    }
    
    /// Cancel a previous association request.
    
    func cancelAttemptAssociate() throws {
        
        if state ∉ [.ready, .managing] {
            let msg = "Invalid manager state: \(String(describing: state))"
            DDLogError(msg, tag: TAG)
            throw msg
        }

        do {
            try AferoSofthub.cancelSendWifiCredentialToHub(withId: deviceId)
        } catch {
            DDLogError("Caught error on cancelAttemptAssociate: \(String(describing: error))", tag: TAG)
            throw error
        }
        
    }

}

