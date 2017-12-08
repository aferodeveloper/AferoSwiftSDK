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

public struct DeviceModelState: CustomDebugStringConvertible, Hashable, AferoJSONCoding {
    
    public var debugDescription: String {
        
        var locationString = "<nil>"
        if let locationState = locationState { locationString = String(reflecting: locationState) }
        
        return "<DeviceModelState> rssi:\(RSSI) available:\(isAvailable) visible:\(isVisible) dirty:\(isDirty) rebooted:\(isRebooted) connectable:\(isConnectable) connected:\(isConnected) direct:\(isDirect) linked:\(isLinked) locationState:\(locationString) deviceLocalityId:\(String(describing: deviceLocalityId)) updatedTimestamp:\(String(describing: updatedTimestamp)) updatedTimestampMillis: \(String(describing: updatedTimestampMillis)))"
    }
    
    static let TAG = "DeviceModelState"
    
    /// Whether or not the device is available.
    ///
    /// - note: Calculation of `isAvailable` is based upon `isDirect`, `isVisible`,
    ///         `isRebooted`, `isConnectablre`, `isConnected`, `isLinked`, and `isDirty`.
    ///         Generally, application developers only need be concerned with `isAvailable`
    var isAvailable: Bool = false
    
    /// Whether or not a hub can see the device.
    var isVisible: Bool = false
    
    /// Whether or not the device rebooted recently.
    var isRebooted: Bool = false
    
    /// Whether or not the device is connectable.
    var isConnectable: Bool = false
    
    /// Whether or not the device is connected to the Afero cloud.
    var isConnected: Bool = false
    
    /// Whether or not the device is currently linked and communicating
    /// with the Afero cloud.
    var isLinked: Bool = false
    
    /// If true, the device is connected directly to the Afero cloud. If false,
    /// the device is connected via a hub.
    var isDirect: Bool = false
    
    /// The device has one or more attributes pending write to the Afero cloud.
    var isDirty: Bool = false
    
    /// The RSSI of the device's connection to its hub, or to the Afero cloud
    /// if direct.
    var RSSI: Int = 0
    
    /// The location state of the device.
    var locationState: LocationState?
    
    /// The timestamp of the most recent update.
    var updatedTimestamp: Date {
        get { return Date.dateWithMillisSince1970(updatedTimestampMillis) }
        set { updatedTimestampMillis = newValue.millisSince1970 }
    }
    
    /// The raw timestamp value of the most recent upate
    var updatedTimestampMillis: NSNumber = NSNumber(value: 0)
    
    /// A UUID identifying a geographical grouping of the device (region, county, zipcode), used
    /// for backend processing purposes, if any.
    var deviceLocalityId: String?
    
    init(isAvailable: Bool = false, isVisible: Bool = false, isDirty: Bool = false, isRebooted: Bool = false, isConnectable: Bool = false, isConnected: Bool = false, isDirect: Bool = false, RSSI: Int = 0, locationState: LocationState = .notLocated, isLinked: Bool = false, updatedTimestampMillis: NSNumber, deviceLocalityId: String? = nil) {
        
        self.isAvailable = isAvailable
        self.isVisible = isVisible
        self.isDirty = isDirty
        self.isRebooted = isRebooted
        self.isConnectable = isConnectable
        self.isConnected = isConnected
        self.isDirect = isDirect
        self.RSSI = RSSI
        self.locationState = locationState
        self.isLinked = isLinked
        self.updatedTimestampMillis = updatedTimestampMillis
        self.deviceLocalityId = deviceLocalityId
    }
    
    init(isAvailable: Bool = false, isVisible: Bool = false, isDirty: Bool = false, isRebooted: Bool = false, isConnectable: Bool = false, isConnected: Bool = false, isDirect: Bool = false, RSSI: Int = 0, locationState: LocationState = .notLocated, isLinked: Bool = false, updatedTimestamp: Date = Date(), deviceLocalityId: String? = nil) {

        self.init(
            isAvailable: isAvailable,
            isVisible: isVisible,
            isDirty: isDirty,
            isRebooted: isRebooted,
            isConnectable: isConnectable,
            isConnected: isConnected,
            isDirect: isDirect,
            RSSI: RSSI,
            locationState: locationState,
            isLinked: isLinked,
            updatedTimestampMillis: updatedTimestamp.millisSince1970,
            deviceLocalityId: deviceLocalityId
        )
    }
    
    // MARK: <Hashable>
    
    public static func ==(lhs: DeviceModelState, rhs: DeviceModelState) -> Bool {
        
        if let lls = lhs.locationState, let rls = rhs.locationState {
            if !(lls == rls) { return false }
        } else {
            if !((lhs.locationState == nil) && (rhs.locationState == nil)) { return false }
        }
        
        
        return lhs.isAvailable == rhs.isAvailable
            && lhs.isVisible == rhs.isVisible
            && lhs.isDirty == rhs.isDirty
            && lhs.isRebooted == rhs.isRebooted
            && lhs.isConnected == rhs.isConnected
            && lhs.isConnectable == rhs.isConnectable
            && lhs.isDirect == rhs.isDirect
            && lhs.RSSI == rhs.RSSI
            && lhs.isLinked == rhs.isLinked
            && lhs.updatedTimestampMillis == rhs.updatedTimestampMillis
            && lhs.deviceLocalityId == rhs.deviceLocalityId
    }
    
    public var hashValue: Int {
        return isAvailable.hashValue
            ^ isVisible.hashValue
            ^ isDirty.hashValue
            ^ isRebooted.hashValue
            ^ isConnectable.hashValue
            ^ isConnected.hashValue
            ^ RSSI.hashValue
            ^ updatedTimestampMillis.hashValue
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
    
    public var JSONDict: AferoJSONCodedType? {
        var ret: [String: Any] = [
            type(of: self).CoderKeyAvailable: isAvailable,
            type(of: self).CoderKeyVisible: isVisible,
            type(of: self).CoderKeyDirty: isDirty,
            type(of: self).CoderKeyRebooted: isRebooted,
            type(of: self).CoderKeyConnectable: isConnectable,
            type(of: self).CoderKeyConnected: isConnected,
            type(of: self).CoderKeyDirect: isDirect,
            type(of: self).CoderKeyRSSI: RSSI,
            type(of: self).CoderKeyLinked: isLinked,
            type(of: self).CoderKeyUpdatedTimestamp: updatedTimestampMillis,
        ]
        
        if case let .some(.located(location)) = locationState,
            let locationJSON = location.JSONDict {
            ret[type(of: self).CoderKeyLocation] = locationJSON
        }
        
        if let deviceLocalityId = deviceLocalityId {
            ret[type(of: self).CoderKeyDeviceLocalityId] = deviceLocalityId
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard let jsonDict = json as? [String: Any] else {
            DDLogDebug("Not a dict, bailing: \(String(reflecting: json))")
            return nil
        }
        
        var locationState: LocationState = .notLocated
        if let location: DeviceLocation = |<(jsonDict[type(of: self).CoderKeyLocation] as? [String: Any]) {
            locationState = .located(at: location)
        }
        
        guard
            let available = jsonDict[type(of: self).CoderKeyAvailable] as? Bool,
            let visible = jsonDict[type(of: self).CoderKeyVisible] as? Bool,
            let dirty = jsonDict[type(of: self).CoderKeyDirty] as? Bool,
            let rebooted = jsonDict[type(of: self).CoderKeyRebooted] as? Bool,
            let connectable = jsonDict[type(of: self).CoderKeyConnectable] as? Bool,
            let connected = jsonDict[type(of: self).CoderKeyConnected] as? Bool,
            let direct = jsonDict[type(of: self).CoderKeyDirect] as? Bool,
            let RSSI = jsonDict[type(of: self).CoderKeyRSSI] as? Int,
            let linked = jsonDict[type(of: self).CoderKeyLinked] as? Bool,
            let updatedTimestampMillis = jsonDict[type(of: self).CoderKeyUpdatedTimestamp] as? NSNumber
        else {
                DDLogError("Invalid DeviceModelState (missing one of 'available', 'visible', 'dirty', 'rebooted', 'connectable', 'connected', 'direct', rssi: \(String(reflecting: jsonDict))", tag: DeviceModelState.TAG)
                return nil
        }
        
        self.init(
            isAvailable: available,
            isVisible: visible,
            isDirty: dirty,
            isRebooted: rebooted,
            isConnectable: connectable,
            isConnected: connected,
            isDirect: direct,
            RSSI: RSSI,
            locationState: locationState,
            isLinked: linked,
            updatedTimestampMillis: updatedTimestampMillis,
            deviceLocalityId: jsonDict[type(of: self).CoderKeyDeviceLocalityId] as? String
        )
        
    }
    
}

extension DeviceModelState {
    
    mutating func update(with status: DeviceStreamEvent.Peripheral.Status) {

        if let isAvailable = status.isAvailable {
            self.isAvailable = isAvailable
        }
        
        if let isVisible = status.isVisible {
            self.isVisible = isVisible
        }
        
        if let isDirty = status.isDirty {
            self.isDirty = isDirty
        }

        if let isConnectable = status.isConnectable {
            self.isConnectable = isConnectable
        }

        if let isConnected = status.isConnected {
            self.isConnected = isConnected
        }
        
        if let isRebooted = status.isRebooted {
            self.isRebooted = isRebooted
        }

        if let isDirect = status.isDirect {
            self.isDirect = isDirect
        }

        if let RSSI = status.RSSI {
            self.RSSI = RSSI
        }

    }
}


