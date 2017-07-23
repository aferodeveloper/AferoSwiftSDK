//
//  DeviceModelState.swift
//  Pods
//
//  Created by Justin Middleton on 7/19/17.
//
//

import Foundation
import CocoaLumberjack

/// Metadata about an Afero device's state.

struct DeviceModelState: CustomDebugStringConvertible, Hashable, AferoJSONCoding {
    
    var debugDescription: String {
        
        var locationString = "<nil>"
        if let locationState = locationState { locationString = String(reflecting: locationState) }
        
        return "<DeviceModelState> rssi:\(rssi) available:\(available) visible:\(visible) dirty:\(dirty) rebooted:\(rebooted) connectable:\(connectable) connected:\(connected) direct:\(direct) linked:\(linked) locationState:\(locationString) hubConnectInfo:\(String(reflecting: hubConnectInfo)) deviceLocalityId:\(String(describing: deviceLocalityId)) setupState: \(String(describing: setupState)) updatedTimestamp:\(String(describing: updatedTimestamp)) updatedTimestampMillis: \(String(describing: updatedTimestampMillis)))"
    }
    
    static let TAG = "DeviceModelState"
    
    /// Whether or not the device is available.
    var available: Bool = false
    
    /// Whether or not the device is visible
    var visible: Bool = false
    
    /// Whether or not the device is "dirty" and needs to be refreshed.
    var dirty: Bool = false
    
    /// Whether or not the device rebooted recently.
    var rebooted: Bool = false
    
    /// Whether or not the device is connectable.
    var connectable: Bool = false
    
    /// Whether or not the device is connected.
    var connected: Bool = false
    
    /// If true, the device is connected directly to the Afero cloud. If false,
    /// the device is connected via a hub.
    var direct: Bool = false
    
    /// The RSSI of the device's connection to its hub, or to the Afero cloud
    /// if direct.
    var rssi: Int = 0
    
    /// The location state of the device.
    var locationState: LocationState?
    
    /// Whether or not the device is currently linked and communicating
    /// with the Afero cloud.
    var linked: Bool = false
    
    /// The timestamp of the most recent update.
    var updatedTimestamp: Date {
        return Date.dateWithMillisSince1970(updatedTimestampMillis)
    }
    
    /// The raw timestamp value of the most recent upate
    var updatedTimestampMillis: NSNumber = NSNumber(value: 0)
    
    /// The locality id of the device.
    var deviceLocalityId: String?
    
    /// Information about the hub through which the device
    /// is currently connected.
    var hubConnectInfo: [HubConnectInfo]
    
    /// The setupState of the device (deprecated)
    @available(*, deprecated, message: "setupState is deprecated and will be removed in a future release.")
    var setupState: String?
    
    init(available: Bool = false, visible: Bool = false, dirty: Bool = false, rebooted: Bool = false, connectable: Bool = false, connected: Bool = false, direct: Bool = false, rssi: Int = 0, locationState: LocationState = .notLocated, linked: Bool = false, updatedTimestampMillis: NSNumber = NSNumber(value: 0), deviceLocalityId: String? = nil, hubConnectInfo: [HubConnectInfo] = [], setupState: String? = nil) {
        
        self.available = available
        self.visible = visible
        self.dirty = dirty
        self.rebooted = rebooted
        self.connectable = connectable
        self.connected = connected
        self.direct = direct
        self.rssi = rssi
        self.locationState = locationState
        self.linked = linked
        self.updatedTimestampMillis = updatedTimestampMillis
        self.deviceLocalityId = deviceLocalityId
        self.hubConnectInfo = hubConnectInfo
        self.setupState = setupState
    }
    
    // MARK: <Hashable>
    
    static func ==(lhs: DeviceModelState, rhs: DeviceModelState) -> Bool {
        
        if let lls = lhs.locationState, let rls = rhs.locationState {
            if !(lls == rls) { return false }
        } else {
            if !((lhs.locationState == nil) && (rhs.locationState == nil)) { return false }
        }
        
        
        return lhs.available == rhs.available
        && lhs.visible == rhs.visible
        && lhs.dirty == rhs.dirty
        && lhs.rebooted == rhs.rebooted
        && lhs.connected == rhs.connected
        && lhs.connectable == rhs.connectable
        && lhs.rssi == rhs.rssi
        && lhs.updatedTimestampMillis == rhs.updatedTimestampMillis
        && lhs.hubConnectInfo == rhs.hubConnectInfo
        && lhs.deviceLocalityId == rhs.deviceLocalityId
        && lhs.setupState == rhs.setupState
    }
    
    public var hashValue: Int {
        return available.hashValue
            ^ visible.hashValue
            ^ dirty.hashValue
            ^ rebooted.hashValue
            ^ connectable.hashValue
            ^ connected.hashValue
            ^ rssi.hashValue
            ^ updatedTimestampMillis.hashValue
            ^ hubConnectInfo.count
    }
    
    // MARK: <AferoJSONCoding>
    
    static var CoderKeyAvailable: String { return "available" }
    static var CoderKeyVisible: String { return "visible" }
    static var CoderKeyDirty: String { return "dirty" }
    static var CoderKeyRebooted: String { return "rebooted" }
    static var CoderKeyConnectable: String { return "connectable" }
    static var CoderKeyConnected: String { return "connected" }
    static var CoderKeyDirect: String { return "direct" }
    static var CoderKeyRSSI: String { return "rssi" }
    static var CoderKeyLocation: String { return "location" }
    static var CoderKeyLinked: String { return "linked" }
    static var CoderKeyUpdatedTimestamp: String { return "updatedTimestamp" }
    static var CoderKeyDeviceLocalityId: String { return "deviceLocalityId" }
    static var CoderKeyHubConnectInfo: String { return "hubConnectInfo" }
    static var CoderKeySetupState: String { return "setupState" }
    
    var JSONDict: AferoJSONCodedType? {
        var ret: [String: Any] = [
            type(of: self).CoderKeyAvailable: available,
            type(of: self).CoderKeyVisible: visible,
            type(of: self).CoderKeyDirty: dirty,
            type(of: self).CoderKeyRebooted: rebooted,
            type(of: self).CoderKeyConnectable: connectable,
            type(of: self).CoderKeyConnected: connected,
            type(of: self).CoderKeyDirect: direct,
            type(of: self).CoderKeyRSSI: rssi,
            type(of: self).CoderKeyLinked: linked,
            type(of: self).CoderKeyUpdatedTimestamp: updatedTimestampMillis,
        ]
        
        if case let .some(.located(location)) = locationState,
            let locationJSON = location.JSONDict {
            ret[type(of: self).CoderKeyLocation] = locationJSON
        }
        
        if let deviceLocalityId = deviceLocalityId {
            ret[type(of: self).CoderKeyDeviceLocalityId] = deviceLocalityId
        }
        
        if hubConnectInfo.count > 0 {
            ret[type(of: self).CoderKeyHubConnectInfo] = hubConnectInfo.flatMap { $0.JSONDict }
        }
        
        if let setupState = setupState {
            ret[type(of: self).CoderKeySetupState] = setupState
        }
        
        return ret
    }
    
    init?(json: AferoJSONCodedType?) {

        guard let jsonDict = json as? [String: Any] else {
            DDLogDebug("Not a dict, bailing: \(String(reflecting: json))")
            return nil
        }
        
        var locationState: LocationState = .notLocated
        if let location: DeviceLocation = |<(jsonDict[type(of: self).CoderKeyLocation] as? [String: Any]) {
            locationState = .located(at: location)
        }
        
        var hubConnectInfo: [HubConnectInfo] = []
        if let maybeHubConnectInfo: [HubConnectInfo] = |<(jsonDict[type(of: self).CoderKeyHubConnectInfo] as? [[String: Any]]) {
            hubConnectInfo = maybeHubConnectInfo
        }
        
        guard
            let available = jsonDict[type(of: self).CoderKeyAvailable] as? Bool,
            let visible = jsonDict[type(of: self).CoderKeyVisible] as? Bool,
            let dirty = jsonDict[type(of: self).CoderKeyDirty] as? Bool,
            let rebooted = jsonDict[type(of: self).CoderKeyRebooted] as? Bool,
            let connectable = jsonDict[type(of: self).CoderKeyConnectable] as? Bool,
            let connected = jsonDict[type(of: self).CoderKeyConnected] as? Bool,
            let direct = jsonDict[type(of: self).CoderKeyDirect] as? Bool,
            let rssi = jsonDict[type(of: self).CoderKeyRSSI] as? Int,
            let linked = jsonDict[type(of: self).CoderKeyLinked] as? Bool,
            let updatedTimestampMillis = jsonDict[type(of: self).CoderKeyUpdatedTimestamp] as? NSNumber
        else {
                DDLogError("Invalid DeviceModelState (missing one of 'available', 'visible', 'dirty', 'rebooted', 'connectable', 'connected', 'direct', rssi: \(String(reflecting: jsonDict))", tag: DeviceModelState.TAG)
                return nil
        }
        
        self.init(
            available: available,
            visible: visible,
            dirty: dirty,
            rebooted: rebooted,
            connectable: connectable,
            connected: connected,
            direct: direct,
            rssi: rssi,
            locationState: locationState,
            linked: linked,
            updatedTimestampMillis: updatedTimestampMillis,
            deviceLocalityId: jsonDict[type(of: self).CoderKeyDeviceLocalityId] as? String,
            hubConnectInfo: hubConnectInfo,
            setupState: jsonDict[type(of: self).CoderKeySetupState] as? String
        )
        
    }
    
    /// Information describing a hub through which a device is connected
    struct HubConnectInfo: Hashable, AferoJSONCoding {
        
        /// The deviceId of the hub.
        var deviceId: String?
        
        /// Whether or not the hub is visible.
        var visible: Bool?
        
        /// Whether or not the hub is connected to the Afero cloud.
        var connected: Bool?
        
        /// Whether or not the hub is connectable.
        var connectable: Bool?
        
        /// The RSSI of the hub's connection to the Afero Cloud.
        var rssi: Int?
        
        /// The friendlyName of the hub.
        var friendlyName: String?
        
        init(deviceId: String? = nil, visible: Bool? = nil, connected: Bool? = nil, connectable: Bool? = nil, rssi: Int? = nil, friendlyName: String? = nil) {
            self.deviceId = deviceId
            self.visible = visible
            self.connected = connected
            self.connectable = connectable
            self.rssi = rssi
            self.friendlyName = friendlyName
        }
        
        // MARK: <Hashable>
        
        static func ==(lhs: HubConnectInfo, rhs: HubConnectInfo) -> Bool {
            return lhs.deviceId == rhs.deviceId
                && lhs.visible == rhs.visible
                && lhs.connected == rhs.connected
                && lhs.connectable == rhs.connectable
                && lhs.rssi == rhs.rssi
                && lhs.friendlyName == rhs.friendlyName
        }
        
        var hashValue: Int { return deviceId?.hashValue ?? 0 }
        
        // MARK: <AferoJSONCoding>
        
        static var CoderKeyDeviceId: String { return "deviceId" }
        static var CoderKeyVisible: String { return "visible" }
        static var CoderKeyConnected: String { return "connected" }
        static var CoderKeyConnectable: String { return "connectable" }
        static var CoderKeyRSSI: String { return "rssi" }
        static var CoderKeyFriendlyName: String { return "friendlyName" }
        
        var JSONDict: AferoJSONCodedType? {
        
            var ret: [String: Any] = [:]
            
            if let deviceId = deviceId {
                ret[type(of: self).CoderKeyDeviceId] = deviceId
            }
            if let visible = visible {
                ret[type(of: self).CoderKeyVisible] = visible
            }
            if let connected = connected {
                ret[type(of: self).CoderKeyConnected] = connected
            }
            if let connectable = connectable {
                ret[type(of: self).CoderKeyConnectable] = connectable
            }
            if let rssi = rssi {
                ret[type(of: self).CoderKeyRSSI] = rssi
            }
            if let friendlyName = friendlyName {
                ret[type(of: self).CoderKeyFriendlyName] = friendlyName
            }
            
            return ret

        }
        
        init?(json: AferoJSONCodedType?) {

            guard let jsonDict = json as? [String: Any] else {
                DDLogDebug("Unable to decode \(String(reflecting: json)) as HubConnectInfo dict.")
                return nil
            }
            
            self.init(
                deviceId: jsonDict[type(of: self).CoderKeyDeviceId] as? String,
                visible: jsonDict[type(of: self).CoderKeyVisible] as? Bool,
                connected: jsonDict[type(of: self).CoderKeyConnected] as? Bool,
                connectable: jsonDict[type(of: self).CoderKeyConnectable] as? Bool,
                rssi: jsonDict[type(of: self).CoderKeyRSSI] as? Int,
                friendlyName: jsonDict[type(of: self).CoderKeyFriendlyName] as? String
            )
            
        }
        
    }
    
}

struct DeviceModelTag {
    
    var id: String
    var localizationKey: String
    var value: String
    var type: String
    
}
