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
    
    /// Fetch a profile based upon an `associationId` and `version`, as obtained
    /// when a setup-mode device is detected by the softhub.
    ///
    /// - parameter associationId: The `associationId` obtained from the softhub.
    /// - parameter version: The `version` identifier obtained from the softhub.
    /// - returns: A `Promise<DeviceProfile>` which resolves to the indicated profile.
    
    public func fetchProfile(for associationId: String, with version: Int) -> Promise<DeviceProfile> {
        
        guard let associationId = associationId.pathAllowedURLEncodedString, !associationId.isEmpty else {
            let error = "Empty associationId."
            DDLogError(error)
            return Promise { _, reject in reject(error) }
        }
        
        return GET("/v1/devices/\(associationId)/deviceProfiles/versions/\(version)")
    }
    
    /// Fetch a profile based upon an `associationId` and `version`, as obtained
    /// when a setup-mode device is detected by the softhub.
    ///
    /// - parameter associationId: The `associationId` obtained from the softhub.
    /// - parameter version: The `version` identifier obtained from the softhub.
    /// - parameter onDone: A `(DeviceProfile, Error)->Void` to act as receiver
    ///                     for the result or error.
    
    public func fetchProfile(for associationId: String, with version: Int, onDone: @escaping FetchProfileOnDone) {
        fetchProfile(for: associationId, with: version)
            .then { profile in onDone(profile, nil) }
            .catch { err in onDone(nil, err)
        }
    }
    
    

}

