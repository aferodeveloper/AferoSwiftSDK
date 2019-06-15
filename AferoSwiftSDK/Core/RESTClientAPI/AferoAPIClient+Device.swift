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
import CocoaLumberjack

public extension AferoAPIClientProto {
    
    /// Fetch all devices for an account. Note that this does not
    /// instantiate DeviceModels; that's done by the DeviceCollection
    /// itself.
    ///
    /// - parameter accountId: The UUID for the account for which to
    ///                        fetch devices.
    /// - parameter expansions: The expansions to fetch for a device.
    /// - returns: A `Promise<[[String: Any]]` which resolves to the
    ///            raw JSON for the device list.
    ///
    /// # Valid Expansions
    /// By default, all expansions below are included. Optionally the caller
    /// can specify a subset.
    /// * `state`: Include the device's connection state.
    /// * `tags`: Include all `deviceTags`.
    /// * `attributes`: Include all attributes.
    /// * `extendedData`: Include extended data.
    /// * `profile`: Include the device's profile.
    /// * `timezone`: Include the device's timezone state.
    
    func fetchDevices(for accountId: String, expansions: Set<String> = [
        "state", "tags", "attributes", "extendedData", "timezone",
        ]) -> Promise<[[String: Any]]> {
        
        guard let safeAccountId = accountId.pathAllowedURLEncodedString else {
            return Promise { _, reject in reject("Bad accountId '\(accountId)'.") }
        }
        
        return GET("/v1/accounts/\(safeAccountId)/devices", expansions: Array(expansions))
    }
}

public extension AferoAPIClientProto {
    
    // MARK: - Association / Disassociation -
    
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
    
    @available(*, unavailable, message: "Use associateDevice(with:to:locatedAt:ownershipTransferVerified) instead")
    func associateDevice(
        _ accountId: String,
        associationId: String,
        location: CLLocation? = nil,
        verified: Bool = false
        ) -> Promise<[String: Any]> {
        assert(false, "Use Use associateDevice(with:to:locatedAt:ownershipTransferVerified) instead")
        return Promise { _, reject in reject ("Use Use associateDevice(with:to:locatedAt:ownershipTransferVerified) instead") }
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
    ///  - parameter expansions: Expansions to include in the call. Defaults to `"state", "tags", "attributes", "extendedData", "profile", "timezone"`
    ///
    ///  - returns: A `Promise<[String: Any]>`
    
    func associateDevice(with associationId: String, to accountId: String, locatedAt location: CLLocation? = nil, ownershipTransferVerified verified: Bool = false, expansions: Set<String> = [
        "state", "tags", "attributes", "extendedData", "profile", "timezone",
        ]) -> Promise<[String: Any]> {
        
        var deviceData : [String: Any] = [
            "associationId": associationId,
        ]
        
        if let location = location {
            
            let deviceLocation = DeviceLocation(
                location: location,
                sourceType: .initialDeviceAssociate
            )
            
            deviceData["location"] = deviceLocation.JSONDict!
        }
        
        var additionalParams = AferoAppEnvironment.scaleAndLocale
        if verified {
            additionalParams["verified"] = "true"
        }
        
        return POST("/v1/accounts/\(accountId)/devices", parameters: deviceData, expansions: Array(expansions), additionalParams: additionalParams)
    }
    
    /// Device Info With Extended Data
    ///
    /// - parameter accountId: The accountId to which the device belongs.
    /// - parameter deviceId: The UUID of the device.
    
    @available(*, deprecated, message: "Use getExtendedDeviceInfo(for deviceId: String, in accountId: String) instead)")
    func getExtendedDeviceInfo(_ accountId: String, deviceId: String) -> Promise<Any> {
        return getExtendedDeviceInfo(for: deviceId, in: accountId)
    }
    
    /// Device Info With Extended Data
    ///
    /// - parameter deviceId: The UUID of the device.
    /// - parameter accountId: The accountId to which the device belongs.
    
    func getExtendedDeviceInfo(for deviceId: String, in accountId: String) -> Promise<Any> {
        return GET("/v1/accounts/\(accountId)/devices/\(deviceId)", expansions: ["extendedData"])
    }
    
    /// Remove a device.
    ///
    /// - parameter accountId: The accountId to which the device belongs.
    /// - parameter deviceId: The UUID of the device to remove.
    
    @available(*, deprecated, message: "Use removeDevice(with deviceId: String, in accountId: String) instead)")
    func removeDevice(_ accountId: String, deviceId: String) -> Promise<Void> {
        return removeDevice(with: deviceId, in: accountId)
    }
    
    /// Remove a device.
    ///
    /// - parameter deviceId: The UUID of the device to remove.
    /// - parameter accountId: The accountId to which the device belongs.
    
    func removeDevice(with deviceId: String, in accountId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/devices/\(deviceId)")
    }
    
}

// MARK: - Friendly Name

public extension AferoAPIClientProto {
    
    
    /// Set the "friendly" (display) name of a device.
    /// - parameter accountId: The account ID of the device.
    /// - parameter name: The new name of the device.
    /// - parameter deviceId: The device's `id`
    
    func setFriendlyName(_ accountId: String, name: String, forDeviceId deviceId: String) -> Promise<Void>  {
        let body: [String: Any] = [
            "friendlyName": name
        ]
        return PUT("/v1/accounts/\(accountId)/devices/\(deviceId)/friendlyName", parameters: body, expansions: nil)
    }
    
}

// MARK: - Device Location -

public extension AferoAPIClientProto {
    
    @available(*, deprecated, message: "Use getLocation(for:in:) instead.")
    func getLocation(_ accountId: String, forDeviceId deviceId: String) -> Promise<LocationModel?> {
        return getLocation(for: deviceId, in: accountId)
    }
    
    /// Get the last known location of a device.
    ///
    /// - parameter deviceId: The id of the device for which to fetch location.
    /// - parameter accountId: The id of the account to which the device is associated.
    /// - returns: A Promise<DeviceLocation?>. Resolves to `.some(DeviceLocation)` if the device has
    ///            a set location, and `.none` if not.
    
    func getLocation(for deviceId: String, in accountId: String) -> Promise<DeviceLocation?> {
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString else {
                return Promise { _, reject in reject("Unable to escape deviceId or accountId") }
        }
        
        return GET("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/location")
    }
    
    /// Set the location of a device.
    /// - parameter location: The new location of the device.
    /// - parameter deviceId: The id of the device to locate.
    /// - parameter accountId: The id of the account to which the device is associated.
    /// - returns: A Promise<DeviceLocation?> that resolves to the given parameters upon success.
    
    func setLocation(
        as location: DeviceLocation?,
        for deviceId: String,
        in accountId: String
        ) -> Promise<Void> {
        
        guard let location = location else {
            return Promise {
                _, reject in reject("Nil locations are currently unsupported.")
            }
        }
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString else {
                return Promise { _, reject in reject("Unable to escape deviceId or accountId") }
        }
        
        return PUT("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/location", object: location)
    }
    
    @available(*, unavailable, message: "Use setLocation(as:with:formattedAddressLines:for:in:) instead.")
    func setLocation(_ accountId: String, location: CLLocation, forDeviceId deviceId: String, locationSourceType: DeviceLocation.SourceType, formattedAddressLines: [String]? = nil) -> Promise<Void> {
        fatalError("Use setLocation(as:with:formattedAddressLines:for:in:) instead.")
    }
    
}

public extension AferoAPIClientProto {
    
    func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone) {
        POST("/v1/accounts/\(accountId)/devices/\(deviceId)/requests", parameters: actions.JSONDict)
            .then {
                (responses: [DeviceBatchAction.Response]) -> Void in
                let ret = DeviceBatchAction.Results(requests: actions, responses: responses)
                onDone(ret, nil)
            }.catch {
                error -> Void in onDone(nil, error)
        }
    }
    
    
    /// Set the timezone for a device.
    /// - parameter timeZone: The timezone to associate with the device.
    /// - parameter isUserOverride: If true, indicates the user has explicitly set the timezone
    ///                             on this device (rather than it being inferred by location).
    ///                             If false, timeZone is the default timeZone of the phone.
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool = false, for deviceId: String, in accountId: String) -> Promise<SetTimeZoneResult> {
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString else {
                let msg = "Unable to safely encode deviceId=`\(deviceId)' or accountId='\(accountId)'"
                DDLogError(msg, tag: TAG)
                return Promise { _, reject in reject(msg) }
        }
        
        let parameters: Parameters = [
            "userOverride": isUserOverride,
            "timezone": timeZone.identifier
        ]
        return PUT("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/timezone", parameters: parameters).then {
            () -> SetTimeZoneResult in
            return (deviceId: deviceId, tz: timeZone, isUserOverride: isUserOverride)
        }
    }
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String, onDone: @escaping SetTimeZoneOnDone) {
        setTimeZone(as: timeZone, isUserOverride: isUserOverride, for: deviceId, in: accountId).then {
            result in onDone(result, nil)
            }.catch {
                err in onDone(nil, err)
        }
    }
    
    /// Get the timezone for a device.
    /// - parameter deviceId: The id of the device for which to fetch the timezone.
    /// - parameter accountId: The accountId for the device for which to fetch the timezone.
    /// - returns: A Promise<TimeZoneState> which resolves to a timezone state.
    
    func getTimeZone(for deviceId: String, in accountId: String) -> Promise<TimeZoneState> {
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString else {
                let msg = "Unable to safely encode deviceId=`\(deviceId)' or accountId='\(accountId)'"
                DDLogError(msg, tag: TAG)
                return Promise { _, reject in reject(msg) }
        }
        
        return GET("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/timezone")
    }
}

extension AferoAPIClientProto {
    
    /// Add or update the given DeviceTag on the device identified by `deviceId` and `accountId`.
    /// - parameter tag: The tag to update. If `tag.id` is non-nil, then its existing representation in
    ///                  the cloud will be replaced the given instance. If `tag.id` is nil, then a new
    ///                  tag will be added.
    /// - parameter deviceId: The `id` of the device on which to set the tag.
    /// - parameter accountId: The `id` of the account to which the given device is associated.
    /// - returns: A `Promise` that resolves to the tag resulting from the add or update request, and throws
    ///            any errors emitted by the cloud.
    
    func persistTag(tag: DeviceTagPersisting.DeviceTag, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag> {
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString else {
                let msg = "Unable to safely encode deviceId=`\(deviceId)' or accountId='\(accountId)'"
                DDLogError(msg, tag: TAG)
                return Promise { _, reject in reject(msg) }
        }
        
        guard let _ = tag.id else {
            return POST("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/deviceTag", object: tag)
        }
        
        return PUT("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/deviceTag", object: tag)
    }
    
    /// Delete a tag with the given `id`, on the device identified by `deviceId` and `accountId`.
    /// - parameter id: The `id` of the tag to delete.
    /// - parameter deviceId: The `id` of the device from which to remove the tag.
    /// - parameter accountId: The `id` of the account to which the given device is associated.
    /// - returns: A `Promise` which resoles to the given tag id if successfully deleted, and throws
    ///            any errors emitted by the cloud.
    /// - note: The Afero REST API returns no content upon a successful deletion; the given tag is simply
    ///         returned in the promise upon success.
    
    func purgeTag(with id: DeviceTagPersisting.DeviceTag.Id, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag.Id> {
        
        guard
            let safeDeviceId = deviceId.pathAllowedURLEncodedString,
            let safeAccountId = accountId.pathAllowedURLEncodedString,
            let safeTagId = id.pathAllowedURLEncodedString else {
                let msg = "Unable to safely encode deviceId=`\(deviceId)' or accountId='\(accountId)'"
                DDLogError(msg, tag: TAG)
                return Promise { _, reject in reject(msg) }
        }
        
        return DELETE("/v1/accounts/\(safeAccountId)/devices/\(safeDeviceId)/deviceTag/\(safeTagId)")
            .then { safeTagId }
    }
    
}


