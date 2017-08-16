//
//  DeviceModel.swift
//  iTokui
//
//  Created by Tony Myles on 11/20/14.
//  Copyright (c) 2014-2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift


import CocoaLumberjack

// MARK: - DeviceRule/DeviceRuleAction-related Extensions

public protocol DeviceActionSource {
    var actions: [DeviceRuleAction] { get set }
}

public protocol DeviceFilterCriteriaSource: class {
    var attributeFilterOperations: [Int : DeviceFilterCriterion.Operation] { get set }
    var filterCriteria: [DeviceFilterCriterion] { get set }
}

public extension DeviceModelable where Self: DeviceActionSource {
    
    /// Representation of the device's current attribute as a `DeviceRuleAction` object.
    /// On implementors that support it, this may instigate signal emission.
    /// For example, setting `action` on a `DeviceModel` instance will result
    /// in an `DeviceEvent.AttributeUpdate(DeviceState)` event being sent.
    ///
    /// Setting this value will cause the existing attribute state
    /// to be completely replaced by an attribute state derived from all
    /// `DeviceActions` whose `deviceId` matches our own, applied in
    /// array index order.
    
    var actions: [DeviceRuleAction] {
        
        get {
            var ret: [DeviceRuleAction] = []
            if currentState.attributes.count > 0 {
                ret.append(DeviceRuleAction(deviceId: deviceId, state: currentState))
            }
            return ret
        }
        
        set {
            var state = currentState
            state.attributes = newValue
                .filter { $0.deviceId == self.deviceId }
                .flatMap { $0.attributeDict }
                .reduce([:]) {
                    (current, next) -> [Int: AttributeValue] in
                    var ret = current
                    ret[next.0] = next.1
                    return ret
            }
            currentState = state
        }
    }
    
}

public extension DeviceModelable where Self: DeviceFilterCriteriaSource {
    
    public func setOperation(_ operation: DeviceFilterCriterion.Operation?, forAttributeId attributeId: Int) {
        attributeFilterOperations[attributeId] = operation
        eventSink.send(value: .stateUpdate(newState: currentState))
    }
    
    public func operationForAttributeId(_ attributeId: Int) -> DeviceFilterCriterion.Operation? {
        return attributeFilterOperations[attributeId]
    }
    
    /// If `filterCriterion.deviceId` == `self.id`, set (or **optionally** overlay) this modelable's state to that indicated
    /// by the given `DeviceFilterCriterion`. If `filterCriterion.deviceId` ≠ `self.id`, then do nothing.
    ///
    /// - parameter filterCriterion: The filterCriterion from which to pull attribute state
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to false**.
    ///
    /// - Important: By default, this does NOT overlay the current state
    
    public func update(_ filterCriterion: DeviceFilterCriterion, accumulative: Bool = false) {
        
        guard filterCriterion.deviceId == deviceId else { return }
        
        guard let stringValue = filterCriterion.attribute.value.stringValue else {
            DDLogInfo("Unable to determine stringValue for \(filterCriterion.attribute)")
            return
        }
        
        let attributes: [Int: String] = [
            filterCriterion.attribute.id: stringValue
        ]
        attributeFilterOperations[filterCriterion.attribute.id] = filterCriterion.operation
        update(attributes, accumulative: accumulative)
    }
    
    /// This device's state as an array of filterCriteria, with `trigger` and `operation`
    /// values set to their defaults for `DeviceFilterCriterion`.
    ///
    /// - Important: Note that `trigger` and `operation`
    /// values are replaced with their respective defaults when round-tripping, so this is
    /// not full-fidelity storage for filter criteria.
    /// - Important: Setting this will **not** overlay the current state, but rather will successively
    ///              replace it.
    
    public var filterCriteria: [DeviceFilterCriterion] {

        get {
            return DeviceFilterCriterion.CriteriaFromState(
                currentState,
                deviceId: deviceId,
                trigger: true,
                attributeFilterOperations: attributeFilterOperations
            )
        }
        
        set {
            attributeFilterOperations = [:]
            newValue.forEach {
                update($0, accumulative: true)
            }
        }
    }

}

extension RecordingDeviceModel: DeviceActionSource { }
extension DeviceModel: DeviceActionSource { }

public extension Array where Element: DeviceModelable & DeviceFilterCriteriaSource {
    
    /// Produce a merged array of filter criteria from this array.
    
    public var filterCriteria: [DeviceFilterCriterion] {
        
        get {
            return self
                .filter { $0.isAvailable }
                .reduce(Set<DeviceFilterCriterion>()) {
                    (current: Set<DeviceFilterCriterion>, next: Element) -> Set<DeviceFilterCriterion> in
                    return current.union(next.filterCriteria)
                }
                .filter { _ in true }
        }
    }
}

public extension Array where Element: DeviceModelable & DeviceActionSource {
    
    /// Get or Distribute `DeviceRuleAction`s across this collection's elements.

    public var actions: [DeviceRuleAction] {
        
        get {
            
            // The trailing .filter() hack below is due to an overload in the Swift 1.2 (XC7b3)
            // library which ambiguously resolves initializer overloads when initializing
            // Arrays with Sets.
            
            return self
                .filter { $0.isAvailable && $0.actions.count > 0 }
                .reduce(Set<DeviceRuleAction>()) {
                    (current: Set<DeviceRuleAction>, next: Element) -> Set<DeviceRuleAction> in
                    return current.union(next.actions)
                }
                .filter { _ in true }
            
        }

    }
    
}

public extension Dictionary where Value: DeviceModelable & DeviceActionSource {
    
    /// For `Dictionary`s whose `Value`s are `DeviceModelableRuleSource`s, produce an aggregate
    /// rule by continuously overlaying constituents' `deviceRules` properties,
    /// merging `actions` along the way.
    
    public var deviceRule: DeviceRule {
        get { return DeviceRule(actions: actions) }
    }
    
    /// Get or Distribute `DeviceRuleAction`s across this collection's elements.
    
    public var actions: [DeviceRuleAction] {
        
        get {
            // The trailing .filter() hack below is due to an overload in the Swift 2 (XC7b3)
            // library which ambiguously resolves initializer overloads when initializing
            // Arrays with Sets.
            
            return self.values
                .filter { $0.isAvailable && $0.actions.count > 0 }
                .reduce(Set<DeviceRuleAction>()) {
                    (current: Set<DeviceRuleAction>, next: Value) -> Set<DeviceRuleAction> in
                    return current.union(next.actions)
                }
                .filter { _ in true }
        }
        
    }
    
}

// MARK: DeviceGroupMembers

/**
A member object in a list of devices in a DeviceGroup.
*/

public struct DeviceGroupMember: Hashable, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "<DeviceSetMember> deviceId: \(deviceId) clientMetadata: \(clientMetadata)"
    }
    
    public var hashValue: Int {
        return deviceId.hashValue
    }
    
    public var deviceId: String
    public var clientMetadata: [String: Any] = [:]
    
    public init(deviceId: String, clientMetadata: [String: Any] = [:]) {
        self.deviceId = deviceId
        self.clientMetadata = clientMetadata
    }
}

public func ==(lhs: DeviceGroupMember, rhs: DeviceGroupMember) -> Bool {
    return lhs.deviceId == rhs.deviceId
}

extension DeviceGroupMember: AferoJSONCoding {
    
    static let CoderKeyDeviceId = "deviceId"
    static let CoderKeyClientMetadata = "clientMetadata"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyDeviceId: deviceId,
            type(of: self).CoderKeyClientMetadata: clientMetadata,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard
            let jsonDict = json as? [String: Any],
            let deviceId = jsonDict[type(of: self).CoderKeyDeviceId] as? String else {
                DDLogInfo("Unable to decode DeviceGroup.DeviceSetMember: \(String(describing: json))")
                return nil
        }
        
        let clientMetadata = jsonDict[type(of: self).CoderKeyClientMetadata] as? [String: Any] ?? [:]
        
        self.init(deviceId: deviceId, clientMetadata: clientMetadata)
    }
}

public extension DeviceRule {
    
    /// Instantiate a `DeviceRule` using an object which provides
    /// a device interface (`DeviceModelable`)
    
    public init(ruleId: String? = nil, actionable: DeviceModelable & DeviceActionSource, deviceGroupId: String? = nil, label: String? = nil, filterCriteria: [DeviceFilterCriterion]? = nil, enabled: Bool = true, userNotifications: [UserNotificationAssociation] = [], accountNotification: AccountNotification? = nil, notifies: Bool? = nil) {
        
        let localAccountNotification = (accountNotification ?? ((notifies ?? true)  ? AccountNotification.standard : nil))
            
        self.init(
            actions: actionable.actions,
            filterCriteria: filterCriteria,
            enabled: enabled,
            accountId: actionable.accountId,
            ruleId: ruleId,
            deviceGroupId:  deviceGroupId,
            label: label,
            userNotifications: userNotifications,
            accountNotification: localAccountNotification
        )
    }
    
    /// Instantiate a `DeviceRule` using an array of `DeviceActionModelable` `DeviceActionSource`s.
    
    public init(ruleId: String? = nil, accountId: String? = nil, scheduleId: String? = nil, schedule: DeviceRule.Schedule? = nil, actionables: [DeviceModelable & DeviceActionSource], filterCriteriaSources: [DeviceModelable & DeviceFilterCriteriaSource], enabled: Bool = true, deviceGroupId: String? = nil, label: String? = nil, userNotifications: [UserNotificationAssociation] = [], accountNotification: AccountNotification? = nil, notifies: Bool? = nil) {
        
        let filterCriteria: [DeviceFilterCriterion]? = filterCriteriaSources.count > 0 ? filterCriteriaSources.flatMap { $0.filterCriteria } : nil
        
        self.init(
            scheduleId: scheduleId,
            schedule: schedule,
            actions: actionables.flatMap { $0.actions },
            filterCriteria: filterCriteria,
            enabled: enabled,
            accountId: accountId ?? actionables.first?.accountId,
            ruleId: ruleId,
            deviceGroupId:  deviceGroupId,
            label: label,
            userNotifications: userNotifications,
            accountNotification: (accountNotification ?? ((notifies ?? true)  ? AccountNotification.standard : nil))
        )
    }
    
}

public extension DeviceRuleAction {
    
    public init(deviceId: String, state: DeviceState, durationSeconds: Int? = nil) {
        let attributeInstances = state.attributes.map {
            return AttributeInstance(id: $0, value: $1)
        }
        self.init(deviceId: deviceId, attributes: attributeInstances, durationSeconds: durationSeconds)
    }
    
    public var attributeDict: [Int: AttributeValue] {
        return Dictionary(attributes.map { return ($0.id, $0.value) }.makeIterator())
    }
}

// MARK: - DeviceGroups

public struct DeviceGroup: Equatable, CustomDebugStringConvertible {

    public var debugDescription: String {
        return "<Group> accountId: \(accountId) name: \(String(describing: name)) groupId: \(String(reflecting: groupId)) created: \(String(reflecting: created)) clientMetadata: \(clientMetadata)"
    }
    
    public var accountId: String
    
    public var devices: [String: DeviceGroupMember] = [:]
    public var name: String? = nil
    public var groupId: String? = nil
    public var created: Date? = nil
    
    public var clientMetadata: [String: Any] = [:]
    
    public init(accountId: String, groupId: String? = nil, name: String? = nil, devices: [String: DeviceGroupMember] = [:], created: Date? = nil, clientMetadata: [String: Any] = [:]) {
        self.accountId = accountId
        self.groupId = groupId
        self.name = name
        self.devices = devices
        self.created = created
        self.clientMetadata = clientMetadata
    }

    public init(accountId: String, groupId: String? = nil, name: String? = nil, deviceList: [DeviceGroupMember], created: Date? = nil, clientMetadata: [String: Any] = [:]) {
        
        var devices: [String: DeviceGroupMember] = [:]
        for member in deviceList {
            devices[member.deviceId] = member
        }
        self.init(accountId: accountId, groupId: groupId, name: name, devices: devices, created: created, clientMetadata: clientMetadata)
    }
    
    public subscript(deviceId: String?) -> DeviceGroupMember? {

        get {
            guard let deviceId = deviceId else {
                return nil
            }
            return devices[deviceId]
        }
        
        set {
            guard let deviceId = deviceId else {
                return
            }
            devices[deviceId] = newValue
        }
    }
    
    public var isEmpty: Bool { return devices.isEmpty }
    
    public var count: Int { return devices.count }
    
    public func contains(_ deviceId: String?) -> Bool {
        return self[deviceId] != nil
    }
    
    public mutating func removeMember(_ deviceId: String?) {
        self[deviceId] = nil
    }
    
    public mutating func addMember(_ member: DeviceGroupMember) {
        self[member.deviceId] = member
    }
    
    public mutating func addMember(_ deviceId: String, clientMetadata: [String: Any] = [:]) {
        self.addMember(DeviceGroupMember(deviceId: deviceId, clientMetadata: clientMetadata))
    }
    
}

extension DeviceGroup {
    
    static let MetadataKeyIconIdentifier = "iconId"
    
    public var iconIdentifier: String? {

        get {
            return clientMetadata[type(of: self).MetadataKeyIconIdentifier] as? String
        }
        
        set {
            clientMetadata[type(of: self).MetadataKeyIconIdentifier] = newValue
        }
    }
}

public func ==(lhs: DeviceGroup, rhs: DeviceGroup) -> Bool {
    return lhs.accountId == rhs.accountId
        && lhs.groupId == rhs.groupId
        && lhs.name == rhs.name
        && lhs.devices == rhs.devices
        && lhs.created == rhs.created
}

extension DeviceGroup: AferoJSONCoding {
    
    static let CoderKeyAccountId = "accountId"
    static let CoderKeyName = "label"
    static let CoderKeyGroupId = "deviceGroupId"
    static let CoderKeyDevices = "devices"
    static let CoderKeyCreatedTimestamp = "createdTimestamp"
    static let CoderKeyClientMetadata = "clientMetadata"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyAccountId: accountId,
            type(of: self).CoderKeyDevices: devices.values.map { $0.JSONDict! },
            type(of: self).CoderKeyClientMetadata: clientMetadata,
        ]
        
        if let groupId = groupId {
            ret[type(of: self).CoderKeyGroupId] = groupId
        }
        
        if let name = name {
            ret[type(of: self).CoderKeyName] = name
        }
        
        if let created = created {
            ret[type(of: self).CoderKeyCreatedTimestamp] = created.millisSince1970
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard
            let jsonDict = json as? [String: Any],
            let accountId = jsonDict[type(of: self).CoderKeyAccountId] as? String,
            let deviceList: [DeviceGroupMember] = |<(jsonDict[type(of: self).CoderKeyDevices] as? [AferoJSONCodedType]) else {
                DDLogInfo("Unable to decode DeviceGroup (missing accountId or deviceList): \(String(describing: json))")
                return nil
        }
        
        let groupId = jsonDict[type(of: self).CoderKeyGroupId] as? String
        let name = jsonDict[type(of: self).CoderKeyName] as? String
        let createdTimestamp = jsonDict[type(of: self).CoderKeyCreatedTimestamp] as? NSNumber
        let clientMetadata: [String: Any] = (jsonDict[type(of: self).CoderKeyClientMetadata] as? [String: Any]) ?? [:]
        
        self.init(accountId: accountId, groupId: groupId, name: name, deviceList: deviceList, created: createdTimestamp?.dateValueFromMillisSince1970, clientMetadata: clientMetadata)
    }
}

// MARK: - AccountActions

public struct AccountAction {
    
    public var requestId: Int
    public var type: String
    public var timestamp: Date? = nil
    public var sender: String? = nil
    public var source: AccountActionSource? = nil
    
    public init(requestId: Int, type: String, timestamp: Date? = nil, sender: String? = nil, source: AccountActionSource? = nil) {
        self.requestId = requestId
        self.type = type
        self.timestamp = timestamp
        self.sender = sender
        self.source = source
    }
    
    public struct AccountActionSource {
        var type: String
        
        init(type: String) {
            self.type = type
        }
    }
    
}

extension AccountAction: AferoJSONCoding {

    static let CoderKeyRequestId = "requestId"
    static let CoderKeyType = "type"
    static let CoderKeyTimestamp = "timestampMs"
    static let CoderKeySender = "sender"
    static let CoderKeySource = "source"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyRequestId: requestId,
            type(of: self).CoderKeyType: type,
        ]
        
        if let timestamp = timestamp {
            ret[type(of: self).CoderKeyTimestamp] = timestamp.millisSince1970
        }
        
        if let sender = sender {
            ret[type(of: self).CoderKeySender] = sender
        }
        
        if let source = source {
            ret[type(of: self).CoderKeySender] = source.JSONDict!
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard
            let jsonDict = json as? [String: Any],
            let requestId = jsonDict[type(of: self).CoderKeyRequestId] as? Int,
            let type = jsonDict[type(of: self).CoderKeyType] as? String else {
                DDLogInfo("Unable to decode AccountAction: \(String(reflecting: json))")
                return nil
        }
        
        var source: AccountActionSource? = nil
        
        if let sourceJson = jsonDict[type(of: self).CoderKeySource] {
            guard let sourceObj: AccountActionSource = |<sourceJson else {
                DDLogInfo("Invalid source for AccountAction: \(String(reflecting: json))")
                return nil
            }
            source = sourceObj
        }
        
        var timestamp: Date? = nil
        
        if let timestampMs = jsonDict[type(of: self).CoderKeyTimestamp] as? NSNumber {
            timestamp = Date.dateWithMillisSince1970(timestampMs)
        }
        
        let sender = jsonDict[type(of: self).CoderKeySender] as? String
        
        self.init(requestId: requestId, type: type, timestamp: timestamp as Date?, sender: sender, source: source)
    }

}

extension AccountAction.AccountActionSource: AferoJSONCoding {
    
    static let CoderKeyType = "type"
    
    public var JSONDict: AferoJSONCodedType? {
        return [type(of: self).CoderKeyType: type]
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard
            let jsonDict = json as? [String: Any],
            let type = jsonDict[type(of: self).CoderKeyType] as? String else {
            DDLogInfo("Unable to decode accountActionSource: \(String(reflecting: json))")
            return nil
        }
        
        self.init(type: type)
    }
}

// MARK: - UserNotifications

public struct UserNotificationAssociation {
    public var userId: String
    public var notificationId: String
    
    public init(userId: String, notificationId: String) {
        self.userId = userId
        self.notificationId = notificationId
    }
    
}

extension UserNotificationAssociation: AferoJSONCoding {
    
    static let CoderKeyUserId = "userId"
    static let CoderKeyNotificationId = "notificationId"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyUserId: userId,
            type(of: self).CoderKeyNotificationId: notificationId,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard
            let jsonDict = json as? [String: Any],
            let userId = jsonDict[type(of: self).CoderKeyUserId] as? String,
            let notificationId = jsonDict[type(of: self).CoderKeyNotificationId] as? String else {
                DDLogInfo("Unable to decode UserNoticationAssociation: \(String(reflecting: json))")
                return nil
        }
        
        self.init(userId: userId, notificationId: notificationId)
    }
    
}

// MARK: - DeviceRuleAction

public func ==(lhs: DeviceRuleAction, rhs: DeviceRuleAction) -> Bool {
    return (lhs.deviceId == rhs.deviceId)
        && (lhs.attributes == rhs.attributes)
        && (lhs.durationSeconds == rhs.durationSeconds)
}

public struct DeviceRuleAction: Hashable, CustomDebugStringConvertible {
    
    // <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        return "<DeviceRuleAction> deviceId: \(self.deviceId) duration: \(String(describing: durationSeconds)) attributes: \(attributes.debugDescription)"
    }
    
    // <Hashable>
    
    public var hashValue: Int {
        return deviceId.hashValue
            ^ attributes.reduce(0) { $0 ^ $1.hashValue }
            ^ (durationSeconds?.hashValue ?? 0)
    }
    
    public var deviceId: String
    public var attributes: [AttributeInstance] = []
    public var durationSeconds: Int?
    
    public init(deviceId: String, durationSeconds: Int? = nil) {
        self.init(deviceId: deviceId, attributes: [], durationSeconds: durationSeconds)
    }
    
    public init(
        deviceId: String,
        attributes: [AttributeInstance],
        durationSeconds: Int? = nil
        ) {
            self.deviceId = deviceId
            self.attributes = attributes
            self.durationSeconds = durationSeconds
    }
    
}

extension DeviceRuleAction: AferoJSONCoding {
    
    static let CoderKeyDeviceId = "deviceId"
    static let CoderKeyAttributes = "attributes"
    static let CoderKeyDurationSeconds = "durationSeconds"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: AferoJSONObject = [
            type(of: self).CoderKeyDeviceId: self.deviceId,
            type(of: self).CoderKeyAttributes: self.attributes.map() { $0.JSONDict! },
        ]
        
        if let durationSeconds = durationSeconds {
            ret[type(of: self).CoderKeyDurationSeconds] = durationSeconds
        }
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? AferoJSONObject,
            let deviceId = json[type(of: self).CoderKeyDeviceId] as? String,
            let attributesJson = json[type(of: self).CoderKeyAttributes] as? [AnyObject],
            let attributes: [AttributeInstance] = |<attributesJson {
                
                let durationSeconds = json[type(of: self).CoderKeyDurationSeconds] as? Int
                self.init(deviceId: deviceId, attributes: attributes, durationSeconds: durationSeconds)
                
        } else {
            DDLogInfo("Invalid Action JSON: \(String(reflecting: json))")
            return nil
        }
    }
    
}

// MARK: - DeviceFilterCriterion

public func ==(lhs: DeviceFilterCriterion, rhs: DeviceFilterCriterion) -> Bool {
    return (lhs.attribute == rhs.attribute)
        && (lhs.deviceId == rhs.deviceId)
        && (lhs.operation == rhs.operation)
        && (lhs.trigger == rhs.trigger)
}

public struct DeviceFilterCriterion: Hashable, CustomDebugStringConvertible {
    
    public enum Operation: String {
        
        case equals = "EQUALS"
        case greaterThan = "GREATER_THAN"
        case lessThan = "LESS_THAN"

    }
    
    // <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        return "<FilterCriterion> deviceId: \(deviceId) value: \(attribute.debugDescription) operation: \(operation) trigger: \(trigger)"
    }
    
    // <Hashable>
    
    public var hashValue: Int {
        return attribute.hashValue
            ^ operation.hashValue
            ^ deviceId.hashValue
            ^ trigger.hashValue
    }
    
    public var attribute: AttributeInstance
    public var operation: Operation
    public var deviceId: String
    public var trigger: Bool = false
    
    public init(attribute: AttributeInstance, operation: Operation, deviceId: String, trigger: Bool = false) {
        self.attribute = attribute
        self.operation = operation
        self.deviceId = deviceId
        self.trigger = trigger
    }
    
}

extension DeviceFilterCriterion {
    
    static func CriteriaFromState(_ state: DeviceState, deviceId: String, trigger: Bool = false, attributeFilterOperations: [Int: Operation] = [:], defaultOperation: Operation = .equals) -> [DeviceFilterCriterion] {
        return state.attributeInstances.map {
            return DeviceFilterCriterion(
                attribute: $0,
                operation: attributeFilterOperations[$0.id] ?? defaultOperation,
                deviceId: deviceId,
                trigger: trigger
            )
        }
    }
}

extension DeviceFilterCriterion: AferoJSONCoding {
    
    static let CoderKeyAttribute = "attribute"
    static let CoderKeyTrigger = "trigger"
    static let CoderKeyOperation = "operation"
    static let CoderKeyDeviceId = "deviceId"
    
    public var JSONDict: AferoJSONCodedType? {
        
        return [
            type(of: self).CoderKeyAttribute: attribute.JSONDict!,
            type(of: self).CoderKeyTrigger: trigger,
            type(of: self).CoderKeyDeviceId: deviceId,
            type(of: self).CoderKeyOperation: operation.rawValue
        ]
        
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard
            let jsonDict = json as? AferoJSONObject,
            let attributeJson = jsonDict[type(of: self).CoderKeyAttribute] as? [String: Any],
            let deviceId = jsonDict[type(of: self).CoderKeyDeviceId] as? String,
            let attribute = AttributeInstance(json: attributeJson) else {
                DDLogInfo("Invalid FilterCriterion JSON: \(String(reflecting: json))")
                return nil
        }
        
        var operation: Operation? = nil
        
        if let operationJson = jsonDict[type(of: self).CoderKeyOperation] as? String {
            operation = Operation(rawValue: operationJson)
        }
        
        let trigger = jsonDict[type(of: self).CoderKeyTrigger] as? Bool ?? false
        
        self.init(attribute: attribute, operation: operation ?? .equals, deviceId: deviceId, trigger: trigger)
        
    }
    
}

// MARK: - DeviceRule

public enum AccountNotification {
    
    case standard
    case custom(id: String)
    
    var id: String? {
        switch self {
        case .standard: return "85c796b4-c08c-4bcd-bb9f-2f5fa850e5f9"
        case .custom(let id): return id
        }
    }
    
    init(id: String) {
        if id == AccountNotification.standard.id { self = .standard; return }
        self = .custom(id: id)
    }
    
}

extension AccountNotification: AferoJSONCoding {
    
    public var JSONDict: AferoJSONCodedType? {
        return self.id
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard let id = json as? String else {
            return nil
        }
        
        self.init(id: id)
    }
}

public struct DeviceRule: Equatable, CustomDebugStringConvertible {

    public var debugDescription: String {
        let actionsString = actions.map { $0.debugDescription }.joined(separator: "\n    ")
        let filtersString = filterCriteria?.map { $0.debugDescription }.joined(separator: "\n    ") ?? "<empty>"
        return "<DeviceRule> label: \(String(reflecting: label)) id: \(String(reflecting: ruleId)) enabled: \(enabled) accountNotification: \(String(reflecting: accountNotification))\n    \(schedule.debugDescription) \nActions:\n    \(actionsString) \nFilterCriteria:\n    \(filtersString)"
    }
    
    public var ruleId: String? = nil
    public var accountId: String? = nil
    public var deviceGroupId: String? = nil
    
    public var accountNotification: AccountNotification? = nil

    public var enabled: Bool = true
    public var filterCriteria: [DeviceFilterCriterion]?
    public var label: String? = nil
    public var created: Date? = nil

    // MARK: Schedules
    
    fileprivate var scheduleIdInternal: String?
    public var scheduleId: String? {
        get {
            return schedule?.scheduleId ?? scheduleIdInternal
        }
        set {
            if let _ = schedule {
                schedule?.scheduleId = newValue
            }
            scheduleIdInternal = newValue
        }
    }
    
    public var schedule: Schedule? = nil
    
    // MARK: Actions
    
    public var actions: [DeviceRuleAction] = []
    
    // MARK: Notifications
    
    public var userNotifications: [UserNotificationAssociation] = []
    
    public init(action: DeviceRuleAction) {
        self.init(schedule: Schedule(), actions: [action], filterCriteria: [], enabled: true)
    }
    
    public init(deviceId: String, attributeId: Int, attributeValue: Bool) {
        let attributeValue = AttributeInstance(id: attributeId, bytes: attributeValue.bytes)
        self.init(action: DeviceRuleAction(deviceId: deviceId, attributes: [attributeValue], durationSeconds: nil))
    }
    
    public init(scheduleId: String? = nil, schedule: Schedule? = nil, actions: [DeviceRuleAction] = [], filterCriteria: [DeviceFilterCriterion]? = nil, enabled: Bool = true, accountId: String? = nil, ruleId: String? = nil, deviceGroupId: String? = nil, label: String? = nil, userNotifications: [UserNotificationAssociation] = [], accountNotification: AccountNotification? = nil) {

        self.scheduleIdInternal = scheduleId
        self.schedule = schedule
        
        self.actions = actions
        self.enabled = enabled
        self.accountId = accountId
        self.ruleId = ruleId
        self.filterCriteria = filterCriteria
        self.label = label
        
        self.deviceGroupId = deviceGroupId
        self.userNotifications = userNotifications
        
        self.accountNotification = accountNotification
    }
    
    
    public struct Schedule: Equatable, CustomDebugStringConvertible {
        
        public var debugDescription: String {
            let daysOfWeek = dayOfWeek.map { $0.rawValue }.joined(separator: ", ")
            return "<Schedule> id: \(String(describing: scheduleId)) time: \(time) daysOfWeek: \(daysOfWeek)"
        }
        
        public var triggeredRuleId: String?
        public var scheduleId: String?
        public var dayOfWeek: Set<DateTypes.DayOfWeek>
        public var time: DateTypes.Time
        
        /// Default constructor; initializes schedule with all seven days of the week,
        /// current time, and current timezone.
        
        public init() {
            self.init(
                dayOfWeek: Set([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]),
                time: DateTypes.Time())
        }
        
        public init(dayOfWeek: Set<DateTypes.DayOfWeek>, time: DateTypes.Time, scheduleId: String? = nil, triggeredRuleId: String? = nil) {
            self.dayOfWeek = dayOfWeek
            self.time = time
            self.scheduleId = scheduleId
            self.triggeredRuleId = triggeredRuleId
        }
        
    }
    
}

public extension DeviceRule {
    
    /// Overall characteristics of this rule. Represented as an `OptionSetType` because
    /// it's quite possible for a rule to have both filterCriteria and a schedule, for example,
    /// and all rules can be run on demand.
    
    public var flags: Flags {
        
        var ret: Flags = .OnDemand
        
        if let _ = scheduleId {
            ret.formUnion(.Scheduled)
        }
        
        if (filterCriteria?.count ?? 0) > 0 {
            ret.formUnion(.Linked)
        }
        
//        if false {
//            // TODO: add Sunrise / Sunset
//            ret.unionInPlace(.SunriseSunset)
//        }
        
        return ret

    }
    
    /// For determining what kind of editor to use, what kind of
    /// icon to display, etc, this gives us the single "most impotant" `Flags` value
    
    public var primaryFlag: Flags {
        
        let flags = self.flags
        
        if flags.contains(.SunriseSunset) {
            return .SunriseSunset
        }
        
        if flags.contains(.Linked) {
            return .Linked
        }
        
        if flags.contains(.Scheduled) {
            return .Scheduled
        }
        
        return .OnDemand
    }
    
    /// DeviceRule flags (scheduled, ondemand, etc)
    
    public struct Flags: OptionSet {
        
        // Yes, this is what a bitfield looks like in Swift :(
        
        public typealias RawValue = UInt
        
        fileprivate var value: RawValue = 0
        
        // MARK: RawRepresentable
        
        public init(rawValue: RawValue) {
            self.value = rawValue
        }
        
        static func fromRaw(_ raw: UInt) -> Flags {
            return self.init(rawValue: raw)
        }
        
        public var rawValue: RawValue { return self.value }
        
        // MARK: Actual values
        
        public static func fromMask(_ raw: UInt) -> Flags {
            return self.init(rawValue: raw)
        }
        
        /// Rule can be run on demand (which all of them can be)
        public static var OnDemand: Flags      { return fromRaw(0x00) }
        
        /// Rule is scheduled.
        public static var Scheduled: Flags     { return fromRaw(0x01 << 0) }
        
        /// Rule is linked to a device.
        public static var Linked: Flags        { return fromRaw(0x01 << 1) }
        
        /// Rule runs at sunrise or sunset
        public static var SunriseSunset: Flags { return fromRaw(0x02 << 2) }
        
    }
}

public func ==<T>(lhs: Array<T>?, rhs: Array<T>?) -> Bool where T: Equatable {

    if let lhs = lhs, let rhs = rhs {
        return lhs == rhs
    }
    
    guard let _ = lhs, let  _ = rhs else {
        return false
    }
    
    return true

}

public func ==(lhs: DeviceRule, rhs: DeviceRule) -> Bool {
    
    return (lhs.enabled == rhs.enabled)
        && (lhs.ruleId == rhs.ruleId)
        && (lhs.schedule == rhs.schedule)
        && (lhs.filterCriteria == rhs.filterCriteria)
        && (lhs.actions == rhs.actions)
}

public func ==(lhs: DeviceRule.Schedule, rhs: DeviceRule.Schedule) -> Bool {
    return  (lhs.dayOfWeek == rhs.dayOfWeek)
        && (lhs.scheduleId == rhs.scheduleId)
        && (lhs.time == rhs.time)
}

extension DeviceRule: Comparable { }

public func <(lhs: DeviceRule, rhs: DeviceRule) -> Bool {
    
    if let llab = lhs.label, let rlab = rhs.label {
        if llab != rlab { return llab < rlab }
    }
    
    if lhs.primaryFlag == rhs.primaryFlag {
        if lhs.primaryFlag == .Scheduled {
            if let ltime = lhs.schedule?.time, let rtime = rhs.schedule?.time {
                return ltime < rtime
            }
        }
        
        if let lrid = lhs.ruleId, let rrid = rhs.ruleId {
            return lrid < rrid
        }
    }
    
    return lhs.primaryFlag.rawValue < rhs.primaryFlag.rawValue
    
}

// MARK: - AferoJSONCoding

extension DeviceRule: AferoJSONCoding {
    
    static let CoderKeyRuleId = "ruleId"
    static let CoderKeyScheduleId = "scheduleId"
    static let CoderKeySchedule = "schedule"
    
    static let CoderKeySceneId = "sceneId"
    static let CoderKeyScene = "scene"
    
    static let CoderKeyDeviceActions = "deviceActions"
    static let CoderKeyEnabled = "enabled"
    static let CoderKeyFilterCriteria = "deviceFilterCriteria"
    static let CoderKeyAccountId = "accountId"
    static let CoderKeyLabel = "label"
    
    static let CoderKeyDeviceGroupId = "deviceGroupId"
    static let CoderKeyUserNotifications = "userNotifications"
    static let CoderKeyAccountNotificationId = "accountNotificationId"
    
    public init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogInfo("Invalid DeviceRule JSON: \(String(reflecting: json))")
            return nil
        }
        
        let scheduleId = jsonDict[type(of: self).CoderKeyScheduleId] as? String
        let schedule: Schedule? = |<jsonDict[type(of: self).CoderKeySchedule]
        
        let accountId = jsonDict[type(of: self).CoderKeyAccountId] as? String
        let ruleId = jsonDict[type(of: self).CoderKeyRuleId] as? String
        let enabled = jsonDict[type(of: self).CoderKeyEnabled] as? Bool ?? false

        let filterJson = jsonDict[type(of: self).CoderKeyFilterCriteria] as? [AnyObject]
        let filterCriteria: [DeviceFilterCriterion]? = |<filterJson

        let actionsJson = jsonDict[type(of: self).CoderKeyDeviceActions] as? [AnyObject]
        let actions: [DeviceRuleAction] = |<actionsJson ?? []
        
        let label: String? = jsonDict[type(of: self).CoderKeyLabel] as? String
        
        let deviceGroupId: String? = jsonDict[type(of: self).CoderKeyDeviceGroupId] as? String
        let userNotifications: [UserNotificationAssociation] = |<(jsonDict[type(of: self).CoderKeyUserNotifications] as? [AnyObject]) ?? []
        
        let accountNotification: AccountNotification? = |<(jsonDict[type(of: self).CoderKeyAccountNotificationId] as? NSString)

        self.init(
            scheduleId: scheduleId,
            schedule: schedule,
            actions: actions,
            filterCriteria: filterCriteria,
            enabled: enabled,
            accountId: accountId,
            ruleId: ruleId,
            deviceGroupId: deviceGroupId,
            label: label,
            userNotifications: userNotifications,
            accountNotification: accountNotification
        )
        
    }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: AferoJSONObject = [
            type(of: self).CoderKeyEnabled: enabled,
            type(of: self).CoderKeyDeviceActions: actions.map { $0.JSONDict! },
            type(of: self).CoderKeyUserNotifications: userNotifications.map { $0.JSONDict! },
        ]
        
        if let label = label {
            ret[type(of: self).CoderKeyLabel] = label
        }
        
        if let scheduleId = scheduleId {
            ret[type(of: self).CoderKeyScheduleId] = scheduleId
        }
        
        if let schedule = schedule {
            ret[type(of: self).CoderKeySchedule] = schedule.JSONDict!
        }

        if let ruleId = ruleId {
            ret[type(of: self).CoderKeyRuleId] = ruleId
        }
        
        if let accountId = accountId {
            ret[type(of: self).CoderKeyAccountId] = accountId
        }
        
        if let deviceGroupId = deviceGroupId {
            ret[type(of: self).CoderKeyDeviceGroupId] = deviceGroupId
        }
        
        if let accountNotification = accountNotification {
            ret[type(of: self).CoderKeyAccountNotificationId] = accountNotification.id
        }
        
        if let filterCriteria = filterCriteria {
            ret[type(of: self).CoderKeyFilterCriteria] = filterCriteria.map { $0.JSONDict! }
        }
        
        return ret
        
    }
}

extension DeviceRule.Schedule: AferoJSONCoding {
    
    static let CoderKeyTime = "time"
    static let CoderKeyDayOfWeek = "dayOfWeek"
    static let CoderKeyScheduleId = "scheduleId"
    static let CoderKeyTriggeredRuleId = "triggeredRuleId"
    
    public var JSONDict: AferoJSONCodedType? {

        var ret: AferoJSONObject = [
            type(of: self).CoderKeyTime: self.time.JSONDict!,
            type(of: self).CoderKeyDayOfWeek: self.dayOfWeek.map { $0.rawValue },
        ]
        
        if let scheduleId = scheduleId {
            ret[type(of: self).CoderKeyScheduleId] = scheduleId
        }
        
        if let triggeredRuleId = triggeredRuleId {
            ret[type(of: self).CoderKeyTriggeredRuleId] = triggeredRuleId
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let scheduleId = json[type(of: self).CoderKeyScheduleId] as? String,
            let timeJson = json[type(of: self).CoderKeyTime] as? [String: Any],
            let time = DateTypes.Time(json: timeJson),
            let dayOfWeekJson = json[type(of: self).CoderKeyDayOfWeek] as? [String],
            let dayOfWeek = DateTypes.DayOfWeek.SetFrom(dayOfWeekJson) {
                
                let triggeredRuleId = json[type(of: self).CoderKeyTriggeredRuleId] as? String
                
                self.init(dayOfWeek: dayOfWeek, time: time, scheduleId: scheduleId, triggeredRuleId: triggeredRuleId)

        } else {
            DDLogInfo("Invalid Schedule json: \(String(reflecting: json))")
            return nil
        }
    }
    
}

