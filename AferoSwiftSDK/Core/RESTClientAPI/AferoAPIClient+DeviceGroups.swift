//
//  APIClient+DeviceGroups.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit

public extension AferoAPIClientProto {
    
    // MARK: - Groups
    
    func fetchGroups(_ accountId: String) -> Promise<[DeviceGroup]> {
        return GET("/v1/accounts/\(accountId)/deviceGroups")
    }
    
    func fetchGroup(_ accountId: String, groupId: String) -> Promise<DeviceGroup> {
        return GET("/v1/accounts/\(accountId)/deviceGroups/\(groupId)")
    }
    
    func createOrUpdateGroup(_ group: DeviceGroup) -> Promise<DeviceGroup> {
        
        guard let _ = group.groupId else {
            return createGroup(group)
        }
        
        return updateGroup(group)
    }
    
    func createGroup(_ group: DeviceGroup) -> Promise<DeviceGroup> {
        
        if let _ = group.groupId {
            return Promise { _, reject in reject(NSError.BadParameter(localizedDescription: "Unexpected group id provided in createGroup(); did you mean to call updateGroup()?")) }
        }
        
        return POST("/v1/accounts/\(group.accountId)/deviceGroups", object: group)
    }
    
    func updateGroup(_ group: DeviceGroup) -> Promise<DeviceGroup> {
        
        guard let groupId = group.groupId else {
            return Promise { _, reject in reject(NSError.BadParameter(localizedDescription: "No group id provided in updateGroup(); did you mean to call createGroup()?")) }
        }
        
        return PUT("/v1/accounts/\(group.accountId)/deviceGroups/\(groupId)", object: group)
    }
    
    func deleteGroup(_ group: DeviceGroup) -> Promise<Void> {
        
        guard let groupId = group.groupId else {
            return Promise { _, reject in reject(NSError.BadParameter(localizedDescription: "No groupId in group to delete, so nothing to do.")) }
        }
        
        return deleteGroup(group.accountId, groupId: groupId)
    }
    
    func deleteGroup(_ accountId: String, groupId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/deviceGroups/\(groupId)")
    }
    

}
