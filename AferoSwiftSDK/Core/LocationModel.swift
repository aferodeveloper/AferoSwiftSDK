//
//  LocationModel.swift
//  iTokui
//
//  Created by Martin Arnberg on 8/30/16.
//  Copyright © 2016-2017 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import CoreLocation
import CocoaLumberjack

@available(*, deprecated, message: "Use DeviceLocation")
public typealias LocationModel = DeviceLocation

@available(*, deprecated, message: "Use DeviceLocation.SourceType")
public typealias LocationSourceType = DeviceLocation.SourceType

/// State of geographical location information for an Afero device.
///
/// # Discussion
///
/// Afero devices can optionally have assigned locations, and these locations
/// can be assigned either by the client app at association time; by the client
/// app after assocation time, manually by the user; or automatically by a
/// hub to which the device has connected (and which know its location).
///
/// # States
/// * `.invalid(error: Error)`: The location needs to be refetched from the
///                             Afero cloud. If `error` is non-nil, then the
///                             `.invalid` state was entered due to a previously
///                             failed fetch, and the error from that failure
///                             is attached.
/// * `.pendingUpdate`: The location is in the process of being refetched
///                     from the Afero cloud.
/// * `.notLocated`: The device has no associated location information.
/// * `.located(at: DeviceLocation)`: The device has associated location information, contained
///                    in the associated `DeviceLocation` value.
///
/// # Transitions
///
/// * `.invalid(.none)` → `.pendingUpdate`
/// * `.invalid(.some(Error))` → `.pendingUpdate`
/// * `.pendingUpdate` → `.invalid(.some(Error))`
/// * `.pendingUpdate` → `.notLocated`
/// * `.pendingUpdate` → `.located(at: Location)`
/// * `.notLocated` → `.invalid(.none)`
/// * `.located(at: Location)` → `.invalid(.none)`
///

public enum LocationState: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    
    /// The location needs to be refetched from the Afero cloud. If `error` is
    /// non-nil, then the `.invalid` state was entered due to a previously
    /// failed fetch, and the error from that failure is attached.
    ///
    /// # Entry Condition
    /// * Upon receipt of a location invalidation from the Afero cloud, will enter
    ///   as `.invalid(error: .none)`.
    /// * Upon a failed location fetch, will enter as `.invalid(error: .some(Error))`.
    ///
    /// # Exit Condition
    /// * Upon commencement of a location fetch attempt, will transition to `.pendingUpdate`.
    case invalid(error: Error?)
    
    /// The location is in the process of being refetched from the Afero cloud.
    ///
    /// # Entry Condition
    /// This state is entered when the `DeviceCollection` commences a location fetch
    /// as a result of receiving a location invalidation from the Afero Cloud.
    /// 
    /// # Exit Condition
    /// This state is exited when the corresponding fetch operation completes.
    /// * Upon success, this state will transition to `.notLocated` or `.located(at: DeviceLocation)`.
    /// * Upon failure, this state will transition to `.invalid(error: Error?)` with the
    /// underlying error attached.
    case pendingUpdate
    
    /// The location state is in sync with the service, and is empty.
    ///
    /// # Entry Condition
    /// * Enters this state upon a successful location fetch resulting in a `nil` location.
    ///
    /// # Exit Condition
    /// * Upon receipt of a location invalidation message from the Afero cloud,
    ///   transitions to `.invalid(error: .none)`
    case notLocated
    
    /// # Entry Condition
    /// * Enters this state upon a successful location fetch resulting in a non-`nil` location.
    ///
    /// # Exit Condition
    /// * Upon receipt of a location invalidation message from the Afero cloud,
    ///   transitions to `.invalid(error: .none)`
    case located(at: DeviceLocation)
    
    /// If any, the location of the device.
    public var deviceLocation: DeviceLocation? {
        switch self {
        case let .located(location): return location
        default: return nil
        }
    }
    
    /// If any, the `CLLocation` representing the device's location.
    public var location: CLLocation? {
        return deviceLocation?.location
    }
    
    /// If any, the provenance of the device's location data.
    public var locationSourceType: DeviceLocation.SourceType? {
        return deviceLocation?.sourceType
    }
    
    // MARK: <Equatable>
    
    public static func ==(lhs: LocationState, rhs: LocationState) -> Bool {
        switch (lhs, rhs) {
        case (.notLocated, .notLocated): return true
        case let (.located(lloc), .located(rloc)):
            return lloc == rloc
        default:
            return false
        }
    }
    
    // MARK: <CustomStringConvertible>
    
    public var description: String {
    
        switch self {
        case let .invalid(error):
            if let error = error {
                return "Invalid (error: \(String(describing: error)))"
            }
            return "Invalid"
            
        case .pendingUpdate:
            return "Pending update"
            
        case .notLocated:
            return "Not located"
            
        case let .located(location):
            return "Located at \(String(describing: location))"
        }
    }
    
    // MARK: <CustomStringDebugConvertible>
    
    public var debugDescription: String {

        switch self {
        case let .invalid(error):
            if let error = error {
                return "LocationState.invalid(error: \(String(reflecting: error)))"
            }
            return "LocationState.invalid(error: nil)"
            
        case .pendingUpdate:
            return "LocationState.pendingUpdate"
            
        case .notLocated:
            return "LocationState.notLocated"
            
        case let .located(location):
            return "LocationState.located(at:\(String(reflecting: location)))"
        }
    
    }
    
}

/// The Afero-native representation of a device's location data.
///
/// Afero devices can optionally have assigned locations, and these locations
/// can be assigned either by the client app at association time; by the client
/// app after assocation time, manually by the user; or automatically by a
/// hub to which the device has connected (and which know its location).

public struct DeviceLocation: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return "Location: \(String(describing: location)), source: \(String(describing: sourceType))"
    }
    
    public var debugDescription: String {
        return "<DeviceLocation> location:\(String(reflecting: location)) sourceType:\(String(reflecting: sourceType)) formattedAddressLines:\(String(reflecting: formattedAddressLines))"
    }
    
    /// The CLLocation reresenting the physical location of the device.
    public var location: CLLocation
    
    public var timestamp: Date {
        return location.timestamp
    }
    
    public var coordinate: CLLocationCoordinate2D {
        return location.coordinate
    }
    
    public var latitude: CLLocationDegrees {
        return coordinate.latitude
    }
    
    public var longitude: CLLocationDegrees {
        return coordinate.longitude
    }
    
    public var altitude: CLLocationDistance {
        return location.altitude
    }
    
    public var verticalAccuracy: CLLocationAccuracy {
        return location.verticalAccuracy
    }
    
    public var horizontalAccuracy: CLLocationAccuracy {
        return location.horizontalAccuracy
    }
    
    public var course: CLLocationDirection {
        return location.course
    }
    
    public var speed: CLLocationSpeed {
        return location.speed
    }
    
    var floor: CLFloor? {
        return location.floor
    }
    
    /// The source of location data for a device.
    /// - `.initialDeviceAssociate`: The location was provided by the client
    ///                              that associated the device with the account.
    /// - `.hubLocationGPS`: The location was provided by the last connected
    ///                      hub's onboard GPS.
    /// - `.hubLocationIP`: The location was estimated based upon the last
    ///                     connected hub's ip address.
    /// - `.userDefinedLocation`: The location was manually provided.
    /// - `.clientIPEstimate`: Location was estimated based upon client IP address.
    
    public enum SourceType: String {
        
        /// The location was provided by the client
        /// that associated the device with the account.
        case initialDeviceAssociate = "INITIAL_DEVICE_ASSOCIATE"
        
        /// The location was provided by the last connected
        /// hub's onboard GPS.
        case hubLocationGPS = "HUB_LOCATION_GPS"
        
        /// The location was estimated based upon the last connected
        /// hub's ip address.
        case hubLocationIP = "HUB_LOCATION_IP"
        
        /// The location was manually provided.
        case userDefinedLocation = "USER_DEFINED_LOCATION"
        
        /// Location was estimated based upon client IP address.
        case clientIPEstimate = "CLIENT_IP_ESTIMATE"
        
    }
    
    /// The provenance of the location data.
    public var sourceType: SourceType
    
    /// The provenance of the location data (deprecated, use `sourceType` instead).
    @available(*, deprecated, message: "Use `sourceType` instead.")
    public var locationSourceType: SourceType {
        return sourceType
    }
    
    /// The reverse-geocoded locality, if provided.
    ///
    /// - note: Content may differ from what could be obtained with
    ///         `CLGeocoder.reverseGeocodeLocation(_:_)`.
    public var formattedAddressLines: [String]?
    
    /// Designated initializier.
    /// - parameter location: The CLLocation reresenting the physical location
    ///                       of the device. Copied.
    /// - parameter sourceType: The provenance of the location designation.
    /// - parameter formattedAddressLines: If provided, the formatted, reverse-geocoded location
    ///                                    of the device.
    ///
    /// - note:  `formattedAddressLines` content may differ from what could
    ///           be obtained with `CLGeocoder.reverseGeocodeLocation(_:_:)`.
    
    init(location: CLLocation = CLLocation(), sourceType: SourceType = SourceType.clientIPEstimate, formattedAddressLines: [String]? = nil) {
        self.location = location.copy() as! CLLocation
        self.sourceType = sourceType
        self.formattedAddressLines = formattedAddressLines
    }
    
    /// - parameter coordinate: A coordinate structure containing the latitude
    ///                         and longitude values.
    ///
    /// - parameter altitude: The altitude value for the location.
    ///
    /// - parameter horizontalAccuracy: The accuracy of the coordinate value.
    ///                                 Specifying a negative number indicates
    ///                                 that the coordinate value is invalid.
    ///
    /// - parameter verticalAccuracy: The accuracy of the altitude value.
    ///                               Specifying a negative number indicates that
    ///                               the altitude value is invalid.
    ///
    /// - parameter course: The direction of travel for the location.
    ///
    /// - parameter speed: The current speed associated with this location.
    ///
    /// - parameter timestamp: The time to associate with the location object.
    ///                        Typically, you would set this to the current time.
    
    init(
        coordinate: CLLocationCoordinate2D,
        altitude: CLLocationDistance = CLLocationDistance(),
        horizontalAccuracy: CLLocationAccuracy = CLLocationDistance(),
        verticalAccuracy: CLLocationAccuracy = CLLocationDistance(),
        course: CLLocationDirection = CLLocationDirection(),
        speed: CLLocationSpeed = CLLocationSpeed(),
        timestamp: Date = Date(),
        sourceType: SourceType = .clientIPEstimate,
        formattedAddressLines: [String]? = nil
        ) {
        
        let location = CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: timestamp
        )
        
        self.init(
            location: location,
            sourceType: sourceType,
            formattedAddressLines: formattedAddressLines
        )
    }

    /// - parameter latitude: The device's latitude.
    /// - parameter longitude: The device's longitude.
    /// - parameter timestamp: The time to associate with the location object.
    ///                        Typically, you would set this to the current time.
    /// - parameter sourceType: The `SourceType` of the location.
    /// - parameter formattedAddressLines: If provided, the formatted, reverse-geocoded location
    ///                                    of the device.
    ///
    /// - note:  `formattedAddressLines` content may differ from what could
    ///           be obtained with `CLGeocoder.reverseGeocodeLocation(_:_)`.
    ///
    /// - seealso: `LocationState.DeviceLocation.SourceType`
    
    init(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        timestamp: Date = Date(),
        sourceType: SourceType,
        formattedAddressLines: [String]? = nil
        ) {
        
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            timestamp: timestamp,
            sourceType: sourceType,
            formattedAddressLines: formattedAddressLines
        )
    }
    
    // MARK: <Equatable>
    
    public static func ==(lhs: DeviceLocation, rhs: DeviceLocation) -> Bool {
        
        return lhs.latitude == rhs.latitude
            && lhs.longitude == rhs.longitude
            && lhs.altitude == rhs.altitude
            && lhs.horizontalAccuracy == rhs.horizontalAccuracy
            && lhs.verticalAccuracy == rhs.verticalAccuracy
            && lhs.course == rhs.course
            && lhs.speed == rhs.speed
            && lhs.sourceType == rhs.sourceType
            && (lhs.formattedAddressLines ?? []) == (rhs.formattedAddressLines ?? [])
    }
    
    // MARK: <Hashable>
    
    public var hashValue: Int {
        return location.hashValue ^ sourceType.hashValue ^ (formattedAddressLines?.count ?? 0)
    }
    
}


extension DeviceLocation: AferoJSONCoding {
    
    static let CoderKeyLatitude = "latitude"
    static let CoderKeyLongitude = "longitude"
    static let CoderKeyLocationSourceType = "locationSourceType"
    static let CoderKeyCreatedFormattedAddressLines = "formattedAddressLines"
    static let CoderKeyLastUpdatedTimestampMillis = "lastUpdatedTimestamp"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyLatitude: String(location.coordinate.latitude),
            type(of: self).CoderKeyLongitude: String(location.coordinate.longitude),
            type(of: self).CoderKeyLocationSourceType: sourceType.rawValue,
            type(of: self).CoderKeyLastUpdatedTimestampMillis: timestamp.millisSince1970,
        ]
        
        if let formattedAddressLines = formattedAddressLines {
            ret[type(of: self).CoderKeyCreatedFormattedAddressLines] = formattedAddressLines
        }
    
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard let jsonDict = json as? [String: Any] else {
            DDLogError("Unable to decode Location: \(String(reflecting: json))")
            return nil
        }
        
        guard
            let latitudeString = jsonDict[type(of: self).CoderKeyLatitude] as? String,
            let latitude = CLLocationDegrees(latitudeString),
            let longitudeString = jsonDict[type(of: self).CoderKeyLongitude] as? String,
            let longitude = CLLocationDegrees(longitudeString),
            let locationSourceTypeString = jsonDict[type(of: self).CoderKeyLocationSourceType] as? String,
            let locationSourceType = SourceType(rawValue: locationSourceTypeString),
            let lastUpdatedTimestampMillis = jsonDict[type(of: self).CoderKeyLastUpdatedTimestampMillis] as? NSNumber else {
                DDLogError("Unable to decode Location: \(String(reflecting: json))")
                return nil
        }
        
        self.init(
            latitude: latitude,
            longitude: longitude,
            timestamp: Date.dateWithMillisSince1970(lastUpdatedTimestampMillis),
            sourceType: locationSourceType,
            formattedAddressLines: jsonDict[type(of: self).CoderKeyCreatedFormattedAddressLines] as? [String]
        )
    }
    
}

extension CLLocation {
    
    /// Convenience method for converting a `CLLocation` to a `DeviceLocation`
    /// - parameter sourceType: The sourceType to use; defaults to `.userDefinedLocation`.
    /// - parameter formattedAddressLines: The geocoded address lines to use, if any. Defaults to nil.
    /// - returns: A `DeviceLocation` instance backed by a copy of the receiver.
    
    func deviceLocation(with sourceType: DeviceLocation.SourceType = .userDefinedLocation, formattedAddressLines: [String]? = nil) -> DeviceLocation {
        return DeviceLocation(location: self, sourceType: sourceType, formattedAddressLines: formattedAddressLines)
    }
    
}
