//
//  APIClient+Profiles.swift
//  iTokui
//
//  Created by Justin Middleton on 6/5/17.
//  Copyright © 2017 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import PromiseKit
import CoreLocation
import CocoaLumberjack

extension AferoAPIClientProto {

    // MARK: - Device Profiles
    
    /// Fetch all profiles for the user's account.
    ///
    /// - parameter profileId: the ID of the profile to fetch.
    /// - returns: a `Promise<[DeviceProfile]>`
    
    public func fetchProfiles(accountId: String, onDone: @escaping FetchProfilesOnDone) {
        GET("/v1/accounts/\(accountId)/deviceProfiles", parameters: AferoAppEnvironment.scaleAndLocale).then {
            (profiles: [DeviceProfile]) -> Void in
            onDone(profiles, nil)
            }.catch {
                (err: Error) -> Void in
                onDone(nil, err)
        }
    }
    
    /// Fetch an individual device's profile data, warm it up if viable, and
    /// pass the results to the given handler.
    ///
    /// - parameter accountId: the accountId for which to fetch the profile
    /// - parameter profileId: the ID of the profile to fetch.
    /// - returns: a `Promise<DeviceProfile>`
    
    public func fetchProfile(accountId: String, profileId: String, onDone: @escaping FetchProfileOnDone) {
        GET("/v1/accounts/\(accountId)/deviceProfiles/\(profileId)", parameters: AferoAppEnvironment.scaleAndLocale).then {
            (profile: DeviceProfile) -> Void in
            onDone(profile, nil)
            }.catch {
                (err: Error) -> Void in
                onDone(nil, err)
        }
    }
    
    
    /// Fetch an individual device's profile data, warm it up if viable, and
    /// pass the results to the given handler.
    ///
    /// - parameter accountId: the accountId for which to fetch the profile
    /// - parameter deviceId: the ID of device whose profile should be fetched.
    /// - returns: a `Promise<DeviceProfile>`
    
    public func fetchProfile(accountId: String, deviceId: String, onDone: @escaping FetchProfileOnDone) {
        GET("/v1/accounts/\(accountId)/devices/\(deviceId)/deviceProfile", parameters: AferoAppEnvironment.scaleAndLocale).then {
            (profile: DeviceProfile) -> Void in
            onDone(profile, nil)
            }.catch {
                (err: Error) -> Void in
                onDone(nil, err)
        }
    }

}

public extension AferoAPIClientProto {
    
    // MARK: - Device Attributes

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

