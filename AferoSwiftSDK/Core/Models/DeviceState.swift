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
            
        case .profileUpdate: return "<DeviceModelEvent.profileUpdate>"
            
        case let .stateUpdate(newState):
            return "<DeviceModelEvent.stateUpdate> \(newState)"
            
        case  let .writeStateChange(newState):
            return "<DeviceModelEvent.writeStateChange \(newState)"
            
        case .deleted: return "<DeviceModelEvent.deleted>"
            
        case .otaStart: return "<DeviceModelEvent.otaStart>"
            
        case let .otaProgress(progress):
            return "<DeviceModelEvent.otaProgress> progress: \(progress)"
            
        case .otaFinish: return "<DeviceModelEvent.otaFinish>"
            
        case let .error(deviceError):
            return "<DeviceModelEvent.error> cid: \(String(reflecting: deviceError))"
            
        case let .errorResolved(status):
            return "<DeviceModelEvent.errorResolved> status:\(status)"
            
        case let .muted(timeout):
            return "<DeviceModelEvent.muted> timout:\(timeout)s"
            
        case let .tagEvent(event: e):
            return "<DeviceModelevent.tagsUpdate> event: \(e)"
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
    
    case tagEvent(event: DeviceModelable.DeviceTagEvent)
    
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

public typealias DeviceAttributes = Dictionary<Int, AttributeValue>

// MARK: - Device State

extension DeviceState {
    
    /// Whether or not the device is available.
    ///
    /// - note: Calculation of `isAvailable` is based upon `isDirect`, `isVisible`,
    ///         `isRebooted`, `isConnectablre`, `isConnected`, `isLinked`, and `isDirty`.
    ///         Generally, application developers only need be concerned with `isAvailable`
    internal(set) public var isAvailable: Bool {
        get { return connectionState.isAvailable }
        set { connectionState.isAvailable = newValue }
    }
    
    /// Whether or not a hub can see the device.
    internal(set) public var isVisible: Bool {
        get { return connectionState.isVisible }
        set { connectionState.isVisible = newValue }
    }
    
    /// Whether or not the device rebooted recently.
    internal(set) public var isRebooted: Bool {
        get { return connectionState.isRebooted }
        set { connectionState.isRebooted = newValue }
    }
    
    /// Whether or not the device is connectable.
    internal(set) public var isConnectable: Bool {
        get { return connectionState.isConnectable }
        set { connectionState.isConnectable = newValue }
    }
    
    /// Whether or not the device is connected to the Afero cloud.
    internal(set) public var isConnected: Bool {
        get { return connectionState.isConnected }
        set { connectionState.isConnected = newValue }
    }
    
    /// Whether or not the device is currently linked and communicating
    /// with the Afero cloud.
    internal(set) public var isLinked: Bool {
        get { return connectionState.isLinked }
        set { connectionState.isLinked = newValue }
    }
    
    /// If true, the device is connected directly to the Afero cloud. If false,
    /// the device is connected via a hub.
    internal(set) public var isDirect: Bool {
        get { return connectionState.isDirect }
        set { connectionState.isDirect = newValue }
    }
    
    /// The device has one or more attributes pending write to the Afero cloud.
    internal(set) public var isDirty: Bool {
        get { return connectionState.isDirty }
        set { connectionState.isDirty = newValue }
    }
    
    /// The RSSI of the device's connection to its hub, or to the Afero cloud
    /// if direct.
    internal(set) public var RSSI: Int {
        get { return connectionState.RSSI }
        set { connectionState.RSSI = newValue }
    }
    
    /// The location state of the device.
    internal(set) public var locationState: LocationState {
        get { return connectionState.locationState ?? .notLocated }
        set { connectionState.locationState = newValue }
    }
    
    /// The timestamp of the most recent update.
    public var updatedTimestamp: Date {
        get { return connectionState.updatedTimestamp }
    }
    
}

// MARK: ExpressibleByDictionaryLiteral

extension DeviceState:  ExpressibleByDictionaryLiteral {
    
    public typealias Element = AttributeInstance
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(elements: elements)
    }
    
    
    public init(elements: [(Key, Value)]) {
        var d = [Key: Value]()
        for (k, v) in elements {
            d[k] = v
        }
        self.init(attributes: d, profileId: nil, friendlyName: nil)
    }
    
}

// MARK: SafeSubscriptable

extension DeviceState: SafeSubscriptable {
    
    public typealias Key = Int
    public typealias Value = AttributeValue
    
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
    
}

/// The set of attributes representing the current state of the device.
public struct DeviceState: CustomDebugStringConvertible, Hashable {
    
    // MARK: <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        return "<DeviceState> profileId: \(String(reflecting: profileId)) connectionState: \(String(reflecting: connectionState)) timeZoneState: \(String(reflecting: timeZoneState)) attributes: \(attributes)"
    }
    
    public var timeZoneState: TimeZoneState = .invalid(error: nil)
    
    public var friendlyName: String?
    public var profileId: String?
    
    /// Internal attributes representation
    internal(set) public var attributes: DeviceAttributes = [:]
    
    var connectionState: DeviceModelState = DeviceModelState()
    
    init(attributes: DeviceAttributes = [:], connectionState: DeviceModelState = DeviceModelState(), profileId: String?, friendlyName: String?, timeZoneState: TimeZoneState = .invalid(error: nil)) {
        self.attributes = attributes
        self.connectionState = connectionState
        self.friendlyName = friendlyName
        self.profileId = profileId
        self.timeZoneState = timeZoneState
    }
    
    init(attributes: DeviceAttributes = [:], isAvailable: Bool, isDirect: Bool, profileId: String, friendlyName: String?, timeZoneState: TimeZoneState = .invalid(error: nil)) {
        
        let connectionState = DeviceModelState(
            isAvailable: isAvailable,
            isVisible: isDirect
        )
        
        self.init(
            attributes: attributes,
            connectionState: connectionState,
            profileId: profileId,
            friendlyName: friendlyName,
            timeZoneState: timeZoneState
        )
    }
    
    // MARK: Hashable
    
    public static func ==(lhs: DeviceState, rhs: DeviceState) -> Bool {
        return lhs.isAvailable == rhs.isAvailable
            && lhs.isDirect == rhs.isDirect
            && lhs.attributes == rhs.attributes
            && lhs.friendlyName == rhs.friendlyName
            && lhs.locationState == rhs.locationState
            && lhs.timeZoneState == rhs.timeZoneState
            && lhs.profileId == rhs.profileId
    }
    
    public func hash(into h: inout Hasher) {
        h.combine(attributes)
    }
    
    
    public mutating func update(_ attributeInstance: AttributeInstance?) {
        guard let attributeInstance = attributeInstance else { return }
        attributes[attributeInstance.id] = attributeInstance.value
    }
    
    public mutating func reset() {
        attributes.removeAll(keepingCapacity: true)
    }
    
    public var attributeInstances: [AttributeInstance] {
        return attributes.map { AttributeInstance(id: $0, value: $1) }
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

public typealias DeviceEventSink = Signal<DeviceModelEvent, NoError>.Observer
public typealias DeviceEventSignal = Signal<DeviceModelEvent, NoError>
public typealias DeviceEventPipe = (signal: DeviceEventSignal, sink: DeviceEventSink)

// MARK: <AttributeSignaling>

public enum AttributeEvent {
    case update(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute)
}

extension AttributeEvent: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case let .update(accountId, deviceId, attribute):
            return "<AttributeEvent.Update> accountId: \(accountId) deviceId: \(deviceId) attribute: \(String(describing: attribute))"
        }
    }
    
    public var debugDescription: String {
        switch self {
        case let .update(accountId, deviceId, attribute):
            return "<AttributeEvent.Update> accountId: \(accountId) deviceId: \(deviceId) attribute: \(String(reflecting: attribute))"
        }
    }
}

open class PipeHolder<Value: CustomStringConvertible & CustomDebugStringConvertible, Err: Error> {
    
    var TAG: String {
        return "PipeHolder<\(Unmanaged.passUnretained(self).toOpaque())>"
    }
    
    public typealias Sig = Signal<Value, Err>
    public typealias Obs = Signal<Value, Err>.Observer
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

//public typealias AttributeEventSink = Signal<AttributeEvent, NoError>.Observer
public typealias AttributeEventSignal = Signal<AttributeEvent, NoError>

public typealias AttributeEventPipe = PipeHolder<AttributeEvent, NoError>

public protocol AttributeEventSignaling: class {
    
    func attribute(for attributeId: Int) -> DeviceModelable.Attribute?
    func eventSignalForAttributeId(_ attributeId: Int?) -> AttributeEventSignal?
    func signalAttributeUpdate(_ attributeId: Int, value: AttributeValue)
}

public extension AttributeEventSignaling {
    
    /// Produce a single `AttributeEventSignal` for multiple `attributeIds`.
    /// - parameter atributeIds: An optional Sequence of `attributeIds` from which
    ///                          to produce the merged signal.
    /// - returns: A signal merging signals for each of the attributes, or nil if the
    ///            set of component signals is empty.
    
    func eventSignalForAttributeIds<A: Sequence>(_ attributeIds: A?) -> AttributeEventSignal? where A.Iterator.Element == Int {
        
        guard let attributeIds = attributeIds else { return nil }
        
        let signals = attributeIds.compactMap {
            [weak self] attributeId in return self?.eventSignalForAttributeId(attributeId)
        }
        
        if signals.count == 0 { return nil }
        
        return AttributeEventSignal.merge(signals)
    }
    
    func eventSignalForAttributeIds<A: Sequence>(_ attributeIds: A?) -> AttributeEventSignal? where A.Iterator.Element == NSNumber {
        return eventSignalForAttributeIds(attributeIds?.compactMap { $0.intValue})
    }
    
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

public typealias DeviceCommandSink = Signal<DeviceModelCommand, NoError>.Observer
public typealias DeviceCommandSignal = Signal<DeviceModelCommand, NoError>
public typealias DeviceCommandPipe = (DeviceCommandSignal, DeviceCommandSink)

public protocol DeviceCommandConsuming: class {
    var commandSink: Signal<DeviceModelCommand, NoError>.Observer { get }
}


public protocol DeviceModelable: DeviceEventSignaling, AttributeEventSignaling, DeviceCommandConsuming, OfflineScheduleStorage {
    
    /// The unique ID of the device on the service.
    var deviceId: String { get }
    
    /// The id used for association. Maps 1:1 to `id`, but is only valid for
    /// performing associatins.
    var associationId: String? { get }
    
    /// The account to which this device is associated.
    var accountId: String { get }
    
    /// The id of the profile for this device.
    var profileId: String? { get set }
    
    /// The `DeviceProfile` for this device.
    var profile: DeviceProfile? { get }
    
    /// The presentation profile for this device. Generally a convenience accessor
    /// for profile?.presentation
    var presentation: DeviceProfile.Presentation? { get }
    
    /// If `true`, this device is online, linked, and ready to receive changes.
    var isAvailable: Bool { get }
    
    /// What we know about the location of this device.
    var locationState: LocationState { get }
    
    var timeZoneState: TimeZoneState { get }
    
    /// If `true`, then this device is directly
    var isDirect: Bool { get }
    
    /// The local timezone of the device, if set.
    var timeZone: TimeZone? { get }
    
    var writeState: DeviceWriteState { get }
    var currentState: DeviceState { get set }
    var friendlyName: String? { get set }
    var otaProgress: Float? { get }
    var deviceErrors: Set<DeviceErrorStatus> { get }
    
    func notifyViewing(_ isViewing: Bool)
    
    typealias DeviceTag = DeviceTagCollection.DeviceTag
    typealias DeviceTagEvent = DeviceTagCollection.Event
    
    var deviceTagCollection: DeviceTagCollection? { get }
    
    /// All tags associated with this instance.
    var deviceTags: Set<DeviceTag> { get }
    
    /// Get a deviceTag for the given identifier.
    /// - parameter id: The `UUID` of the tag to fetch.
    /// - returns: The matching `DeviceTag`, if any.
    func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag?
    
    /// Get all `deviceTag` for the given `key`.
    /// - parameter key: The `DeviceTag.Key` to match.
    /// - returns: All `DeviceTag`s whose key equals `key`
    func deviceTags(forKey key: DeviceTag.Key) -> Set<DeviceTag>
    
    /// Get the last `deviceTag` for the given key.
    /// - parameter key: The key to fliter by.
    /// - returns: The last `DeviceTag` matching the key, if any.
    /// - warning: There is no unique constraint on device tags in the Afero
    ///            cloud as of this writing, so it is possible that more than
    ///            one tag for a given key could exist (however, creating duplicate
    ///            keys is not supported by this API. If you would like to see
    ///            *all* keys that match the given key, use `deviceTags(forKey:)`.
    func getTag(for key: DeviceTag.Key) -> DeviceTag?
    
    func addOrUpdate(tag: DeviceTagCollection.DeviceTag, onDone: @escaping DeviceTagCollection.AddOrUpdateTagOnDone)
    func deleteTag(identifiedBy id: DeviceTagCollection.DeviceTag.Id, onDone: @escaping DeviceTagCollection.DeleteTagOnDone)
    
}

protocol DeviceModelableInternal: DeviceModelable {
    var deviceCloudSupporting: AferoCloudSupporting? { get }
}

public extension DeviceModelable {
    
    /// If false, this device doesn't have a presentation profile, and is therefore
    /// not expected to be visible to users in a consumer device (e.g., a softhub).
    /// In every other way it's treated as a regular device.
    
    var isPresentable: Bool { return presentation != nil }
}

public extension DeviceModelable {
    /// The unique ID of the device on the service.
    @available(*, deprecated, message: "DeviceModel.id is deprecated; use DeviceModel.deviceId.")
    var id: String {
        get { return deviceId }
    }
}

public func <<T> (lhs: T, rhs: T) -> Bool where T: DeviceModelable {
    if lhs.displayName < rhs.displayName { return true }
    if lhs.displayName == rhs.displayName { return lhs.deviceId < rhs.deviceId }
    return false
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: DeviceModelable {
    return rhs.deviceId == lhs.deviceId
}

public extension DeviceModelable {
    
    var TAG: String { return "DeviceModelable" }
}

public extension DeviceModelable {
    
    var displayName: String {
        
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

// MARK: - DeviceModelState Aliases -

public extension DeviceModelable {
    
    var friendlyName: String? {
        get { return currentState.friendlyName }
        set { currentState.friendlyName = newValue }
    }
    
    /// Whether or not the device is available.
    ///
    /// - note: Calculation of `isAvailable` is based upon `isDirect`, `isVisible`,
    ///         `isRebooted`, `isConnectablre`, `isConnected`, `isLinked`, and `isDirty`.
    ///         Generally, application developers only need be concerned with `isAvailable`
    
    internal(set) var isAvailable: Bool {
        get { return currentState.isAvailable }
        set { currentState.isAvailable = newValue }
    }
    
    /// Whether or not a hub can see the device.
    internal(set) var isVisible: Bool {
        get { return currentState.isVisible }
        set { currentState.isVisible = newValue }
    }
    
    /// Whether or not the device rebooted recently.
    internal(set) var isRebooted: Bool {
        get { return currentState.isRebooted }
        set { currentState.isRebooted = newValue }
    }
    
    /// Whether or not the device is connectable.
    internal(set) var isConnectable: Bool {
        get { return currentState.isConnectable }
        set { currentState.isConnectable = newValue }
    }
    
    /// Whether or not the device is connected to the Afero cloud.
    internal(set) var isConnected: Bool {
        get { return currentState.isConnected }
        set { currentState.isConnected = newValue }
    }
    
    /// Whether or not the device is currently linked and communicating
    /// with the Afero cloud.
    internal(set) var isLinked: Bool {
        get { return currentState.isLinked }
        set { currentState.isLinked = newValue }
    }
    
    /// If true, the device is connected directly to the Afero cloud. If false,
    /// the device is connected via a hub.
    internal(set) var isDirect: Bool {
        get { return currentState.isDirect }
        set { currentState.isDirect = newValue }
    }
    
    /// The device has one or more attributes pending write to the Afero cloud.
    internal(set) var isDirty: Bool {
        get { return currentState.isDirty }
        set { currentState.isDirty = newValue }
    }
    
    /// The RSSI of the device's connection to its hub, or to the Afero cloud
    /// if direct.
    internal(set) var RSSI: Int {
        get { return currentState.RSSI }
        set { currentState.RSSI = newValue }
    }
    
    /// The location state of the device.
    internal(set) var locationState: LocationState {
        get { return currentState.locationState }
        set { currentState.locationState = newValue }
    }
    
    /// the TimeZoneState of the device.
    internal(set) var timeZoneState: TimeZoneState {
        get { return currentState.timeZoneState }
        set {
            currentState.timeZoneState = newValue
            if (self as? BaseDeviceModel)?.shouldAttemptAutomaticUTCMigration ?? false {
                _ = migrateUTCOfflineScheduleEvents()
            }
        }
    }
    
    /// The device's TimeZone, if set.
    var timeZone: TimeZone? {
        return timeZoneState.timeZone
    }
    
    /// The timestamp of the most recent update.
    var updatedTimestamp: Date {
        get { return currentState.updatedTimestamp }
    }
    
}

extension DeviceModelableInternal {
    
    /// Set this device's timezone. Upon success, the timeZone will be immediately set on this device
    /// (a conclave invalidation will also be handled), and a device state update will be signaled.
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool) -> Promise<SetTimeZoneResult> {
        
        guard let deviceCloudSupporting = deviceCloudSupporting else {
            return Promise { _, reject in reject("No attribute writeable") }
        }
        
        return Promise {
            fulfill, reject in
            
            deviceCloudSupporting.setTimeZone(
                as: timeZone,
                isUserOverride: isUserOverride,
                for: deviceId,
                in: accountId) {
                    [weak self] maybeResult, maybeError in
                    if let error = maybeError {
                        reject(error)
                        return
                    }
                    
                    if let result = maybeResult {
                        (self as? BaseDeviceModel)?.timeZoneState = .some(timeZone: result.tz, isUserOverride: result.isUserOverride)
                        fulfill(result)
                        return
                    }
                    
                    reject("Missing response.")
            }
        }
        
    }
    
}

public extension DeviceModelable {
    
    func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool) -> Promise<SetTimeZoneResult> {
        return (self as? DeviceModelableInternal)?.setTimeZone(as: timeZone, isUserOverride: isUserOverride) ?? Promise {
            _, reject in reject("No actual setTimeZone implementation.")
        }
    }
    
}

public extension DeviceModelable {
    
    var presentation: DeviceProfile.Presentation? {
        return profile?.presentation(deviceId)
    }
    
    var readableAttributes: Set<DeviceProfile.AttributeDescriptor> {
        return profile?.readableAttributes ?? []
    }
    
    var readableAttributeIds: Set<Int> {
        return profile?.readableAttributeIds ?? []
    }
    
    var hasReadableAttributes: Bool {
        return readableAttributes.count > 0
    }
    
    var hasPresentableReadableAttributes: Bool {
        return profile?.hasPresentableReadableAttributes ?? false
    }
    
    var writableAttributes: Set<DeviceProfile.AttributeDescriptor> {
        return profile?.writableAttributes ?? []
    }
    
    var writableAttributeIds: Set<Int> {
        return profile?.writableAttributeIds ?? []
    }
    
    var hasWritableAttributes: Bool {
        return writableAttributes.count > 0
    }
    
    var hasPresentableWritableAttributes: Bool {
        return profile?.hasPresentableWritableAttributes ?? false
    }
    
    func groupIndicesForOperation(_ operations: AferoAttributeOperations) -> [Int] {
        return profile?.groupIndicesForOperation(operations) ?? []
    }
    
    func groupsForOperation(_ operations: AferoAttributeOperations) -> [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(operations) ?? []
    }
    
    var groupsWithWritableAttributes: [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(.Write) ?? []
    }
    
    var groupsWithReadableAttributes: [DeviceProfile.Presentation.Group] {
        return profile?.groupsForOperation(.Read) ?? []
    }
    
    /// Return all the controlIds for this device, optionally filtered per the given groupIndex.
    
    func controlIds(_ groupIndex: Int? = nil) -> [Int] {
        
        guard let groupIndex = groupIndex else {
            return profile?.presentation(deviceId)?.controls?.map { $0.id } ?? []
        }
        
        guard let groups = profile?.presentation(deviceId)?.groups else { return [] }
        
        if groupIndex >= groups.count { return [] }
        
        return groups[groupIndex].controlIds ?? []
    }
    
    var writeState: DeviceWriteState {
        return .reconciled
    }
    
    /// Fetch an attribute by id
    /// - parameter attributeId: The id of the attribute to fetch
    @available(*, deprecated, message: "Use value(for:) instead.")
    func valueForAttributeId(_ attributeId: Int) -> AttributeValue? {
        return value(for: attributeId)
    }
    
    /// Fetch an attribute by id
    /// - parameter attributeId: The id of the attribute to fetch
    func value(for attributeId: Int) -> AttributeValue? {
        return currentState[safe: attributeId]
    }
    
    func value(for descriptor: DeviceProfile.AttributeDescriptor) -> AttributeValue? {
        return value(for: descriptor.id)
    }
    
    func value(for semanticType: String) -> AttributeValue? {
        guard let id = attributeId(for: semanticType) else {
            return nil
        }
        return value(for: id)
    }
    
    func value(for systemAttribute: AferoSystemAttribute) -> AttributeValue? {
        return value(for: systemAttribute.rawValue)
    }
    
    func set(value: AttributeValue, forAttributeId attributeId: Int) -> Promise<DeviceBatchAction.Results> {
        return set(value: value, forAttributeId: attributeId, localOnly: false)
    }
    
    /// Set an attributeValue by id
    /// - parameter value: The `AttributeValue` to set
    /// - parameter forAttributeId: The attributeId which associated with the value
    /// - parameter localOnly: If true, the value is only written locally to the device state,
    ///                        and is not propogated through the service.and
    /// - returns: A `Promise<DeviceBatchAction.Results>` containing all request and response info.
    
    func set(value: AttributeValue, forAttributeId attributeId: Int, localOnly: Bool) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: [(attributeId, value)], localOnly: localOnly)
    }
    
    func set(attributes: [AttributeInstance]) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: attributes.map { ($0.id, $0.value) }, localOnly: false)
    }
    
    func set(attributes: [(Int, AttributeValue)]) -> Promise<DeviceBatchAction.Results> {
        return set(attributes: attributes, localOnly: false)
    }
    
    /// Given a sequence of `(Int, AttributeValue)` pairs, apply apply them to the device.apply
    /// If `localOnly`, then the changes are only applied locally, and may be overwritten by future
    /// incoming device updates.
    /// - parameter attributes: A sequences of `(attributeId, attributeValue)` pairs to write, in order.
    /// - parameter localOnly: If true, the value is only written locally to the device state,
    ///                        and is not propogated through the service.and
    /// - returns: A `Promise<DeviceBatchAction.Results>` containing all request and response info.
    
    func set(attributes: [(Int, AttributeValue)], localOnly: Bool) -> Promise<DeviceBatchAction.Results> {
        
        return Promise {
            
            [weak self] fulfill, reject in
            
            let instances = attributes.map { AttributeInstance(id: $0.0, value: $0.1) }
            
            if localOnly {
                self?.update(with: instances, accumulative: false)
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
                
                self?.update(with: instances)
                
                fulfill(results)
            }
        }
        
    }
    
    @available(*, deprecated, message: "Use attributeConfig(for: Int) instead.")
    func attributeConfig(forAttributeId attributeId: Int) -> DeviceProfile.AttributeConfig? {
        return attributeConfig(for: attributeId)
    }
    
    func attributeConfigs(isIncluded: @escaping (DeviceProfile.AttributeConfig)->Bool = { _ in true })
        -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], DeviceProfile.AttributeConfig>>? {
            return profile?.attributeConfigs(on: deviceId, isIncluded: isIncluded)
    }
    
    func attributeConfigs(withIdsIn range: ClosedRange<Int>) -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], DeviceProfile.AttributeConfig>>? {
        return profile?.attributeConfigs(on: deviceId, withIdsIn: range)
    }
    
    func attributeConfigs(withIdsIn range: AferoPlatformAttributeRange) -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], DeviceProfile.AttributeConfig>>? {
        return attributeConfigs(withIdsIn: range.range)
    }
    
    func attributeConfig(for attributeId: Int) -> DeviceProfile.AttributeConfig? {
        return profile?.attributeConfig(for: attributeId, on: deviceId)
    }
    
    /// Comprises an attribute value and all type and presentation info.
    typealias Attribute = (value: AttributeValue, config: DeviceProfile.AttributeConfig, displayParams: [String: Any]?)
    
    
    /// Return all `Attribute` instances for this device, lazily filtered with the given predicate.
    func attributes(isIncluded: (Attribute)->Bool = { _ in true}) -> LazyCollection<[Attribute]>? {
        return attributeConfigs()?
            .compactMap {
                config -> Attribute? in
                
                guard let value = self.value(for: config.descriptor) else {
                    return nil
                }
                
                let displayParams = profile?.valueOptionProcessor(for: config.descriptor.id)?(value)
                
                return (value: value, config: config, displayParams: displayParams)
            }.lazy
    }
    
    func attributes(in range: ClosedRange<Int>) -> LazyCollection<[Attribute]>? {
        return attributeConfigs(withIdsIn: range)?
            .compactMap {
                config -> Attribute? in
                
                guard let value = self.value(for: config.descriptor) else {
                    return nil
                }
                
                let displayParams = profile?.valueOptionProcessor(for: config.descriptor.id)?(value)
                
                return (value: value, config: config, displayParams: displayParams)
            }.lazy
    }
    
    func attributes(in range: AferoPlatformAttributeRange) -> LazyCollection<[Attribute]>? {
        return attributes(in: range.range)
    }
    
    /// Get the value and all metadata associated with an `attributeId`, if any.
    func attribute(for attributeId: Int) -> Attribute? {
        guard
            let value = value(for: attributeId),
            let config = attributeConfig(for: attributeId) else {
                return nil
        }
        
        let displayParams = profile?.valueOptionProcessor(for: config.descriptor.id)?(value)
        
        return (value: value, config: config, displayParams: displayParams)
    }
    
    func descriptorForAttributeId(_ attributeId: Int) -> DeviceProfile.AttributeDescriptor? {
        return attributeConfig(for: attributeId)?.descriptor
    }
    
    func attributeOptionForAttributeId(_ attributeId: Int) -> DeviceProfile.Presentation.AttributeOption? {
        return attributeConfig(for: attributeId)?.presentation
    }
    
    func attributeConfig(for semanticType: String) -> DeviceProfile.AttributeConfig? {
        return attributeConfigs { $0.descriptor.semanticType == semanticType }?.first
    }
    
    func descriptor(for semanticType: String) -> DeviceProfile.AttributeDescriptor? {
        return attributeConfig(for: semanticType)?.descriptor
    }
    
    func attributeId(for semanticType: String) -> Int? {
        return descriptor(for: semanticType)?.id
    }
    
    func attributeOption(for semanticType: String) -> DeviceProfile.Presentation.AttributeOption? {
        return attributeConfig(for: semanticType)?.presentation
    }
    
    func defaultValueForAttributeId(_ id: Int) -> AttributeValue? {
        guard let defaultString = descriptorForAttributeId(id)?.defaultValue else { return nil }
        return AttributeValue(stringLiteral: defaultString)
    }
    
    @available(*, deprecated, message: "Use value(for: Int) and set(value: AttributeValue, forAttributeId: Int) instead.")
    subscript(attributeId id: Int) -> AttributeValue? {
        
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
    
    @available(*, deprecated, message: "Use value(for: DeviceProfile.AttributeDescriptor) instead")
    subscript(attributeDescriptor: DeviceProfile.AttributeDescriptor) -> AttributeValue? {
        get {
            return self[attributeId: attributeDescriptor.id]
        }
    }
    
}

public extension DeviceModelable {
    
    static var CoderKeyId: String { return "id" }
    static var CoderKeyData: String { return "data" }
    static var CoderKeyValue: String { return "value" }
    static var CoderKeyAttributeId: String { return "attrId" }
    static var CoderKeyAttributes: String { return "attributes" }
    static var CoderKeyValues: String { return "values" }
    static var CoderKeyProfileId: String { return "profileId" }
    static var CoderKeyAvailable: String { return "available" }
    static var CoderKeyFriendlyName: String { return "friendlyName" }
    
    // MARK: - Update Methods: Handle external model updates
    
    func update(with peripheral: DeviceStreamEvent.Peripheral) {
        
        profileId = peripheral.profileId
        
        var state = self.currentState
        
        state.friendlyName = peripheral.friendlyName
        state.connectionState.update(with: peripheral.status)
        
        currentState = state
        
        update(with: peripheral.attributes.values)
    }
    
    func update(with attribute: DeviceStreamEvent.Peripheral.Attribute) {
        update(with: [attribute])
    }
    
    func update<S: Sequence> (with attributes: S)
        where S.Iterator.Element == DeviceStreamEvent.Peripheral.Attribute {
            update(with: attributes.compactMap {
                v in return (v.id, v.value)
            })
    }
    
    func update<S: Sequence> (with attributes: S)
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
    
    func update(_ deviceData: [String: Any], attrsOnly: Bool = true) {
        
        DDLogDebug("Before state update: \(self)", tag: "DeviceModel")
        
        // TODO: Refactor this, as the code has evolved beyond the current function sig.
        
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
    
    func update(with attributeInstances: [AttributeInstance], accumulative: Bool = true) {
        
        defer {
            if (self as? BaseDeviceModel)?.shouldAttemptAutomaticUTCMigration ?? false {
                _ = migrateUTCOfflineScheduleEvents()
            }
        }
        
        var state = currentState
        
        if !accumulative {
            state.reset()
        }
        
        attributeInstances.forEach {
            state.update($0)
        }
        
        if state == currentState { return }
        
        currentState = state
        
        attributeInstances.forEach {
            self.signalAttributeUpdate($0.id, value: $0.value)
        }
        
    }
    
    /// Identical to calling `update(_: [AttributeInstance], accumulative: Bool)` with a single-element
    /// array of instances.
    
    func update(with attributeInstance: AttributeInstance, accumulative: Bool = true) {
        update(with: [attributeInstance], accumulative: accumulative)
    }
    
    func update(with attributes: [[String: Any]], accumulative: Bool = true) {
        
        let attrs: [Int: String] = attributes.reduce([:]) {
            curr, next in
            guard
                let id = next["id"] as? Int, let value = next["value"] as? String else { return curr }
            var ret = curr
            ret[id] = value
            return ret
        }
        
        update(attrs, accumulative: accumulative)
    }
    
    /// Update (or optionally set) this modelable with the given attributes. If `accumulative` is `true`,
    /// then the current state will be modified. If `accumulative` is `false`, then
    /// the modelable's state will be replaced with new attributes.
    /// - parameter attributes: A set of attributes from which to draw device state.
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to true**.
    
    func update(_ attributes: [Int: String], accumulative: Bool = true) {
        
        let attributeInstances: [AttributeInstance] = attributes.compactMap {
            
            (attributeId: Int, stringLiteralValue: String) -> AttributeInstance? in
            
            let descriptor = descriptorForAttributeId(attributeId)
            
            let attributeValue = self.profile?.attributes[attributeId]?.valueForStringLiteral(stringLiteralValue)
            
            if attributeValue == nil {
                DDLogError(String(format: "Unable to parse value for stringLiteral: %@ with expected type %@ device: %@ (%@)", stringLiteralValue, (descriptor?.debugDescription ?? "<no descriptor>"), displayName, deviceId))
                return nil
            }
            
            if attributeValue == nil { return nil }
            
            return AttributeInstance(id: attributeId, value: attributeValue!)
        }
        
        update(with: attributeInstances, accumulative: accumulative)
    }
    
    /// Overlay (or optoinally set) this modelable's state to that indicated by the given `DeviceRuleAction`.
    /// - parameter filterCriterion: The filterCriterion from which to pull attribute state
    /// - parameter accumulative: Whether or not to overlay the current device state. **Defaults to true**.
    
    func update(_ action: DeviceRuleAction, accumulative: Bool = true) {
        
        var attributes: [Int: String] = [:]
        for (key, value) in action.attributeDict {
            guard let jsonValue = value.stringValue else { continue }
            attributes[key] = jsonValue
        }
        
        update(attributes, accumulative: accumulative)
    }
    
    
    // MARK: - Write commands: request model updates
    
    /// Successively send write commands for members of `attributes` to the commandSink (which in turn will
    /// invoke `completion` as per `.AttributeWrite` docs above.
    
    func write(_ attributes: [AttributeInstance?], completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        
        guard let actions = attributes.compactMap({ $0 }).batchActionRequests else {
            DDLogError("Unable to convert \(attributes) to batchActionRequests; bailing on write.")
            completion(nil, "Unable to convert \(attributes) to batchActionRequests; bailing on write.")
            return
        }
        
        let writeCommand: DeviceModelCommand = .postBatchActions(actions: actions, completion: completion)
        DDLogDebug("Sending write: \(writeCommand)")
        self.commandSink.send(value: writeCommand)
    }
    
    /// Send a write command for a single optional `AttributeInstance`
    func write(_ attribute: AttributeInstance?, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        write([attribute], completion: completion)
    }
    
    /// Send a write command for the given `attributeId` and `attributeValue`.
    func write(_ attributeId: Int, attributeValue: AttributeValue, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        write(AttributeInstance(id: attributeId, value: attributeValue), completion: completion)
    }
    
    /// Send a write command for a `Bool` value to the given `attributeId`. Note that no profile type checks
    /// are currently being done, so it's the responsiblity of the invoker to ensure that `Bool` is an appropriate
    /// type for the given `attributeId`.
    
    func write(_ attributeId: Int, value: Bool, completion: @escaping WriteAttributeOnDone = { _, _ in }) {
        let attributeValue = AttributeValue(value)
        write(attributeId, attributeValue: attributeValue, completion: completion)
    }
    
    func notifyViewing(_ isViewing: Bool) {
        DDLogDebug("DeviceModelable notifyViewing(\(isViewing))")
    }
}


// MARK: PrimaryOperation handling

public extension DeviceModelable {
    
    var primaryOperationAttributeDescriptor: AferoAttributeDescriptor? {
        return profile?.primaryOperationAttribute
    }
    
    var primaryOperationValue: AttributeValue? {
        return self.currentState[safe: primaryOperationAttributeDescriptor?.id]
    }
    
    var primaryOperationAttributeOptions: DeviceProfile.Presentation.AttributeOption? {
        return profile?.presentation(deviceId)?.primaryOperationOption
    }
    
    func togglePrimaryOperation(_ onDone: @escaping WriteAttributeOnDone = { _,_  in }) {
        
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
        
        if
            let rangeOptions = primaryOperationAttributeOptions.rangeOptions,
            let minValue = rangeOptions.minValue,
            let maxValue = rangeOptions.maxValue {

            var newValue = minValue

            if primaryOperationValue == newValue {
                newValue = maxValue
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

public extension DeviceModelable {
    
    var softhubHardwareInfo: String? {
        let semanticType = "Hubby Hardware Info"
        
        guard let value = value(for: .softhubHardwareInfo)?.stringValue else {
            DDLogVerbose("\(deviceId) has no value for semanticType '\(semanticType)'.", tag: TAG)
            return nil
        }
        
        return value
    }
    
}




