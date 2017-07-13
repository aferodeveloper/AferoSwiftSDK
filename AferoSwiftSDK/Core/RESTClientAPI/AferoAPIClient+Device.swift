//
//  APIClient+Device.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit
import CoreLocation

public extension AferoAPIClientProto {
    
    // Kiban Device Management
    
    /// Associate a device.
    ///
    ///  - parameter accountId: the accountId to which to associate the device.
    ///
    ///  - parameter associationId: the serial number of the device, acquired
    ///                             manually or through QR code scan.
    ///
    ///  - parameter location: the current location of the device.
    ///
    ///  - returns: A `Promise<[String: Any]>`
    
    public func associateDevice(_ accountId: String, associationId: String, location: CLLocation? = nil, verified: Bool = false) -> Promise<[String: Any]> {
        
        var deviceData : [String: Any] = [
            "associationId": associationId,
            ]
        
        if let coord = location?.coordinate {
            
            deviceData["location"] = [
                "latitude": coord.latitude,
                "longitude": coord.longitude,
                "locationSourceType": LocationSourceType.initialDeviceAssociate.rawValue,
            ]
            
        }
        
        var additionalParams = AferoAppEnvironment.scaleAndLocale
        if verified {
            additionalParams["verified"] = "true"
        }
        
        return POST("/v1/accounts/\(accountId)/devices", parameters: deviceData, expansions: ["state", "profile"], additionalParams: additionalParams)
    }
    
    /// Device Info With Extended Data
    ///
    /// - parameter accountId: The accountId to which the device belongs.
    /// - parameter deviceId: The UUID of the device.
    
    public func getExtendedDeviceInfo(_ accountId: String, deviceId: String) -> Promise<Any> {
        return GET("/v1/accounts/\(accountId)/devices/\(deviceId)", expansions: ["extendedData"])
    }
    
    /// Remove a device.
    ///
    /// - parameter accountId: The accountId to which the device belongs.
    /// - parameter deviceId: The UUID of the device to remove.
    
    public func removeDevice(_ accountId: String, deviceId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/devices/\(deviceId)")
    }
    

}
