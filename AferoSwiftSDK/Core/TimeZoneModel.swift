//
//  TimeZoneModel.swift
//  Pods
//
//  Created by Justin Middleton on 8/31/17.
//
//

import Foundation
import CocoaLumberjack

/// Represents timezone information for a peripheral.

public enum TimeZoneState: Equatable {
    
    /// The timeZone needs to be fetched or refetched from the cloud.
    /// If `error` is non-nil, then there was an error fetching previoiusly.
    case invalid(error: Error?)
    
    /// The timeZone is in the process of being fetched from the Afero cloud.
    case pendingUpdate
    
    /// The device's timezone state is known to be empty.
    case none
    
    /// The device has a `timeZone`. If `isUserOverride` is true, then
    /// the user has manually set the `timeZone` and it may differ from
    /// that inferred by the device's location. If `false`, then the `timeZone`
    /// was inferred from the device's location.
    case some(timeZone: TimeZone, isUserOverride: Bool)

    /// The timezone, if any, represented by this object.
    var timeZone: TimeZone? {
        if case let .some(timeZone, _) = self {
            return timeZone
        }
        return nil
    }
    
    /// The error, if any, associated with this object.
    var error: Error? {
        if case let .invalid(error) = self {
            return error
        }
        return nil
    }
    
    // MARK: <Equatable>
    
    public static func ==(lhs: TimeZoneState, rhs: TimeZoneState) -> Bool {

        switch(lhs, rhs) {
            
        case let (.some(ltz,luo), .some(rtz,ruo)):
            return ltz == rtz && luo == ruo
            
        case (.invalid, .invalid):             fallthrough
        case (.pendingUpdate, .pendingUpdate): fallthrough
        case (.none, .none):
            return true
            
        default:
            return false
        }
        
    }
    
    
}

extension TimeZoneState: AferoJSONCoding {
    
    static let CoderKeyUserOverride = "userOverride"
    static let CoderKeyTimeZone = "timezone"
    
    public var JSONDict: AferoJSONCodedType? {
    
        if case let .some(timeZone, isUserOverride) = self {
            return [
                type(of: self).CoderKeyTimeZone: timeZone.identifier,
                type(of: self).CoderKeyUserOverride: isUserOverride
            ]
        }
        
        return nil
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard let json = json else {
            self = .none
            return
        }
        
        let TAG = "TimeZoneState"

        guard let jsonDict = json as? [String: Any] else {
            DDLogError("Not a JSON dictionary: \(json)", tag: TAG)
            self = .invalid(error: "Invalid encoding.")
            return
        }
        
        guard let timeZoneId = jsonDict[type(of: self).CoderKeyTimeZone] as? String else {
            DDLogError("No timezone found.", tag: TAG)
            self = .invalid(error: "No timeZone id.")
            return
        }
        
        let timeZone: TimeZone

        if let maybeTimeZone = TimeZone(identifier: timeZoneId) {
            timeZone = maybeTimeZone
        } else if let maybeTimeZone = TimeZone(abbreviation: timeZoneId) {
            timeZone = maybeTimeZone
        } else {
            DDLogError("Unable to interpret '\(timeZoneId).", tag: TAG)
            self = .invalid(error: "Invalid timeZone id.")
            return
        }
        
        let isUserOverride: Bool
        if let maybeIsUserOverride = jsonDict[type(of: self).CoderKeyUserOverride] as? Bool {
            isUserOverride = maybeIsUserOverride
        } else {
            DDLogWarn("No userOverride found; assuming false", tag: TAG)
            isUserOverride = false
        }
        
        self = .some(timeZone: timeZone, isUserOverride: isUserOverride)
    }
    
}
