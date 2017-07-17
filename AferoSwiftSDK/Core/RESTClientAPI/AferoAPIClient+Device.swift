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
    
    @available(*, deprecated, message: "Use associateDevice(with:to:locatedAt:ownershipTransferVerified) instead")
    public func associateDevice(_ accountId: String, associationId: String, location: CLLocation? = nil, verified: Bool = false) -> Promise<[String: Any]> {
        
        return associateDevice(with: associationId, to: accountId, locatedAt: location, ownershipTransferVerified: verified)
        
    }
    
    /// Associate a device to an Afero account.
    ///
    /// Associating a device to an Afero account makes the device available to members
    /// of that account, and also enables hardware and mobile software-based hubs on that
    /// account to connect to the device.
    ///
    /// A device can only be associated with one account at a time.
    ///
    ///  - parameter associationId: the serial number of the device, acquired
    ///                             manually or through QR code scan.
    ///
    ///  - parameter accountId: the accountId to which to associate the device.
    ///
    ///  - parameter location: the current location of the device.
    ///
    ///  - parameter ownershipTransferVerified: For devices for which ownership transfer
    ///                                         is allowed, this tells the API that the
    ///                                         user has verified that ownership should transfer.
    ///
    ///  - returns: A `Promise<[String: Any]>`
    
    public func associateDevice(with associationId: String, to accountId: String, locatedAt location: CLLocation? = nil, ownershipTransferVerified verified: Bool = false) -> Promise<[String: Any]> {
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
    
    @available(*, deprecated, message: "Use removeDevice(with deviceId: String, in accountId: String) instead)")
    public func getExtendedDeviceInfo(_ accountId: String, deviceId: String) -> Promise<Any> {
        return getExtendedDeviceInfo(for: deviceId, in: accountId)
    }

    /// Device Info With Extended Data
    ///
    /// - parameter deviceId: The UUID of the device.
    /// - parameter accountId: The accountId to which the device belongs.
    
    public func getExtendedDeviceInfo(for deviceId: String, in accountId: String) -> Promise<Any> {
        return GET("/v1/accounts/\(accountId)/devices/\(deviceId)", expansions: ["extendedData"])
    }

    /// Remove a device.
    ///
    /// - parameter accountId: The accountId to which the device belongs.
    /// - parameter deviceId: The UUID of the device to remove.

    @available(*, deprecated, message: "Use removeDevice(with deviceId: String, in accountId: String) instead)")
    public func removeDevice(_ accountId: String, deviceId: String) -> Promise<Void> {
        return removeDevice(with: deviceId, in: accountId)
    }

    /// Remove a device.
    ///
    /// - parameter deviceId: The UUID of the device to remove.
    /// - parameter accountId: The accountId to which the device belongs.
    
    public func removeDevice(with deviceId: String, in accountId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/devices/\(deviceId)")
    }

}
