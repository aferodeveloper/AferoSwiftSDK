//
//  DeviceActions.swift
//  Pods
//
//  Created by Justin Middleton on 9/14/17.
//
//

import Foundation
import PromiseKit
import CoreLocation

public typealias WriteAttributeOnDone = (DeviceBatchAction.Results?, Error?) -> Void
public typealias SetTimeZoneResult = (deviceId: String, tz: TimeZone, isUserOverride: Bool)
public typealias SetTimeZoneOnDone = (SetTimeZoneResult?, Error?)->Void


typealias DeviceCloudSupporting = DeviceActionable & DeviceTagCloudPersisting

protocol DeviceTagCloudPersisting: class {
    
    /// Add or update the given DeviceTag on the device identified by `deviceId` and `accountId`.
    /// - parameter tag: The tag to update. If `tag.id` is non-nil, then its existing representation in
    ///                  the cloud will be replaced the given instance. If `tag.id` is nil, then a new
    ///                  tag will be added.
    /// - parameter deviceId: The `id` of the device on which to set the tag.
    /// - parameter accountId: The `id` of the account to which the given device is associated.
    /// - returns: A `Promise` that resolves to the tag resulting from the add or update request, and throws
    ///            any errors emitted by the cloud.

    func persistTag(tag: DeviceTagPersisting.DeviceTag, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag>

    /// Delete a tag with the given `id`, on the device identified by `deviceId` and `accountId`.
    /// - parameter id: The `id` of the tag to delete.
    /// - parameter deviceId: The `id` of the device from which to remove the tag.
    /// - parameter accountId: The `id` of the account to which the given device is associated.
    /// - returns: A `Promise` which resoles to the given tag id if successfully deleted, and throws
    ///            any errors emitted by the cloud.
    /// - note: The Afero REST API returns no content upon a successful deletion; the given tag is simply
    ///         returned in the promise upon success.
    
   func purgeTag(with id: DeviceTagPersisting.DeviceTag.Id, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag.Id>
}

protocol DeviceActionable: class {
    
    func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone)
    
    /// Set the timezone for a device.
    /// - parameter timeZone: The timezone to associate with the device.
    /// - parameter isUserOverride: If true, indicates the user has explicitly set the timezone
    ///                             on this device (rather than it being inferred by location).
    ///                             If false, timeZone is the default timeZone of the phone.
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String) -> Promise<SetTimeZoneResult>
    
    /// Set the location of a device.
    /// - parameter location: The new location of the device.
    /// - parameter deviceId: The id of the device to locate.
    /// - parameter accountId: The id of the account to which the device is associated.
    /// - returns: A Promise<DeviceLocation?> that resolves to the given parameters upon success.

    func setLocation(as location: DeviceLocation?, for deviceId: String, in accountId: String) -> Promise<Void>

}

extension DeviceActionable {
    
    func setLocation(as location: CLLocation, with sourceType: DeviceLocation.SourceType, formattedAddressLines: [String]? = nil, for deviceId: String, in accountId: String) -> Promise<Void> {
        
        let location = DeviceLocation(
            location: location,
            sourceType: sourceType,
            formattedAddressLines: formattedAddressLines
        )
        
        return setLocation(as: location, for: deviceId, in: accountId)
    }
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String, onDone: @escaping SetTimeZoneOnDone) {
        setTimeZone(as: timeZone, isUserOverride: isUserOverride, for: deviceId, in: accountId).then {
            result in onDone(result, nil)
            }.catch {
                err in onDone(nil, err)
        }
    }

}

// Extend the DeviceCollection so that member devices have something to service convenience
// methods. For the most part, these will simply proxy the API client.

extension DeviceCollection: DeviceActionable {

    // Note that this is more than a simple convenience wrapper. We track overall
    // RTT for requests; this ensures that these times are recorded.
    
    public func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone) {
        
        let startTime = mach_absolute_time()
        
        apiClient.post(actions: actions, forDeviceId: deviceId, withAccountId: accountId) {
            maybeResults, maybeError in
            maybeResults?.requestIds.forEach {
                self.metricHelper.begin(requestId: $0, accountId: accountId, deviceId: deviceId, time: startTime)
            }
            onDone(maybeResults, maybeError)
        }
        
    }
    
    /// Set the timezone for a device.
    /// - parameter timeZone: The timezone to associate with the device.
    /// - parameter isUserOverride: If true, indicates the user has explicitly set the timezone
    ///                             on this device (rather than it being inferred by location).
    ///                             If false, timeZone is the default timeZone of the phone.
    
    public func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String) -> Promise<SetTimeZoneResult> {
        return apiClient.setTimeZone(as: timeZone, isUserOverride: isUserOverride, for: deviceId, in: accountId)
    }
    
    /// Set the location of a device.
    /// - parameter location: The new location of the device.
    /// - parameter deviceId: The id of the device to locate.
    /// - parameter accountId: The id of the account to which the device is associated.
    /// - returns: A Promise<DeviceLocation?> that resolves to the given parameters upon success.

    public func setLocation(as location: DeviceLocation?, for deviceId: String, in accountId: String) -> Promise<Void> {
        return apiClient.setLocation(as: location, for: deviceId, in: accountId)
    }
    
    public func setLocation(as location: CLLocation, with sourceType: DeviceLocation.SourceType, formattedAddressLines: [String]?, for deviceId: String, in accountId: String) -> Promise<Void> {
        
        let location = DeviceLocation(
            location: location,
            sourceType: sourceType,
            formattedAddressLines: formattedAddressLines
        )
        
        return apiClient.setLocation(as: location, for: deviceId, in: accountId)
    }
    
}

public extension DeviceCollection {
    
    func setLocation(as location: CLLocation, with sourceType: DeviceLocation.SourceType, formattedAddressLines: [String]? = nil, for deviceId: String) -> Promise<Void> {
        return setLocation(as: location, with: sourceType, formattedAddressLines: formattedAddressLines, for: deviceId, in: accountId)
    }
    
}

extension DeviceCollection: DeviceTagCloudPersisting {
    
    func persistTag(tag: DeviceTagPersisting.DeviceTag, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag> {
        return apiClient.persistTag(tag: tag, for: deviceId, in: accountId)
    }
    
    func purgeTag(with id: DeviceTagPersisting.DeviceTag.Id, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag.Id> {
        return apiClient.purgeTag(with: id, for: deviceId, in: accountId)
    }
    
}




