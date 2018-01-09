//
//  ActivityModel.swift
//  iTokui
//
//  Created by Justin Middleton on 7/24/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation


import CocoaLumberjack

public struct HistoryFilter {
    
    public static let defaultFilter = HistoryFilter()
    
    var historyTypes: [HistoryActivity.HistoryType]?
    var deviceIds: [String]?
    var attributeLabelFilter: String?
    
    public init(historyTypes: [HistoryActivity.HistoryType]? = [.attribute, .available, .unavailable, .associate, .disassociate], deviceIds: [String]? = nil, attributeLabelFilter: String? = "attributeLabel NEQ 'NONE'") {
        self.historyTypes = historyTypes
        self.deviceIds = deviceIds
        self.attributeLabelFilter = attributeLabelFilter
    }
    
    public var filterString: String {
        
        var clauses: [String] = []
        
        if let attributeLabelFilter = attributeLabelFilter {
            clauses.append(attributeLabelFilter)
        }
        
        
        if let historyTypes = historyTypes {
            let historyTypesList = historyTypes.map { return "'\($0.rawValue)'" }.joined(separator: ", ")
            clauses.append(
                "historyType in [\(historyTypesList)]")
        }
        
        if let deviceIds = deviceIds {
            let deviceIdsList = deviceIds.map { return "'\($0)'" }.joined(separator: ", ")
            clauses.append("deviceId in [\(deviceIdsList)]")
        }
        
        return clauses.joined(separator: " and ")
    }
}

public struct HistoryActivity: Hashable, Comparable {

    // These are improperly overloaded (filter and event).
    // TODO split out.
    
    public var hashValue: Int {
        return historyId.hashValue
    }
    
    public enum HistoryType: String {

        case new = "NEW"
        case attribute = "ATTRIBUTE"
        case attributeWrite = "ACTION_ATTRIBUTE_WRITE"
        case attributeUpdate = "ACTION_ATTRIBUTE_UPDATE"
        case deviceAvailability = "ACTION_DEVICE_AVAILABILITY"
        case deviceUpdate = "ACTION_DEVICE_UPDATE"
        case available = "AVAILABLE"
        case unavailable = "UNAVAILABLE"
        case state = "STATE"
        case version = "VERSION"
        case connect = "CONNECT"
        case disconnect = "DISCONNECT"
        case disconnectNotification = "DISCONNECT_NOTIFICATION"
        case associate = "ASSOCIATE"
        case disassociate = "DISASSOCIATE"
        case location = "LOCATION"
        case unknown = "<unknown>"
        
    }
    
    public var deviceId: String?
    public var deviceFriendlyName: String?
    public var message: String
    public var historyType: HistoryType
    public var icon: URL?
    public var deviceIcon: URL?
    public var controlIcon: URL?
    public var historyId: String
    public var attributeId: Int?
    public var attributeValue: String?
    
    /// Integer timestamp in millis since Jan 1 1970 00:00:00 GMT
    public var createdTimestamp: NSNumber
    
    // These are expensive to calculate, so do it lazily and cache.

    /// Timestamp as an NSDate
    public var date: Date! {
        return Date.dateWithMillisSince1970(self.createdTimestamp)
    }
    
    public var localizedDayOfYearString: String! {
        return self.date.dayOfYearString
    }
    
    public var localizedTimeComponents: LocalizedTimeComponents! {
        return self.date.localizedTimeComponents
    }
    
    public init(historyId: String, createdTimestamp: NSNumber, message: String, historyType: HistoryType, deviceIcon: URL? = nil, controlIcon: URL? = nil, icon: URL? = nil, deviceId: String?, deviceFriendlyName: String?, attributeId: Int?, attributeValue: String?) {
        self.historyId = historyId
        self.createdTimestamp = createdTimestamp
        self.message = message
        self.historyType = historyType
        self.icon = icon
        self.deviceIcon = deviceIcon
        self.controlIcon = controlIcon
        self.deviceId = deviceId
        self.deviceFriendlyName = deviceFriendlyName
        self.attributeId = attributeId
        self.attributeValue = attributeValue
    }
    
}

public func ==(lhs: HistoryActivity, rhs: HistoryActivity) -> Bool {
    return lhs.historyId == rhs.historyId
}

public func <(lhs: HistoryActivity, rhs: HistoryActivity) -> Bool {

    if lhs.createdTimestamp == rhs.createdTimestamp {
        if let ldfn = lhs.deviceFriendlyName, let rdfn = rhs.deviceFriendlyName {
            return ldfn < rdfn
        }
    }
    
    return lhs.createdTimestamp.int64Value < rhs.createdTimestamp.int64Value
    
}

extension HistoryActivity.HistoryType: AferoJSONCoding {
    
    public var JSONDict: AferoJSONCodedType? {
        return self.rawValue
    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? String {
            self = HistoryActivity.HistoryType(rawValue: json) ?? .unknown
        } else {
            return nil
        }
    }
    
}

extension HistoryActivity: AferoJSONCoding {
    
    static var CoderKeyCreatedTimestamp = "createdTimestamp"
    static var CoderKeyMessage = "message"
    static var CoderKeyDeviceHistoryType = "historyType"
    static var CoderKeyIcon = "icon"
    static var CoderKeyDeviceIcon = "deviceIcon"
    static var CoderKeyControlIcon = "controlIcon"
    static var CoderKeyHistoryId = "historyId"
    static var CoderKeyDeviceId = "deviceId"
    static var CoderKeyDeviceFriendlyName = "deviceFriendlyName"
    static var CoderKeyAttributeId = "attributeId"
    static var CoderKeyAttributeValue = "attributeValue"

    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyHistoryId: historyId,
            type(of: self).CoderKeyCreatedTimestamp: createdTimestamp,
            type(of: self).CoderKeyMessage: message,
            type(of: self).CoderKeyDeviceHistoryType: historyType.rawValue,
        ]

        if let icon = icon {
            ret[type(of: self).CoderKeyDeviceIcon] = icon.absoluteString
        }

        if let deviceIcon = deviceIcon {
            ret[type(of: self).CoderKeyDeviceIcon] = deviceIcon.absoluteString
        }
        
        if let controlIcon = controlIcon {
            ret[type(of: self).CoderKeyControlIcon] = controlIcon.absoluteString
        }

        if let deviceFriendlyName = deviceFriendlyName {
            ret[type(of: self).CoderKeyDeviceFriendlyName] = deviceFriendlyName
        }

        if let deviceId = deviceId {
            ret[type(of: self).CoderKeyDeviceId] = deviceId
        }

        if let attributeId = attributeId {
            ret[type(of: self).CoderKeyAttributeId] = attributeId
        }
        
        if let attributeValue = attributeValue {
            ret[type(of: self).CoderKeyAttributeValue] = attributeValue
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let historyId = json[type(of: self).CoderKeyHistoryId] as? String,
            let timestamp = json[type(of: self).CoderKeyCreatedTimestamp] as? NSNumber,
            let message = json[type(of: self).CoderKeyMessage] as? String,
            let historyType: HistoryActivity.HistoryType = |<json[type(of: self).CoderKeyDeviceHistoryType] {

                var icon: URL? = nil
                if let iconURLString = json[type(of: self).CoderKeyIcon] as? String {
                    icon = URL(string: iconURLString)
                }
                
                var controlIcon: URL? = nil
                if let controlIconURLString = json[type(of: self).CoderKeyControlIcon] as? String {
                    controlIcon = URL(string: controlIconURLString)
                }

                var deviceIcon: URL? = nil
                if let deviceIconURLString = json[type(of: self).CoderKeyDeviceIcon] as? String {
                    deviceIcon = URL(string: deviceIconURLString)
                }

                self.init(
                    historyId: historyId,
                    createdTimestamp: timestamp,
                    message: message,
                    historyType: historyType,
                    deviceIcon: deviceIcon,
                    controlIcon: controlIcon,
                    icon: icon,
                    deviceId: json[type(of: self).CoderKeyDeviceId] as? String,
                    deviceFriendlyName: json[type(of: self).CoderKeyDeviceFriendlyName] as? String,
                    attributeId: json[type(of: self).CoderKeyAttributeId] as? Int,
                    attributeValue: json[type(of: self).CoderKeyAttributeValue] as? String
                )
                
        } else {
            DDLogError("Unable to decode HistoryActivity: \(String(reflecting: json))")
            return nil
        }
    }
}
