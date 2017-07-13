//
//  AferoAPIClient+Rules.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit

public extension AferoAPIClientProto {

    // MARK: Schedules
    
    /**
     Remove a schedule.
     - parameter accountId: The `accountId` with which the schedule is associated.
     - parameter scheduleId: The id of the schedule to delete.
     */
    
    public func deleteSchedule(_ accountId: String, scheduleId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/schedules/\(scheduleId)")
    }
    
    /// Create a new schedule, or update an existing one
    /// - parameter accountId: The account id for the schedule
    /// - parameter schedule: The schedule to create or update
    /// - returns: A `Promise<DeviceRule.Schedule>`
    
    public func createOrUpdateSchedule(_ accountId: String, schedule: DeviceRule.Schedule) -> Promise<DeviceRule.Schedule> {
        
        if let _ = schedule.scheduleId {
            return updateSchedule(accountId, schedule:  schedule)
        } else {
            return createSchedule(accountId, schedule: schedule)
        }
    }
    
    
    /// Update an existing schedule
    ///  - parameter accountId: The accountId for the schedule
    ///  - parameter schedule: The `DeviceRule.Schedule` which will be updated. `schedule.scheduleId` cannot be nil.
    /// - returns: A `Promise<DeviceRule.Schedule>`
    
    public func updateSchedule(_ accountId: String, schedule: DeviceRule.Schedule) -> Promise<DeviceRule.Schedule> {
        
        guard let scheduleId = schedule.scheduleId else {
            NSLog("No scheduleId on schedule; didn't you mean create?")
            return Promise { _, reject in reject(NSError(code: .badParameterError, localizedDescription: "No scheduleId on schedule; didn't you mean create?")) }
        }
        
        return PUT("/v1/accounts/\(accountId)/schedules/\(scheduleId)", object: schedule)
    }
    
    /// Create a new schedule
    ///  - parameter accountId: The accountId for the schedule
    ///  - parameter schedule: The `DeviceRule.Schedule` which will be updated.
    /// - returns: A `Promise<DeviceRule.Schedule>`
    /// - note: `schedule.scheduleId` must not be populated.
    
    public func createSchedule(_ accountId: String, schedule: DeviceRule.Schedule) -> Promise<DeviceRule.Schedule> {
        
        if let _ = schedule.scheduleId {
            return Promise { _, reject in reject(NSError(code: .badParameterError, localizedDescription: "ScheduleId present in schedule; didn't you mean update?")) }
        }
        
        return POST("/v1/accounts/\(accountId)/schedules", object: schedule)
    }
    
    // MARK: Rules
    
    /**
     Execute a rule.
     
     - parameter accountId: The account ID that owns the scene.
     - parameter sceneId: The ID of the scene itself.
     */
    
    public func executeRule(_ accountId: String, ruleId: String) ->Promise<[AccountAction]> {
        
        let body: [String: Any] = [
            "type": "execute_actions"
        ]
        
        return POST("/v1/accounts/\(accountId)/rules/\(ruleId)/actions", parameters: body)
    }
    
    /**
     Fetch an individual rule.
     - parameter accountId: The accountID for the rule.
     - parameter ruleId: The ruleId for the rule.
     */
    
    public func fetchRule(_ accountId: String, ruleId: String) -> Promise<DeviceRule> {
        return GET("/v1/accounts/\(accountId)/rules/\(ruleId)", expansions: ["schedule", "scene"])
    }
    
    /**
     Fetch rules, optionally for a given device, and pass them to the given handler.
     
     `deviceId` is optional; if included, only rules for that device will be retrieved.
     If excluded or `nil`, all rules for an account will be fetched.
     
     - important: If both deviceGroupId and deviceId are present, deviceId will win.
     - parameter accountId: The accountId to which the device belongs.
     - parameter deviceId: The (optional) serial number of a device. Defaults to nil.
     */
    
    public func fetchRules(_ accountId: String, deviceId: String? = nil, deviceGroupId: String? = nil) -> Promise<[DeviceRule]> {
        
        if let deviceId = deviceId {
            return GET("/v1/accounts/\(accountId)/devices/\(deviceId)/rules", expansions: ["schedule"])
        }
        
        if let deviceGroupId = deviceGroupId {
            return GET("/v1/accounts/\(accountId)/deviceGroups/\(deviceGroupId)/rules", expansions: ["schedule"])
        }
        
        return GET("/v1/accounts/\(accountId)/rules", expansions: ["schedule"])
    }
    
    /**
     Create or update a device rule. This will overwrite the rule on the service, so be careful. Also, note that while the
     rule may contain fully a constituted `Schedule` object, only the `scheduleId` and `sceneId` parameters
     will be honored in this call.
     
     - important: This method is used both for device and group rules. In order to save or update a group rule,
     `deviceGroupId` must be present either in the rule. Otherwise a device rule (possibly for multiple devices, based
     upon presence of deviceActions) will be created.
     
     - parameter rule: The DeviceRule object to create or update. The `rule` must have an `accountId` populated. If this is a `deviceGroup` rule,
     then the rule must also have `deviceGroupId` populated.
     
     - returns: A Promise<DeviceRule>
     */
    
    
    public func createOrUpdateRule(_ rule: DeviceRule) -> Promise<DeviceRule> {
        
        guard let accountId = rule.accountId else {
            let error = NSError(code: .badParameterError, localizedDescription: "Bad or missing parameters: no accountId in rule \(rule.accountId!).")
            return Promise { _, reject in reject(error) }
        }
        
        if let groupId = rule.deviceGroupId {
            
            // We're creating or updating a group rule
            
            if let ruleId = rule.ruleId {
                return PUT("/v1/accounts/\(accountId)/deviceGroups/\(groupId)/rules/\(ruleId)", object: rule)
            }
            
            return POST("/v1/accounts/\(accountId)/deviceGroups/\(groupId)/rules", object: rule)
        }
        
        // We're just creating a regular device rule.
        
        if let ruleId = rule.ruleId {
            return PUT("/v1/accounts/\(accountId)/rules/\(ruleId)", object: rule)
        }
        
        return POST("/v1/accounts/\(accountId)/rules", object: rule)
        
    }
    
    /**
     Delete a rule with the given accountId and ruleId.
     - parameter accountId: The accountId for the rule to delete.
     - parameter ruleId: The id of the rule to delete.
     */
    
    public func deleteRule(_ accountId: String, ruleId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/rules/\(ruleId)")
    }
    

}
