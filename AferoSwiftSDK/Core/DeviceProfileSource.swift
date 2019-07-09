//
//  DeviceProfileSource.swift
//  AferoSwiftSDK
//
//  Created by Cora Middleton on 6/19/19.
//

import Foundation
import CocoaLumberjack
import PromiseKit


// MARK: - Profile Registries

public typealias FetchProfileOnDone = (DeviceProfile?, Error?)->Void

public protocol DeviceProfileSource {
    
    /// Fetch an individual profile, by `accountId` and `profileId`.
    /// - parameter accountId: The `id` of the account whence to fetch the profile.
    /// - parameter profileId: The `id` of the profiles to fetch
    /// - parameter onDone: Result handler for the call.
    
    func fetchProfile(accountId: String, profileId: String, onDone:  @escaping FetchProfileOnDone)
    
    /// Fetch an individual profile, by `accountId` and `profileId`.
    /// - parameter accountId: The `id` of the account whence to fetch the profile.
    /// - parameter deviceId: The `id` of the profiles to fetch
    /// - parameter onDone: Result handler for the call.
    
    func fetchProfile(accountId: String, deviceId: String, onDone: @escaping FetchProfileOnDone)
    
}

public typealias FetchProfilesOnDone = ([DeviceProfile]?, Error?)->Void

public protocol DeviceAccountProfilesSource: DeviceProfileSource {
    
    /// Fetch all current profiles for a given account.
    /// - parameter accountId: The `id` of the account whence to fetch the profiles.
    /// - parameter onDone: Result handler for the call.
    
    func fetchProfiles(accountId: String, onDone: @escaping FetchProfilesOnDone)
    
}

extension DeviceAccountProfilesSource {
    
    func fetchProfiles(for accountId: String) -> Promise<[DeviceProfile]> {
        
        return Promise {
            
            fulfill, reject in
            
            fetchProfiles(accountId: accountId) {
                maybeProfiles, maybeError in
                
                if let error = maybeError {
                    reject(error)
                    return
                }
                
                guard let profiles = maybeProfiles else {
                    reject("No profiles returned.")
                    return
                }
                
                fulfill(profiles)
            }
        }
    }
}

internal class CachedDeviceAccountProfilesSource: DeviceAccountProfilesSource {
    
    fileprivate lazy var TAG: String = { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }()
    
    /// Strongly-held uncached source for profiles
    var source: DeviceAccountProfilesSource
    
    init(profileSource: DeviceAccountProfilesSource) {
        self.source = profileSource
    }
    
    fileprivate var profileCache: [String: DeviceProfile] = [:]
    
    func containsProfile(for profileId: String) -> Bool {
        return profileCache[profileId] != nil
    }
    
    func add(profile: DeviceProfile) {
        guard let profileId = profile.id else { return }
        if !containsProfile(for: profileId) {
            profileCache[profileId] = profile
        }
    }
    
    func reset() {
        profileCache.removeAll(keepingCapacity: false)
    }
    
    private var _hasVisibleDevices: Bool?
    
    fileprivate(set) var hasVisibleDevices: Bool! {
        
        get {
            if let ret = _hasVisibleDevices { return ret }
            let ret = self.profileCache.reduce(false) {
                curr, next in
                if curr == true { return true }
                return next.1.presentation() != nil
            }
            _hasVisibleDevices = ret
            return ret
        }
        
        set {
            _hasVisibleDevices = newValue
        }
    }
    
    /**
     Get a profile for the given profileId. Used the cached version if available,
     and pass the result to the given handler (if provided).
     
     - parameter profileId: The profile ID to fetch
     - parameter onDone: an optional block ``((DeviceProfile?)->Void)`` to handle the result (but why someone wouldn't pass one of these is beyond me).
     */
    
    func fetchProfile(accountId: String, profileId: String, onDone: @escaping FetchProfileOnDone) {
        
        let TAG = self.TAG
        
        if let ret = profileCache[profileId] {
            DDLogVerbose(String(format: "Found cached profile for %@", profileId), tag: TAG)
            onDone(ret, nil)
            return
        }
        
        source.fetchProfile(accountId: accountId, profileId: profileId) {
            [weak self] (maybeProfile, maybeError) in asyncMain {
                
                guard let profile = maybeProfile else {
                    
                    if let error = maybeError {
                        DDLogError("Error fetching profileId:\(profileId), accountId:\(accountId): \(error)")
                    } else {
                        DDLogWarn("Got nil profile, no error fetching profileId:\(profileId), accountId:\(accountId)")
                    }
                    
                    onDone(nil, maybeError)
                    return
                }
                
                self?.add(profile: profile)
                self?.hasVisibleDevices = nil
                
                DDLogDebug(String(format: "Added profile %@: %@", profileId, profile.debugDescription), tag: TAG)
                
                onDone(profile, nil)
            }
        }
    }
    
    func fetchProfile(accountId: String, deviceId: String, onDone: @escaping FetchProfileOnDone) {
        
        let TAG = self.TAG
        
        source.fetchProfile(accountId: accountId, deviceId: deviceId) {
            [weak self] (maybeProfile, maybeError) in asyncMain {
                
                guard
                    let profile = maybeProfile else {
                        
                        if let error = maybeError {
                            DDLogError("Error fetching deviceId:\(deviceId), accountId:\(accountId): \(error)")
                        } else {
                            DDLogError("Got nil profile, no error fetching deviceId:\(deviceId), accountId:\(accountId)")
                        }
                        
                        onDone(nil, maybeError)
                        return
                }
                
                guard let profileId = profile.id else {
                    DDLogError("Got profile with no id for deviceId:\(deviceId) accountId:\(accountId)")
                    onDone(nil, nil)
                    return
                }
                
                self?.add(profile: profile)
                self?.hasVisibleDevices = nil
                
                DDLogDebug(String(format: "Added profile %@: %@", profileId, profile.debugDescription), tag: TAG)
                
                onDone(profile, nil)
            }
        }
        
    }
    
    /**
     Fetch all profiles, and execute the optionally provided block when complete.
     This pre-seeds the cache.
     
     - parameter onDone: An optional block to fire when done.
     */
    
    func fetchProfiles(accountId: String, onDone: @escaping FetchProfilesOnDone) {
        
        let TAG = self.TAG
        
        source.fetchProfiles(accountId: accountId) {
            [weak self] maybeProfiles, maybeError in
            
            guard let profiles = maybeProfiles else {
                if let error = maybeError {
                    DDLogError("Error fetching profiles for accountId:\(accountId): \(error)", tag: TAG)
                } else {
                    DDLogError("Got nil profiles, no error fetching profiles for accountId:\(accountId)", tag: TAG)
                }
                
                onDone(nil, maybeError)
                return
            }
            
            profiles.forEach {
                profile in
                self?.add(profile: profile)
                self?.hasVisibleDevices = nil
            }
            
            DDLogInfo("Fetched profiles for accountId:\(accountId)", tag: TAG)
            onDone(profiles, nil)
        }
    }
    
}

