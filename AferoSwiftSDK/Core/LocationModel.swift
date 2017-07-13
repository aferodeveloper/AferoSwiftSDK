//
//  LocationModel.swift
//  iTokui
//
//  Created by Martin Arnberg on 8/30/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation

import CocoaLumberjack

public enum LocationSourceType: String {
    case initialDeviceAssociate = "INITIAL_DEVICE_ASSOCIATE"
    case hubLocationGPS = "HUB_LOCATION_GPS"
    case userDefinedLocation = "USER_DEFINED_LOCATION"
}

public enum LocationState: Equatable {
    case invalid
    case none
    case valid(location: LocationModel)
}

public func ==(lhs: LocationState, rhs: LocationState) -> Bool {
    switch (lhs, rhs) {
    case (.invalid, .invalid): fallthrough
    case (.none, .none): return true
    case let (.valid(lloc), .valid(rloc)):
        return lloc == rloc
    default:
        return false
    }
}

public struct LocationModel: Equatable {
    public var latitude: Double
    public var longitude: Double
    public var locationSourceType: LocationSourceType
    public var formattedAddressLines: [String]?
}

public func ==(lhs: LocationModel, rhs: LocationModel) -> Bool {
    
    return lhs.latitude == rhs.latitude
        && lhs.longitude == rhs.longitude
        && lhs.locationSourceType == rhs.locationSourceType
        && lhs.formattedAddressLines == rhs.formattedAddressLines
}

extension LocationModel: AferoJSONCoding {
    static let CoderKeyLatitude = "latitude"
    static let CoderKeyLongitude = "longitude"
    static let CoderKeyLocationSourceType = "locationSourceType"
    static let CoderKeyCreatedFormattedAddressLines = "formattedAddressLines"
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [:]
        
        ret[type(of: self).CoderKeyLatitude] = String(latitude)
        ret[type(of: self).CoderKeyLongitude] = String(longitude)
        ret[type(of: self).CoderKeyLocationSourceType] = locationSourceType.rawValue
        ret[type(of: self).CoderKeyCreatedFormattedAddressLines] = formattedAddressLines
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard let jsonDict = json as? [String: Any] else {
            DDLogError("Unable to decode Location: \(String(reflecting: json))")
            return nil
        }
        guard let latitudeString = jsonDict[type(of: self).CoderKeyLatitude] as? String,
                let latitude = Double(latitudeString),
                let longitudeString = jsonDict[type(of: self).CoderKeyLongitude] as? String,
                let longitude = Double(longitudeString),
                let locationSourceTypeString = jsonDict[type(of: self).CoderKeyLocationSourceType] as? String,
                let locationSourceType = LocationSourceType(rawValue: locationSourceTypeString)
        
            else {
            DDLogError("Unable to decode Location: \(String(reflecting: json))")
            return nil
        }
        
        self.init(
            latitude: latitude,
            longitude: longitude,
            locationSourceType: locationSourceType,
            formattedAddressLines: jsonDict[type(of: self).CoderKeyCreatedFormattedAddressLines] as? [String]
        )
    }
    
}
