//
//  DeviceEvent.swift
//  iTokui
//
//  Created by Justin Middleton on 3/4/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation


import ReactiveSwift
import Result
import CocoaLumberjack
import PromiseKit

public typealias DeviceError = DeviceStreamEvent.DeviceError
public typealias DeviceErrorStatus = DeviceError.Status

/**
 Events related to a device's state.
 
 - AttributeUpdate(DeviceState): the devices' attribute state has changed.
 - WriteStateChanged(WriteState):
 */

public enum DeviceModelEvent: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        switch(self) {
            
        case .profileUpdate: return "<DeviceModelEvent.ProfileUpdate>"
            
        case let .stateUpdate(newState):
            return "<DeviceModelEvent.StateUpdate> \(newState)"
            
        case  let .writeStateChange(newState):
            return "<DeviceModelEvent.WriteStateChange \(newState)"
            
        case .deleted: return "<DeviceModelEvent.Deleted>"
            
        case .otaStart: return "<DeviceModelEvent.OTAStart>"
            
        case let .otaProgress(progress):
            return "<DeviceModelEvent.OTAProgress> progress: \(progress)"
            
        case .otaFinish: return "<DeviceModelEvent.OTAFinish>"
            
        case let .error(deviceError):
            return "<DeviceModelEvent.Error> cid: \(String(reflecting: deviceError))"
            
        case let .errorResolved(status):
            return "<DeviceModelEvent.ErrorResolved> status:\(status)"
            
        case let .muted(timeout):
            return "<DeviceModelEvent.Muted> timout:\(timeout)s"
        }
    }

    /// A device's profile has been updated. This can include any assets related to the
    /// devices's display, its controls, etc. The device view or anything showing its
    /// controls should probably be reloaded.
    case profileUpdate
    
    /// Something changed about the device's state. Views representing
    /// device state should be updated.
    case stateUpdate(newState: DeviceState)
    
    /// Either a local write was requested but has not yet been resolved,
    /// A write has resulted in an error, all pending writes have been reconciled.
    case writeStateChange(newState: DeviceWriteState)
    
    /// An error of some kind has been encountered.
    case error(DeviceError)
    
    /// The error status of the device has been resolved.
    case errorResolved(status: DeviceErrorStatus)
    
    /// An OTA of a profile or firmware has been started.
    case otaStart
    
    /// The progress of an OTA has been updated. The `progress` value is
    /// the proportion complete, 0.0...1.0.
    case otaProgress(progress: Float)
    
    /// The OTA has finished.
    case otaFinish
    
    /// The device has been deleted from its collection.
    case deleted
    
    /// The device has been muted (throttled), and will not accept additional
    /// writes for the next `timeout` seconds.
    case muted(timeout: TimeInterval)
    
}

/**
 The state of any requests made to write to a device.
 
 - If `.Reconciled`, there are no pending state changes.
 - If `.Pending`, there's a pending write.
 - If `.Failed`, the most recent write failed. The body of the write
 */

public enum DeviceWriteState {
    
    case reconciled
    case pending(actions: [DeviceBatchAction.Request])
    case failed(actions: [DeviceBatchAction.Request], error: NSError)
    
}

// MARK: - Device State

/// The set of attributes representing the current state of the device.
public struct DeviceState: ExpressibleByDictionaryLiteral, Equatable, CustomDebugStringConvertible, Hashable, SafeSubscriptable {
    
    public var debugDescription: String {
        return "<DeviceState> profileId: \(String(reflecting: profileId)) isAvailable: \(isAvailable) attributes: \(attributes)"
    }
    
    public typealias Key = Int
    public typealias Value = AttributeValue
    public typealias Element = AttributeInstance
    
    public var isAvailable: Bool
    public var isDirect: Bool
    
    public var friendlyName: String?
    public var profileId: String?
    
    public var locationState: LocationState = .none

    public var attributes: [Key: Value]
    
    public var attributeInstances: [AttributeInstance] {
        return attributes.map { AttributeInstance(id: $0, value: $1) }
    }
    
    public init(attributes: [Key: Value], isAvailable: Bool = false, isDirect: Bool = false, profileId: String? = nil, friendlyName: String? = nil) {
        self.attributes = attributes
        self.isAvailable = isAvailable
        self.isDirect = isDirect
        self.friendlyName = friendlyName
        self.profileId = profileId
    }
    
    public init(elements: [(Key, Value)], isAvailable: Bool = false, profileId: String? = nil) {
        var d = [Key: Value]()
        for (k, v) in elements {
            d[k] = v
        }
        self.init(attributes: d, isAvailable: isAvailable)
    }
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements: elements)
    }
    
    // MARK: Hashable
    
    public static func ==(lhs: DeviceState, rhs: DeviceState) -> Bool {
        return lhs.isAvailable == rhs.isAvailable
            && lhs.isDirect == rhs.isDirect
            && lhs.attributes == rhs.attributes
            && lhs.friendlyName == rhs.friendlyName
            && lhs.locationState == rhs.locationState
            && lhs.profileId == rhs.profileId
    }

    public var hashValue: Int {
        return attributes.count
    }
    
    // MARK: SafeSubscriptable
    public subscript(safe key: Key?) -> Value? {
        get {
            if let key = key {
                return attributes[key]
            }
            return nil
        }
        
        set {
            if let key = key {
                attributes[key] = newValue
            }
        }
    }
    
    public mutating func update(_ attributeInstance: AttributeInstance?) {
        guard let attributeInstance = attributeInstance else { return }
        attributes[attributeInstance.id] = attributeInstance.value
    }
    
    public mutating func reset() {
        attributes.removeAll(keepingCapacity: true)
    }
}

extension DeviceState: AferoJSONCoding {
    
    fileprivate var CoderKeyIsAvailable: String { return "isAvailable" }
    fileprivate var CoderKeyFriendlyName: String { return "friendlyName" }
    fileprivate var CoderKeyProfileId: String { return "profileId" }
    fileprivate var CoderKeyAttributes: String { return "attributes" }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            CoderKeyIsAvailable: isAvailable,
            CoderKeyAttributes: Dictionary(
                attributes.map {
                    (key: Key, value: Value) -> (String, String) in
                    return ("\(key)", value.debugDescription)
                }
            )
        ]
        
        if let friendlyName = friendlyName {
            ret[CoderKeyFriendlyName] = friendlyName
        }
        
        if let profileId = profileId {
            ret[CoderKeyProfileId] = profileId
        }
        
        return ret
        
    }
    
    public init?(json: AferoJSONCodedType?) {
        DDLogError("ERROR: JSON decoding not supported for DeviceState.")
        return nil
    }
    
}


// MARK: - Device Interfaces

// MARK: <DeviceStateSignaling>

public protocol DeviceEventSignaling: class {
    var eventSignal: DeviceEventSignal { get }
    var eventSink: DeviceEventSink { get }
}

public typealias DeviceEventSink = Observer<DeviceModelEvent, NoError>
public typealias DeviceEventSignal = Signal<DeviceModelEvent, NoError>
public typealias DeviceEventPipe = (signal: DeviceEventSignal, sink: DeviceEventSink)

// MARK: <AttributeSignaling>

public enum AttributeEvent {
    case update(accountId: String, deviceId: String, attributeId: Int, attributeDescriptor: DeviceProfile.AttributeDescriptor, attributeOption: DeviceProfile.Presentation.AttributeOption?, attributeValue: AttributeValue)
}

extension AttributeEvent: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return debugDescription
    }
    
    public var debugDescription: String {
        switch self {
        case let .update(accountId, deviceId, attributeId, attributeDescriptor, attributeOption, attributeValue):
            return "<AttributeEvent.Update> accountId: \(accountId) deviceId: \(deviceId) attributeId: \(attributeId), descriptor: \(attributeDescriptor) options: \(String(reflecting: attributeOption)) attributeValue: \(attributeValue)"
        }
    }
}

open class PipeHolder<Value: CustomStringConvertible & CustomDebugStringConvertible, Err: Error> {

    var TAG: String {
        return "PipeHolder<\(Unmanaged.passUnretained(self).toOpaque())>"
    }
    
    public typealias Sig = Signal<Value, Err>
    public typealias Obs = Observer<Value, Err>
    typealias Pipe = (Sig, Obs)
    
    let pipe: Pipe
    
    public init() {
        pipe = Sig.pipe()
    }
    
    open var signal: Sig { return pipe.0 }
    
    /// Puts a `Next` event into the given observer.
    open func sendNext(_ value: Value) {
        DDLogVerbose(String(format: "forwarding %@", value.debugDescription), tag: TAG)
        pipe.1.send(value: value)
    }
    
    /// Puts an `Failed` event into the given observer.
    open func sendFailed(_ error: Err) {
        DDLogVerbose(String(format: "forwarding failed %@", error as NSError), tag: TAG)
        pipe.1.send(error: error)
    }
    
    /// Puts a `Completed` event into the given observer.
    open func sendCompleted() {
        DDLogVerbose("forwarding completed", tag: TAG)
        pipe.1.sendCompleted()
    }
    
    /// Puts a `Interrupted` event into the given observer.
    open func sendInterrupted() {
        DDLogVerbose("forwarding interrupted", tag: TAG)
        pipe.1.sendInterrupted()
    }
    
}

//public typealias AttributeEventSink = Observer<AttributeEvent, NoError>
public typealias AttributeEventSignal = Signal<AttributeEvent, NoError>

public typealias AttributeEventPipe = PipeHolder<AttributeEvent, NoError>

public protocol AttributeEventSignaling: class {
    func eventSignalForAttributeId(_ attributeId: Int?) -> AttributeEventSignal?
    func signalAttributeUpdate(_ attributeId: Int, value: AttributeValue)
}

public extension AttributeEventSignaling {
    
    /// Produce a single `AttributeEventSignal` for multiple `attributeIds`.
    /// - parameter atributeIds: An optional Sequence of `attributeIds` from which
    ///                          to produce the merged signal.
    /// - returns: A signal merging signals for each of the attributes, or nil if the
    ///            set of component signals is empty.
    
    public func eventSignalForAttributeIds<A: Sequence>(_ attributeIds: A?) -> AttributeEventSignal? where A.Iterator.Element == Int {
        
        guard let attributeIds = attributeIds else { return nil }
        
        let signals = attributeIds.flatMap {
            [weak self] attributeId in return self?.eventSignalForAttributeId(attributeId)
        }
        
        if signals.count == 0 { return nil }
        
        return AttributeEventSignal.merge(signals)
    }
    
    public func eventSignalForAttributeIds<A: Sequence>(_ attributeIds: A?) -> AttributeEventSignal? where A.Iterator.Element == NSNumber {
        return eventSignalForAttributeIds(attributeIds?.flatMap { $0.intValue})
    }

}

// MARK: DeviceBatchActionRequestable

public typealias WriteAttributeOnDone = (DeviceBatchAction.Results?, Error?) -> Void

public protocol DeviceBatchActionRequestable: class {
    func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone)
}

public enum DeviceModelCommand {
    
    /// Write an attribute to the device.
    /// - parameter attribute: The `AttributeInstance` to write. If `nil`, no write will take place,
    ///                        and `completion` will be immediately executed with arguments `(nil, nil)`.
    /// - parameter completion: An optional block to execute with the instance written and the
    ///                         result of any underlying implementation-specific command.
    /// - important: Absence of an error being passed to `completion` does not guarantee
    ///                         that the entire round trip was successful, but **presence guarantees
    ///                         that the write did not happen**.
    
    case postBatchActions(actions: [DeviceBatchAction.Request], completion: WriteAttributeOnDone)
}

public typealias DeviceCommandSink = Observer<DeviceModelCommand, NoError>
public typealias DeviceCommandSignal = Signal<DeviceModelCommand, NoError>
public typealias DeviceCommandPipe = (DeviceCommandSignal, DeviceCommandSink)

public protocol DeviceCommandConsuming: class {
    var commandSink: Observer<DeviceModelCommand, NoError> { get }
}


public protocol DeviceModelable: class, DeviceEventSignaling, AttributeEventSignaling, DeviceCommandConsuming, OfflineScheduleStorage {
    
    var profileId: String? { get set }
    var presentation: DeviceProfile.Presentation? { get }
    var profile: DeviceProfile? { get }
    var isAvailable: Bool { get set }
    var isDirect: Bool { get set }
    var writeState: DeviceWriteState { get }
    var currentState: DeviceState { get set }
    var id: String { get set }
    var friendlyName: String? { get set }
    var accountId: String { get }
    var attributeWriteable: DeviceBatchActionRequestable? { get }
    var otaProgress: Double? { get }
    var deviceErrors: Set<DeviceErrorStatus> { get }
    
    func notifyViewing(_ isViewing: Bool)
    
}

public func <<T> (lhs: T, rhs: T) -> Bool where T: DeviceModelable {
    if lhs.displayName < rhs.displayName { return true }
    if lhs.displayName == rhs.displayName { return lhs.id < rhs.id }
    return false
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: DeviceModelable {
    return rhs.id == lhs.id
}

public extension DeviceModelable {
    
    var TAG: String { return "DeviceModelable" }
}

public extension DeviceModelable {
    
    public var displayName: String {
        
        var name = NSLocalizedString("<unknown device>", comment: "Unknown device default displayName")
        
        if let friendlyName = friendlyName, !friendlyName.isEmpty {
            name = friendlyName
        } else if let alternateName = presentation?.label, !alternateName.isEmpty {
            name = alternateName
        } else if let alternateName = profile?.deviceType, !alternateName.isEmpty {
            name = alternateName
        } else if let alternateName = profileId, !alternateName.isEmpty {
            name = alternateName
        }
        
        return name

    }
}

public extension DeviceModelable {
    
    public var presentation: DeviceProfile.Presentation? {
        return profile?.presentation(id)
    }
    
    public var readableAttributes: Set<DeviceProfile.AttributeDescriptor> {
        return profile?.readableAttributes ?? []
    }

    var readableAttributeIds: Set<Int> {
        return profile?.readableAttributeIds ?? []
    }

    public var hasReadableAttributes: Bool {
        return readableAttributes.count > 0
    }
    
    public var hasPresentableReadableAttributes: Bool {
        return profile?.hasPresentableReadableAttributes ?? false
    }
    
    public var writableAttributes: Set<DeviceProfile.AttributeDescriptor> {
        return profile?.writableAttributes ?? []
    }
    
    var writableAttributeIds: Set<Int> {
        return profile?.writableAttributeIds ?? []
    }
    
    public var hasWritableAttributes: Bool {
        return writableAttributes.count > 0
    }
    
    public var hasPresentableWritableAttributes: Bool {
        return profile?.hasPresentableWritableAttributes ?? false
    }
    
    public func groupIndicesForOperation(_ operations: DeviceProfile.AttributeDescriptor.Operations) -> [Int] {
        return profile?.groupIndicesForOperation(operations) ?? []
    }
    
    public func groupsForOperation(_ operations: DeviceProfile.AttributeDescriptor.Operations) -> [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(operations) ?? []
    }
    
    public var groupsWithWritableAttributes: [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(.Write) ?? []
    }
    
    public var groupsWithReadableAttributes: [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(.Read) ?? []
    }
    
    /// Return all the controlIds for this device, optionally filtered per the given groupIndex.
    
    public func controlIds(_ groupIndex: Int? = nil) -> [Int] {
        
        guard let groupIndex = groupIndex else {
            return profile?.presentation(id)?.controls?.map { $0.id } ?? []
        }
        
        guard let groups = profile?.presentation(id)?.groups else { return [] }
        
        if groupIndex >= groups.count { return [] }
        
        return groups[groupIndex].controlIds ?? []
    }
    
    public var writeState: DeviceWriteState {
        return .reconciled
    }

    /// Fetch an attribute by id
    /// - parameter attributeId: The id of the attribute to fetch

    public func valueForAttributeId(_ attributeId: Int) -> AttributeValue? {
        return self[attributeId: attributeId]
    }
    
    public func set(value: AttributeValue, forAttributeId attributeId: Int) -> Promise<DeviceBatchAction.Results> {
        return set(value: value, forAttributeId: attributeId, localOnly: false)
    }

    /// Set an attributeValue by id
    /// - parameter value: The `AttributeValue` to set
    /// - parameter forAttributeId: The attributeId which associated with the value
    /// - parameter localOnly: If true, the value is only written locally to the device state,
    ///                        and is not propogated through the service.and
    /// - returns: A `Promise<DeviceBatchAction.Results>` containing all request and response info.

    public func set(value: AttributeValue, forAttributeId attributeId: Int, localOnly: Bool) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: [(attributeId, value)], localOnly: localOnly)
    }

    public func set(attributes: [AttributeInstance]) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: attributes.map { ($0.id, $0.value) }, localOnly: false)
    }

    public func set(attributes: [(Int, AttributeValue)]) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: attributes, localOnly: false)
    }

    /// Given a sequence of `(Int, AttributeValue)` pairs, apply apply them to the device.apply
    /// If `localOnly`, then the changes are only applied locally, and may be overwritten by future
    /// incoming device updates.
    /// - parameter attributes: A sequences of `(attributeId, attributeValue)` pairs to write, in order.
    /// - parameter localOnly: If true, the value is only written locally to the device state,
    ///                        and is not propogated through the service.and
    /// - returns: A `Promise<DeviceBatchAction.Results>` containing all request and response info.

    public func set(attributes: [(Int, AttributeValue)], localOnly: Bool) -> Promise<DeviceBatchAction.Results> {

        return Promise {
            
            [weak self] fulfill, reject in

            let instances = attributes.map { AttributeInstance(id: $0.0, value: $0.1) }

            if localOnly {
                self?.update(instances, accumulative: false)
                fulfill((instances.batchActionRequests ?? []).successfulUnpostedResults)
                return
            }
            
            self?.write(instances) {
                
                (maybeResults, maybeError) -> Void in
                
                if let error = maybeError {
                    reject(error)
                    return
                }
                
                guard let results = maybeResults else {
                    reject(NSError(domain: "DeviceState", code: -1000, localizedDescription: NSLocalizedString("No attribute instance returned fromw rite operation", comment: "Device state error -1000 localizedDescription")))
                    return
                }
                
                fulfill(results)
            }
        }

    }

    public func attributeConfig(forAttributeId attributeId: Int) -> DeviceProfile.AttributeConfig? {
        return profile?.attributeConfig(attributeId, deviceId: id)
    }
    
    public func descriptorForAttributeId(_ attributeId: Int) -> DeviceProfile.AttributeDescriptor? {
        return attributeConfig(forAttributeId: attributeId)?.descriptor
    }
    
    public func attributeOptionForAttributeId(_ attributeId: Int) -> DeviceProfile.Presentation.AttributeOption? {
        return attributeConfig(forAttributeId: attributeId)?.presentation
    }
    
    public func defaultValueForAttributeId(_ id: Int) -> AttributeValue? {
        guard let defaultString = descriptorForAttributeId(id)?.defaultValue else { return nil }
        return AttributeValue(stringLiteral: defaultString)
    }
    
    public subscript(attributeId id: Int) -> AttributeValue? {
        
        get {
            return self.currentState[safe: id]
        }
        
        set {
            
            if currentState[safe: id] == newValue {
                return
            }
            
            var state = currentState
            state[safe: id] = newValue
            currentState = state
        }
    }
    
    public subscript(attributeDescriptor: DeviceProfile.AttributeDescriptor) -> AttributeValue? {
        get {
            return self[attributeId: attributeDescriptor.id]
        }
    }
    
    public var otaProgress: Double? { return nil }
    
}

public extension DeviceModelable {
    
    public static var CoderKeyId: String { return "id" }
    public static var CoderKeyData: String { return "data" }
    public static var CoderKeyValue: String { return "value" }
    public static var CoderKeyAttributeId: String { return "attrId" }
    public static var CoderKeyAttributes: String { return "attributes" }
    public static var CoderKeyValues: String { return "values" }
    public static var CoderKeyProfileId: String { return "profileId" }
    public static var CoderKeyAvailable: String { return "available" }
    public static var CoderKeyFriendlyName: String { return "friendlyName" }
    
    // MARK: - Update Methods: Handle external model updates
    
    public func update(with peripheral: DeviceStreamEvent.Peripheral, attrsOnly: Bool = true) {

        id = peripheral.id
        profileId = peripheral.profileId
        
        var state = self.currentState

        if !attrsOnly {
            state.friendlyName = peripheral.friendlyName
            state.isAvailable = peripheral.isAvailable
            state.isDirect = peripheral.isDirect
        }
        
        currentState = state
        
        update(with: peripheral.attributes.values)
    }
    
    public func update(with attribute: DeviceStreamEvent.Peripheral.Attribute) {
        update(with: [attribute])
    }
    
    public func update<S: Sequence> (with attributes: S)
        where S.Iterator.Element == DeviceStreamEvent.Peripheral.Attribute {
        update(with: attributes.flatMap {
            v in return (v.id, v.value)
        })
    }
    
    public func update<S: Sequence> (with attributes: S)
        where S.Iterator.Element == (Int, String?) {
            update(attributes.reduce([Int: String]()) {
                curr, next in
                var ret = curr
                if let nextV = next.1 {
                    ret[next.0] = nextV
                }
                return ret
            })
    }
    
    /// Update the modelable's state with the given data as provided in a `Conclave` payload.
    
    public func update(_ deviceData: [String: Any], attrsOnly: Bool = true) {
        
        DDLogDebug("Before state update: \(self)", tag: "DeviceModel")
        
        // TODO: Refactor this, as the code has evolved beyond the current function sig.
        
        if let idValue = deviceData[type(of: self).CoderKeyId] as? String {
            self.id = idValue
        }
        
        var state = self.currentState
        
        if !attrsOnly {
            state.friendlyName = deviceData[type(of: self).CoderKeyFriendlyName] as? String
        }
        
        if let availableValue = deviceData[type(of: self).CoderKeyAvailable] as? Int {
            state.isAvailable = availableValue != 0
        }
        
        currentState = state
        
        if let rawAttributes = deviceData[type(of: self).CoderKeyValues] as? [String: Any] {
            
            var attributes: [Int: String] = [:]
            
            for (key, value) in rawAttributes {
                if let
                    attrId = Int(key),
                    let attrData = value as? String {
                        attributes[attrId] = attrData
                        
                }
            }
            
            update(attributes)
        }
        
        if let
            attrId = deviceData[type(of: self).CoderKeyAttributeId] as? Int,
            let attrData = deviceData[type(of: self).CoderKeyValue] as? String {
                let attributes: [Int: String] = [attrId: attrData]
                update(attributes)
        }
        
        DDLogDebug("After state update: \(self)", tag: "DeviceModel")
    }
    
    /// Update the current state by successively applying the given attributeInstances. If `accumulative` is `true`,
    /// then the current state will be modified. If `accumulative` is `false`, then
    /// the modelable's state will be replaced with new attributes.
    /// - parameter attributes: The array of `AttributeInstance`s to apply
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to true**.
    
    public func update(_ attributeInstances: [AttributeInstance], accumulative: Bool = true) {
        
        var state = currentState
        
        let TAG = self.TAG
        
        if !accumulative {
            state.reset()
        }
        
        attributeInstances.forEach {
            state.update($0)
        }
        
        if state == currentState { return }
        
        attributeInstances.forEach {
            DDLogDebug(String(format: "Signaling update for attribute: %@", $0.debugDescription), tag: TAG)
            self.signalAttributeUpdate($0.id, value: $0.value)
        }
        
        currentState = state
    }
    
    /// Identical to calling `update(_: [AttributeInstance], accumulative: Bool)` with a single-element
    /// array of instances.
    
    public func update(_ attributeInstance: AttributeInstance, accumulative: Bool = true) {
        update([attributeInstance], accumulative: accumulative)
    }
    
    /// Update (or optionally set) this modelable with the given attributes. If `accumulative` is `true`,
    /// then the current state will be modified. If `accumulative` is `false`, then
    /// the modelable's state will be replaced with new attributes.
    /// - parameter attributes: A set of attributes from which to draw device state.
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to true**.
    
    public func update(_ attributes: [Int: String], accumulative: Bool = true) {
        
        let attributeInstances: [AttributeInstance] = attributes.flatMap {
            
            (attributeId: Int, stringLiteralValue: String) -> AttributeInstance? in
            
            let descriptor = descriptorForAttributeId(attributeId)
            
            let attributeValue = self.profile?.attributes[attributeId]?.valueForStringLiteral(stringLiteralValue)
            
            if attributeValue == nil {
                DDLogError(String(format: "Unable to parse value for stringLiteral: %@ with expected type %@ device: %@ (%@)", stringLiteralValue, (descriptor?.debugDescription ?? "<no descriptor>"), displayName, id))
                return nil
            }
            
            if attributeValue == nil { return nil }
            
            return AttributeInstance(id: attributeId, value: attributeValue!)
        }
        
        update(attributeInstances, accumulative: accumulative)
    }
    
    /// Overlay (or optoinally set) this modelable's state to that indicated by the given `DeviceRuleAction`.
    /// - parameter filterCriterion: The filterCriterion from which to pull attribute state
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to true**.
    
    public func update(_ action: DeviceRuleAction, accumulative: Bool = true) {
        
        var attributes: [Int: String] = [:]
        for (key, value) in action.attributeDict {
            guard let jsonValue = value.stringValue else { continue }
            attributes[key] = jsonValue
        }
        
        update(attributes, accumulative: accumulative)
    }
    
    
    // MARK: - <DeviceCommandConsuming> Default Implementations
    
    func handleCommand(_ command: DeviceModelCommand) {
        
        DDLogDebug(String(format: "Received DeviceModelCommand %@", String(describing: command)))
        
        switch command {
        case let .postBatchActions(actions, completion):
            
            let localOnDone: WriteAttributeOnDone = {
                results, maybeError in
                completion(results, maybeError)
            }

            attributeWriteable?.post(
                actions: actions,
                forDeviceId: self.id,
                withAccountId: accountId,
                onDone: localOnDone
            )

        }
    }
    
    // MARK: - Write commands: request model updates
    
    /// Successively send write commands for members of `attributes` to the commandSink (which in turn will
    /// invoke `completion` as per `.AttributeWrite` docs above.
    
    public func write(_ attributes: [AttributeInstance?], completion: @escaping WriteAttributeOnDone = { _, _ in }) {

        guard let actions = attributes.flatMap({ $0 }).batchActionRequests else {
            DDLogError("Unable to convert \(attributes) to batchActionRequests; bailing on write.")
            completion(nil, "Unable to convert \(attributes) to batchActionRequests; bailing on write.")
            return
        }

        let writeCommand: DeviceModelCommand = .postBatchActions(actions: actions, completion: completion)
        DDLogDebug("Sending write: \(writeCommand)")
        self.commandSink.send(value: writeCommand)
    }
    
    /// Send a write command for a single optional `AttributeInstance`
    public func write(_ attribute: AttributeInstance?, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        write([attribute], completion: completion)
    }
    
    /// Send a write command for the given `attributeId` and `attributeValue`.
    public func write(_ attributeId: Int, attributeValue: AttributeValue, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        write(AttributeInstance(id: attributeId, value: attributeValue), completion: completion)
    }
    
    /// Send a write command for a `Bool` value to the given `attributeId`. Note that no profile type checks
    /// are currently being done, so it's the responsiblity of the invoker to ensure that `Bool` is an appropriate
    /// type for the given `attributeId`.
    
    public func write(_ attributeId: Int, value: Bool, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        let attributeValue = AttributeValue(value)
        write(attributeId, attributeValue: attributeValue, completion: completion)
    }
    
    public func notifyViewing(_ isViewing: Bool) {
        DDLogDebug("DeviceModelable notifyViewing(\(isViewing))")
    }
}


// MARK: PrimaryOperation handling

public extension DeviceModelable {
    
    var primaryOperationAttributeDescriptor: DeviceProfile.AttributeDescriptor? {
        return profile?.primaryOperationAttribute
    }
    
    var primaryOperationValue: AttributeValue? {
        return self.currentState[safe: primaryOperationAttributeDescriptor?.id]
    }
    
    var primaryOperationAttributeOptions: DeviceProfile.Presentation.AttributeOption? {
        return profile?.presentation(id)?.primaryOperationOption
    }
    
    func togglePrimaryOperation(_ onDone: @escaping WriteAttributeOnDone = { _ in }) {
        
        guard let
            primaryOperationAttributeDescriptor = primaryOperationAttributeDescriptor,
            let primaryOperationValue = primaryOperationValue,
            let primaryOperationAttributeOptions = primaryOperationAttributeOptions else {
                onDone(nil, nil)
                return
        }
        
        if !primaryOperationAttributeDescriptor.isWritable {
            DDLogDebug("primaryOperationAttribute not writable; bailing.")
            onDone(nil, nil)
            return
        }
        
        if let rangeOptions = primaryOperationAttributeOptions.rangeOptions {
            
            var newValue = rangeOptions.min
            
            if primaryOperationValue == newValue {
                newValue = rangeOptions.max
            }
            
            write(primaryOperationAttributeDescriptor.id, attributeValue: newValue, completion: {
                results, maybeError in
                onDone(results, maybeError)
            })
            
            return
            
        }
        
        let valueOptions = primaryOperationAttributeOptions.valueOptions
        if valueOptions.count < 1 {
            DDLogDebug("Need at least 2 valueOptions for valueOption toggle; got \(valueOptions.count)")
            onDone(nil, nil)
            return
        }
        
        guard let
            matchMin = valueOptions.first?.match,
            let avMin = AttributeValue(type: primaryOperationAttributeDescriptor.dataType, value: matchMin),
            let matchMax = valueOptions.last?.match,
            let avMax = AttributeValue(type: primaryOperationAttributeDescriptor.dataType, value: matchMax) else {
                DDLogDebug(String(format: "Unable to parse min %@ or max %@ to appropriate value type %@; bailing.", valueOptions.first?.match ?? "<none>", valueOptions.last?.match ?? "<none>", primaryOperationAttributeDescriptor.dataType.debugDescription))
                onDone(nil, nil)
                return
        }
        
        var newValue = avMin
        
        if primaryOperationValue == newValue {
            newValue = avMax
        }
        
        write(primaryOperationAttributeDescriptor.id, attributeValue: newValue, completion: {
            results, maybeError in
            onDone(results, maybeError)
        })
        
    }
}


