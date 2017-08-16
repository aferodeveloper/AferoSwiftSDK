//
//  DeviceCollection+PromiseKit.swift
//  Pods
//
//  Created by Justin Middleton on 8/15/17.
//
//

import Foundation
import PromiseKit
import CoreLocation

public extension DeviceCollection {
    
    /// Add a device to the device collection.
    ///
    /// - parameter associationId: The associationId for the device. Note that this is different from the deviceId.
    /// - parameter location: The location, if any, to associate with the device.
    /// - parameter isOwnershipChangeVerified: If the device is eligible for ownership change (see note), and
    ///                                        `isOwnershipChangeVerified` is `true`, then the device being scanned
    ///                                        will be disassociated from its existing account prior to being
    ///                                        associated with the new one.
    ///
    /// ## Ownership Transfer
    /// Some devices are provisioned to have their ownership transfer automatically. If upon an associate attempt
    /// with `isOwnershipTransferVerified == false` is made upon a device that's assocaiated with another account,
    /// and an error is returned with an attached URLResponse with header `transfer-verification-enabled: true`,
    /// then the call can be retried with `isOwnershipTranferVerified == true`, and the service will disassociate
    /// said device from its existing account prior to associating it with the new account.
    
    public func addDevice(with associationId: String, location: CLLocation? = nil, isOwnershipChangeVerified: Bool = false, timeZone: TimeZone = TimeZone.current, timeZoneIsUserOverride: Bool = false) -> Promise<DeviceModel> {
        
        return Promise {
            fulfill, reject in
            
            addDevice(
                with: associationId,
                location: location,
                isOwnershipChangeVerified: isOwnershipChangeVerified,
                timeZone: timeZone,
                timeZoneIsUserOverride: timeZoneIsUserOverride
            ) {
                
                maybeDevice, maybeErr in
                
                if let err = maybeErr {
                    reject(err)
                    return
                }
                
                if let device = maybeDevice {
                    fulfill(device)
                    return
                }
                
                reject("No device returned from addDevice call!")
            }
        }
        
    }
    
    /// Remove a device from the collection.
    ///
    /// This call results in a disassociate being called against the Afero service.
    /// - parameter deviceId: The id of the device to remove.
    
    public func removeDevice(with deviceId: String) -> Promise<String> {
        
        return Promise {
            fulfill, reject in

            removeDevice(with: deviceId) {
                maybeDeviceId, maybeErr in
                
                if let err = maybeErr {
                    reject(err)
                    return
                }
                
                if let deviceId = maybeDeviceId {
                    fulfill(deviceId)
                    return
                }
                
                reject("No device returned from addDevice call!")
            }

        }
    }
    
}
