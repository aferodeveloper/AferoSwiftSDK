//
//  DeviceModel.swift
//  iTokui
//
//  Created by Justin Middleton on 6/5/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import PromiseKit
import Result
import CocoaLumberjack


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

extension NSError {

    convenience init(code: DeviceModel.ErrorCode, localizedDescription: String) {
        self.init(domain: DeviceModel.ErrorDomain, code: code.rawValue, localizedDescription: localizedDescription)
    }
    
}

// MARK: - Service-connected device model

public class BaseDeviceModel: DeviceModelableInternal, CustomStringConvertible, Hashable, Comparable {
    

    internal(set) public var utcMigrationIsInProgress: Bool = false {
        didSet {
            DDLogVerbose("Offline Schedule UTC migration in progress: \(utcMigrationIsInProgress)", tag: TAG)
        }
    }
    
    internal var shouldAttemptAutomaticUTCMigration: Bool = false {
        didSet {
            DDLogVerbose("Offline Schedule UTC migration should attempt: \(shouldAttemptAutomaticUTCMigration)", tag: TAG)
            guard oldValue != shouldAttemptAutomaticUTCMigration else { return }
            if shouldAttemptAutomaticUTCMigration {
                _ = migrateUTCOfflineScheduleEvents()
            }
        }
    }
    
    // MARK: <CustomStringConvertible> <CustomdebugStringConvertible>
    
    public var description: String {
        get {
            return "<DeviceModel @\(Unmanaged.passUnretained(self).toOpaque())> Device id: \(deviceId) profileId: \(String(reflecting: profileId))"
        }
    }
    
    public var debugDescription: String { return description }
    
    // MARK: Required stored properties
    
    internal(set) public var deviceId: String
    
    /// The id used for association. Maps 1:1 to `id`, but is only valid for
    /// performing associatins.
    internal(set) public var associationId: String?
    
    /// The account to which this device is associated.
    internal(set) public var accountId: String
    
    /// DeviceProfile ID for this device. When setting, will always result in an update sent
    /// on the `stateSink`. If the profileID differs from current, is non-nil,
    /// AND the resolver has been configured, this will result in a request to the
    /// resolver to fetch the profile, which on update will cause a seubsequent send on `stateSink`.
    
    init(deviceId: String,
         accountId: String,
         associationId: String? = nil,
         state: DeviceState = DeviceState(),
         profile: DeviceProfile? = nil,
         deviceCloudSupporting: AferoCloudSupporting? = nil,
         profileSource: DeviceProfileSource? = nil
        ) {
        
        var localState = state
        
        if let profileId = profile?.id {
            localState.profileId = profileId
        }
        
        self.deviceId = deviceId
        self.accountId = accountId
        self.associationId = associationId
        self.currentState = localState
        self.profile = profile
        self.profileSource = profileSource
        self.deviceCloudSupporting = deviceCloudSupporting
    }
    
    convenience init(
        deviceId: String,
        accountId: String,
        associationId: String? = nil,
        profileId: String,
        friendlyName: String? = nil,
        attributes: DeviceAttributes,
        connectionState: DeviceModelState = DeviceModelState(),
        deviceCloudSupporting: AferoCloudSupporting? = nil,
        profileSource: DeviceProfileSource? = nil
        ) {
        
        let state = DeviceState(
            attributes: attributes,
            connectionState: connectionState,
            profileId: profileId,
            friendlyName: friendlyName
        )
        
        self.init(
            deviceId: deviceId,
            accountId: accountId,
            associationId: associationId,
            state: state,
            deviceCloudSupporting: deviceCloudSupporting,
            profileSource: profileSource
        )
    }
    

    // MARK: <Hashable>
    
    public var hashValue: Int { return deviceId.hashValue }
    
    // MARK: <DeviceModelable>
    
    public var profileId: String? {
        
        get { return self.currentState.profileId }
        
        set {
            currentState.profileId = newValue
            updateProfile()
        }
    }
    
    // MARK: Profile Shortcuts
    
    /// The profile associated with this device.
    public var profile: DeviceProfile? {
        didSet {
            if oldValue == profile { return }
            eventSink.send(value: .profileUpdate)
        }
    }
    
    // MARK: State
    
    /// The current state of the device; canonical storage for isAvailable, attributes, and profileId.
    public var currentState: DeviceState = [:] {
        didSet {
            if oldValue == currentState { return }
            emitEventsForStateChange(oldValue, newState: currentState)
        }
    }
    
    fileprivate func emitEventsForStateChange(_ oldState: DeviceState, newState: DeviceState) {
        eventSink.send(value: .stateUpdate(newState: newState))
    }
    
    public var deleted: Bool = false {
        didSet {
            if deleted {
                eventSink.send(value: .deleted)
            }
        }
    }
    
    // MARK: Signals and Pipes
    
    /**
     The `DeviceCloudSupporting` to which attribute writes are sent. These may
     go to Conclave or the API, depending upon how things are configured.
     By default, this is nil, so writes are ignored.
     */
    
    weak fileprivate(set) var deviceCloudSupporting: AferoCloudSupporting? = nil
    
    // MARK: State Signaling
    
    /**
     `stateChangePipe` handles events coming from wherever The Truth(tm) resides, and
     multicasts to anyone interested in the state of this device.
     */
    
    lazy fileprivate var eventPipe: (DeviceEventSignal, DeviceEventSink) = {
        return DeviceEventSignal.pipe()
    }()
    
    /**
     The `Signal` on which state changes can be received.
     */
    
    public var eventSignal: DeviceEventSignal {
        return eventPipe.0
    }
    
    /**
     The `Sink` to which `currentState` is broadcast after being chaned.
     */
    
    public var eventSink: DeviceEventSink {
        return eventPipe.1
    }
    
    // MARK: Attribute signaling
    
    fileprivate var attributePipeTable: [Int: AttributeEventPipe] = [:]
    
    public func eventPipeForAttributeId(_ attributeId: Int?) -> AttributeEventPipe? {
        guard let attributeId = attributeId else { return nil }
        
        guard let eventPipe = attributePipeTable[attributeId] else {
            DDLogVerbose("Creating new eventPipe for attribute id \(attributeId)", tag: TAG)
            let eventPipe = AttributeEventPipe()
            attributePipeTable[attributeId] = eventPipe
            return eventPipe
        }
        
        DDLogVerbose("Found pre-existing eventPipe for attributeId \(attributeId)", tag: TAG)
        return eventPipe
    }
    
    public func eventSignalForAttributeId(_ attributeId: Int?) -> AttributeEventSignal? {
        return eventPipeForAttributeId(attributeId)?.signal
    }
    
    fileprivate static var attributeSignalQ = DispatchQueue(
        label: "io.afero.attributeSignaling",
        qos: .default,
        attributes: .concurrent
    )
    
    public func signalAttributeUpdate(_ attributeId: Int, value: AttributeValue) {
        
        let TAG = self.TAG
        
        guard
            let attribute = attribute(for: attributeId),
            let pipe = eventPipeForAttributeId(attributeId) else {
                return
        }
        
        let event: AttributeEvent = .update(
            accountId: accountId,
            deviceId: deviceId,
            attribute: attribute
        )
        
        type(of: self).attributeSignalQ.async {
            DDLogVerbose("Signaling AttributeEvent \(event)", tag: TAG)
            pipe.sendNext(event)
        }
        
    }
    
    fileprivate func completeAllAttributeSignals() {
        attributePipeTable.forEach {
            id, pipe in
            pipe.sendCompleted()
        }
        attributePipeTable.removeAll()
    }
    
    // MARK: - <DeviceCommandConsuming> Default Implementations
    
    lazy fileprivate var commandPipe: (DeviceCommandSignal, DeviceCommandSink) = {
        let ret = DeviceCommandSignal.pipe()
        self.commandSignalDisposable = ret.0
            .observe(on: QueueScheduler.main)
            .observeValues {
                [weak self] command in self?.handle(command: command)
        }
        return ret
    }()
    
    fileprivate var commandSignal: DeviceCommandSignal {
        return commandPipe.0
    }
    
    public var commandSink: DeviceCommandSink {
        return commandPipe.1
    }
    
    fileprivate var commandSignalDisposable: Disposable? = nil {
        willSet { commandSignalDisposable?.dispose() }
    }
    
    func handle(command: DeviceModelCommand) {
        
        DDLogDebug(String(format: "Received DeviceModelCommand %@", String(describing: command)))
        
        switch command {
        case let .postBatchActions(actions, completion):
            
            let localOnDone: WriteAttributeOnDone = {
                results, maybeError in
                completion(results, maybeError)
            }
            
            guard let deviceCloudSupporting = deviceCloudSupporting else {
                DDLogDebug("No deviceCloudSupporting; bailing.", tag: TAG)
                localOnDone(nil, "No deviceCloudSupporting configured.")
                return
            }
            
            deviceCloudSupporting.post(
                actions: actions,
                forDeviceId: self.deviceId,
                withAccountId: accountId,
                onDone: localOnDone
            )
            
        }
    }

    fileprivate var profileSource: DeviceProfileSource?
    
    deinit {
        commandSignalDisposable = nil
        completeAllAttributeSignals()
    }
    
    public func updateProfile(_ onDone: @escaping (_ success: Bool, _ error: Error?)->Void = { _, _ in }) {
        
        if let profileId = profileId {
            self.profileSource?.fetchProfile(
                accountId: accountId,
                profileId: profileId,
                onDone: {
                    [weak self] (maybeProfile, maybeError) in asyncMain {
                        
                        guard let profile = maybeProfile else {
                            if let error = maybeError {
                                DDLogError("ERROR: Error fetching profile: \(error)")
                            }
                            onDone(false, maybeError)
                            return
                        }
                        
                        self?.profile = profile
                        onDone(true, nil)
                    }
                }
            )
        } else {
            self.profileSource?.fetchProfile(
                accountId: accountId,
                deviceId: deviceId,
                onDone: {
                    [weak self] (maybeProfile, maybeError) in asyncMain {
                        
                        guard let profile = maybeProfile else {
                            if let error = maybeError {
                                DDLogError("ERROR: Error fetching profile: \(error)")
                            }
                            onDone(false, maybeError)
                            return
                        }
                        
                        self?.profile = profile
                        onDone(true, nil)
                    }
                }
            )
        }
        
    }
    
    // MARK: Error reporting
    
    static var ErrorDomain: String { return "DeviceModel" }
    
    enum ErrorCode: Int {
        case timeout = -1
    }
    
    public var deviceErrors = Set<DeviceErrorStatus>()
    
    public func error(_ error: DeviceError) {
        deviceErrors.insert(error.status)
        eventSink.send(value: .error(error))
    }
    
    public func dismissError(_ status: DeviceErrorStatus) {
        deviceErrors.removeAll()
        eventSink.send(value: .errorResolved(status: status))
    }
    
    // MARK: Tags
    
    public var deviceTagCollection: DeviceTagCollection? { return nil }
    
    public var deviceTags: Set<DeviceTag> {
        DDLogWarn("deviceTags default (no-op) implementation called.", tag: TAG)
        return Set()
    }
    
    public func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag? {
        DDLogWarn("deviceTag(forIdentifier:\(id)) default (no-op) implementation called.", tag: TAG)
        return nil
    }
    
    public func deviceTags(forKey key: DeviceTag.Key) -> Set<DeviceTag> {
        DDLogWarn("deviceTags(forKey:\(key)) default (no-op) implementation called.", tag: TAG)
        return Set()
    }
    
    public func getTag(for key: DeviceTag.Key) -> DeviceTag? {
        DDLogWarn("getTag(for:\(key)) default (no-op) implementation called.", tag: TAG)
        return nil
    }
    
    public func addOrUpdate(tag: DeviceTag, onDone: @escaping DeviceTagCollection.AddOrUpdateTagOnDone) {
        DDLogWarn("addOrUpdate(tag:\(String(describing: tag))) default (no-op) implementation called.", tag: TAG)
        asyncMain { onDone(tag, nil) }
    }
    
    public func deleteTag(identifiedBy id: DeviceTag.Id, onDone: @escaping DeviceTagCollection.DeleteTagOnDone) {
        DDLogWarn("deleteTag(identifiedBy:\(id) default (no-op) implementation called.", tag: TAG)
        asyncMain { onDone(id, nil) }
    }
    
    // MARK: OTA Handling
    
    var otaProgressWatchdog: Timer? {
        willSet {
            otaProgressWatchdog?.invalidate()
        }
    }
    
    public var pendingOTAVersion: String?
    
    public var otaProgress: Float? {
        
        didSet {
            
            if otaProgress == oldValue { return }
            
            guard let otaProgress = otaProgress else {
                eventSink.send(value: .otaFinish)
                pendingOTAVersion = nil
                otaProgressWatchdog = nil
                return
            }
            
            if oldValue == nil {
                eventSink.send(value: .otaStart)
            }
            
            eventSink.send(value: .otaProgress(progress: otaProgress))
            
            otaProgressWatchdog = Timer.schedule(45) {
                [weak self] _ in
                self?.otaProgress = nil
            }
            
        }
    }
    
}

/// A DeviceModelable which is connected to the Afero cloud.

public class DeviceModel: BaseDeviceModel {
    
    init(
        deviceId: String,
        accountId: String,
        associationId: String? = nil,
        state: DeviceState = DeviceState(),
        tags: [DeviceTag] = [],
        profile: DeviceProfile? = nil,
        deviceCloudSupporting: AferoCloudSupporting? = nil,
        profileSource: DeviceProfileSource? = nil,
        viewingNotificationConsumer: @escaping NotifyDeviceViewing = { _ in }
        ) {
        
        self.viewingNotificationConsumer = viewingNotificationConsumer
        super.init(
            deviceId: deviceId,
            accountId: accountId,
            associationId: associationId,
            state: state,
            profile: profile,
            deviceCloudSupporting: deviceCloudSupporting,
            profileSource: profileSource
        )
        self._deviceTagCollection = DeviceTagCollection(with: self, tags: tags)

    }
    
    convenience init(
        deviceId: String,
        accountId: String,
        associationId: String? = nil,
        profileId: String,
        friendlyName: String? = nil,
        attributes: DeviceAttributes,
        tags: [DeviceTag] = [],
        connectionState: DeviceModelState = DeviceModelState(),
        deviceCloudSupporting: AferoCloudSupporting? = nil,
        profileSource: DeviceProfileSource? = nil,
        viewingNotificationConsumer:  @escaping NotifyDeviceViewing = { _ in }
        ) {
        
        let state = DeviceState(
            attributes: attributes,
            connectionState: connectionState,
            profileId: profileId,
            friendlyName: friendlyName
        )
        
        self.init(
            deviceId: deviceId,
            accountId: accountId,
            associationId: associationId,
            state: state,
            tags: tags,
            deviceCloudSupporting: deviceCloudSupporting,
            profileSource: profileSource,
            viewingNotificationConsumer: viewingNotificationConsumer
        )
    }
    
    // MARK: <DeviceCommandConsuming>
    
    /// The current state of the device; canonical storage for isAvailable, attributes, and profileId.
    override public var currentState: DeviceState {
        didSet { writeState = .reconciled }
    }

    fileprivate(set) public var writeState: DeviceWriteState = .reconciled {
        
        didSet {
            
            switch(writeState) {
                
            case .reconciled:
                self.writeTimer = nil
                
            case let .pending(actions):
                startWriteTimer(actions)
                
            default:
                break
            }
            
            eventSink.send(value: .writeStateChange(newState: writeState))
        }
        
    }
    
    fileprivate var writeTimer: Timer? = nil {
        willSet {
            if let writeTimer = writeTimer {
                writeTimer.invalidate()
            }
        }
    }
    
    public var writeTimeout: TimeInterval = 10.0
    
    fileprivate func startWriteTimer(_ actions: [DeviceBatchAction.Request]) {
        
        self.writeTimer = Timer.schedule(repeatInterval: writeTimeout) {
            [weak self] _ in
            self?.writeTimer = nil
            let localizedDescription = NSLocalizedString("Timed out.", comment: "DeviceModel attribute write timeout error description")
            self?.writeState = .failed(actions: actions, error: NSError(code: .timeout, localizedDescription: localizedDescription))
        }
    }
    
    override func handle(command: DeviceModelCommand) {

        let localCommand: DeviceModelCommand
        
        switch command {
            
        case let .postBatchActions(actions, completion):
            
            let localCompletion = {
                [weak self] (results: DeviceBatchAction.Results?, error: Error?) -> Void in
                self?.writeTimer = nil
                completion(results, error)
            }
            
            localCommand = DeviceModelCommand.postBatchActions(
                actions: actions,
                completion: localCompletion
            )
            
            startWriteTimer(actions)
            
        }
        
        super.handle(command: localCommand)
    }
    
    public typealias NotifyDeviceViewing = (_ isViewing: Bool, _ deviceId: String) -> Void

    fileprivate var viewingNotificationConsumer: NotifyDeviceViewing = { _, _ in }
    
    public func notifyViewing(_ isViewing: Bool) {
        viewingNotificationConsumer(isViewing, deviceId)
    }
    
    // MARK: Tags
    
    var _deviceTagCollection: DeviceTagCollection!
    
    override public var deviceTagCollection: DeviceTagCollection? {
        return _deviceTagCollection
    }
    
    public typealias DeviceTag = DeviceModelable.DeviceTag
    
    override internal(set) public var deviceTags: Set<DeviceTag> {
        
        get { return _deviceTagCollection.deviceTags }
        
        set {
            
            let tagsToRemove = _deviceTagCollection.deviceTags.subtracting(newValue)
            
            tagsToRemove.forEach {
                _deviceTagCollection.remove(tag: $0) { _, _ in }
            }
            
            newValue.forEach {
                _deviceTagCollection.add(tag: $0) { _, _ in }
            }
        }
        
    }
    
    /// Get a deviceTag for the given identifier.
    /// - parameter id: The `UUID` of the tag to fetch.
    /// - returns: The matching `DeviceTag`, if any.
    
    override public func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag? {
        return _deviceTagCollection.deviceTag(forIdentifier: id)
    }
    
    /// Get all `deviceTag` for the given `key`.
    /// - parameter key: The `DeviceTag.Key` to match.
    /// - returns: All `DeviceTag`s whose key equals `key`
    
    override public func deviceTags(forKey key: DeviceTag.Key) -> Set<DeviceTag> {
        return _deviceTagCollection.deviceTags(forKey: key)
    }
    
    /// Get the last `deviceTag` for the given key.
    /// - parameter key: The key to fliter by.
    /// - returns: The last `DeviceTag` matching the key, if any.
    /// - warning: There is no unique constraint on device tags in the Afero
    ///            cloud as of this writing, so it is possible that more than
    ///            one tag for a given key could exist (however, creating duplicate
    ///            keys is not supported by this API. If you would like to see
    ///            *all* keys that match the given key, use `deviceTags(forKey:)`.
    
    override public func getTag(for key: DeviceTag.Key) -> DeviceTag? {
        return _deviceTagCollection.deviceTags(forKey: key).first
    }
    
    override public func addOrUpdate(tag: DeviceTag, onDone: @escaping DeviceTagCollection.AddOrUpdateTagOnDone) {
        _deviceTagCollection.addOrUpdate(tag: tag, onDone: onDone)
    }
    
    override public func deleteTag(identifiedBy id: DeviceTag.Id, onDone: @escaping DeviceTagCollection.DeleteTagOnDone) {
        _deviceTagCollection.deleteTag(identifiedBy: id, onDone: onDone)
    }

}

extension DeviceModel: DeviceTagPersisting {

    // MARK: DeviceTagPersisting
    //
    // These calls are used by the DeviceTagCollection to commit its changes.
    
    /// Leverage our `deviceCloudSupporting` to purge a tag from the cloud for this device.
    /// - warning: While public, this is a low-level implementation used by the underlying
    ///            `DeviceTagCollection` instance.
    
    func purgeTag(with id: DeviceTagPersisting.DeviceTag.Id, onDone: @escaping DeviceTagPersisting.DeleteTagOnDone) {
        
        let missingActionableMsg = "No deviceCloudSupporting to perform purgeTag()."
        assert(deviceCloudSupporting != nil, missingActionableMsg)
        
        guard let deviceCloudSupporting = deviceCloudSupporting else {
            DDLogError(missingActionableMsg, tag: TAG)
            onDone(nil, missingActionableMsg)
            return
        }
        
        deviceCloudSupporting.purgeTag(with: id, for: deviceId, in: accountId).then {
            tag in onDone(tag, nil)
            }.catch {
                err in onDone(nil, err)
        }
    }
    
    /// Leverage our `deviceCloudSupporting` to add a tag to the cloud for this device.
    /// - warning: While public, this is a low-level implementation used by the underlying
    ///            `DeviceTagCollection` instance.
    
    func persist(tag: DeviceTagPersisting.DeviceTag, onDone: @escaping DeviceTagPersisting.AddOrUpdateTagOnDone) {
        
        let missingActionableMsg = "No deviceCloudSupporting to perform persistTag()."
        assert(deviceCloudSupporting != nil, missingActionableMsg)
        
        guard let deviceCloudSupporting = deviceCloudSupporting else {
            DDLogError(missingActionableMsg, tag: TAG)
            onDone(nil, missingActionableMsg)
            return
        }
        
        deviceCloudSupporting.persistTag(tag: tag, for: deviceId, in: accountId).then {
            tag in onDone(tag, nil)
            }.catch {
                err in onDone(nil, err)
        }
        
    }

}

extension DeviceModel {
    
    // These calls are used by the DeviceCollection to reflect changes from the
    // cloud back to the DeviceTagCollection.
    
    func _addOrUpdate(tag: DeviceTag) {
        
        let logtag = TAG
        
        _deviceTagCollection.add(tag: tag) {
            t, e in
            
            if let e = e {
                DDLogError("Error adding tag \(tag) from cloud: \(String(reflecting: e))", tag: logtag)
                return
            }
            
            DDLogDebug("Added tag from cloud: \(tag)", tag: logtag)
            
            eventSink.send(value: DeviceModelEvent.tagEvent(event: DeviceModelable.DeviceTagEvent.addedTag(tag)))
            
        }
    }
    
    func _removeTag(with id: DeviceTag.Id) {

        let logtag = TAG

        _deviceTagCollection.remove(withId: id) {
            t, e in
            
            if let e = e {
                DDLogError("Error removing tag id:\(id) from cloud: \(String(reflecting: e))", tag: logtag)
                return
            }
            
            DDLogDebug("Tag id:\(id) removed by cloud.", tag: logtag)

            guard let tag = t?.first else {
                let msg = "Expected exactly one tag from removal, got zero."
//                assert(false, msg)
                DDLogError(msg, tag: self.TAG)
                return
            }
            
            eventSink.send(value: DeviceModelEvent.tagEvent(event: DeviceModelable.DeviceTagEvent.deletedTag(tag)))

        }
    }
}



// MARK: RecordingDeviceModel

/**
A "Dummy" device model which records writeAttribute() in its `currentState`, acknowledges them, and emits DeviceActions.
*/

public class RecordingDeviceModel: BaseDeviceModel, CustomDebugStringConvertible {
    
    // MARK: CustomDebugStringConvertible
    
   override public var debugDescription: String {
        return "<RecordingDeviceModel @\(Unmanaged.passUnretained(self).toOpaque())> Device id: \(deviceId) profileId: \(String(reflecting: profileId)) currentState: \(currentState)"
    }
    
    // MARK: <DeviceModelable>
    
    public func clearAttributes() {
        var state = currentState
        state.attributes.removeAll()
        currentState = state
    }

    /// Whether or not writes to this device cause state to accumulate. This value
    /// is used as the `accumulative` argument to underlying `update(*)` calls.
    
    var accumulative: Bool = true
    
    override init(deviceId: String,
                  accountId: String,
                  associationId: String? = nil,
                  state: DeviceState = DeviceState(),
                  profile: DeviceProfile? = nil,
                  deviceCloudSupporting: AferoCloudSupporting? = nil,
                  profileSource: DeviceProfileSource? = nil
        ) {
        
        super.init(
            deviceId: deviceId,
            accountId: accountId,
            associationId: associationId,
            state: state,
            profile: profile,
            deviceCloudSupporting: deviceCloudSupporting,
            profileSource: profileSource
        )
        
        self.deviceCloudSupporting = self
    }
    
    public convenience init(model: DeviceModelable, copyState: Bool = false) {
        
        self.init(
            deviceId: model.deviceId,
            accountId: model.accountId,
            associationId: model.associationId,
            state: (copyState ? model.currentState : DeviceState(profileId: model.profileId ?? model.profile?.id, friendlyName: model.friendlyName)),
            profile: model.profile
        )
        
        deviceCloudSupporting = self
    }
    
    deinit {
        commandSignalDisposable = nil
        completeAllAttributeSignals()
    }

}

// MARK: RecordingDeviceModel - <DeviceCloudSupporting>

extension RecordingDeviceModel: DeviceTagPersisting, DeviceTagCloudPersisting {
    
    func purgeTag(with id: DeviceStreamEvent.Peripheral.DeviceTag.Id, onDone: @escaping DeviceTagPersisting.DeleteTagOnDone) {
        DDLogDebug("FYI: RecordingDeviceModels don't purge tags.", tag: TAG)
        onDone(id, nil)
    }
    
    func persist(tag: DeviceTagPersisting.DeviceTag, onDone: @escaping DeviceTagPersisting.AddOrUpdateTagOnDone) {
        DDLogDebug("FYI: RecordingDeviceModels don't persist tags.", tag: TAG)
        onDone(tag, nil)
    }
    
    func persistTag(tag: DeviceTagPersisting.DeviceTag, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag> {
        return Promise { fulfill, _ in fulfill(tag) }
    }
    
    func purgeTag(with id: DeviceTagPersisting.DeviceTag.Id, for deviceId: String, in accountId: String) -> Promise<DeviceTagPersisting.DeviceTag.Id> {
        return Promise { fulfill, _ in fulfill(id) }
    }

}

extension RecordingDeviceModel: DeviceActionable {
    
    /// We masquerade as a DeviceCloudSupporting so that we're able to be wired directly
    /// to ProfileControls, which in turn allows us to both record and publish state changes
    /// without going through a service.
    
    public func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone) {
        
        DDLogDebug("\(debugDescription) Posting \(actions) forDeviceId: \(deviceId), withAccountId: \(accountId)", tag: "RecordingDeviceModel")
        
        if accountId != self.accountId {
            onDone(nil, "Incorrect accountId \(accountId) (expected \(self.accountId))")
            return
        }
        
        if deviceId != self.deviceId {
            onDone(nil, "Incorrect deviceId \(deviceId) (expected \(self.deviceId))")
            return
        }
        
        let updateDict = actions.reduce([:]) {
            curr, next -> [Int: String] in
            guard case let .attributeWrite(id, value) = next else { return curr }
            var ret = curr
            ret[id] = value
            return ret
        }
        
        let results = actions.successfulUnpostedResults
        
        update(updateDict, accumulative: accumulative)
        
        asyncMain { onDone(results, nil) }
    }
    
     public func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool, for deviceId: String, in accountId: String) -> Promise<SetTimeZoneResult> {
        
        guard deviceId == self.deviceId, accountId == self.accountId else {
            let msg = "Incorrect deviceId (\(deviceId)) or accountId (got: \(accountId), expected: \(self.accountId)."
            DDLogError(msg + " Bailing.", tag: TAG)
            return Promise { _, reject in reject(msg) }
        }
        
        self.timeZoneState = .some(timeZone: timeZone, isUserOverride: isUserOverride)
        return Promise { fulfill, _ in fulfill((deviceId: deviceId, tz: timeZone, isUserOverride: isUserOverride)) }
    }
    
    public func setLocation(as location: DeviceLocation?, for deviceId: String, in accountId: String) -> Promise<Void> {

        guard deviceId == self.deviceId, accountId == self.accountId else {
            let msg = "Incorrect deviceId (\(deviceId)) or accountId (got: \(accountId), expected: \(self.accountId)."
            DDLogError(msg + " Bailing.", tag: TAG)
            return Promise { _, reject in reject(msg) }
        }
        
        if let location = location {
            locationState = .located(at: location)
        } else {
            locationState = .notLocated
        }
        
        return Promise { fulfill, _ in fulfill() }
    }
    
}

public extension RecordingDeviceModel {
    
    public class func ModelsFromActions(_ models: [DeviceModel],  actions: [DeviceRuleAction]) -> [String : RecordingDeviceModel] {
        
        var actionMap: [String: DeviceRuleAction] = [:]
        for action in actions {
            actionMap[action.deviceId] = action
        }
        
        var modelMap: [String: RecordingDeviceModel] = [:]
        for model in models {
            if let action = actionMap[model.deviceId] {
                let recordingModel = RecordingDeviceModel(model: model, copyState: false)
                recordingModel.update(action)
                recordingModel.isAvailable = true
                modelMap[model.deviceId] = recordingModel
                DDLogDebug("Added recording model \(String(reflecting: modelMap[model.deviceId]))")
            }
        }
        
        return modelMap
    }
    
    public var isAvailable: Bool {
        get { return currentState.isAvailable }
        set { currentState.isAvailable = newValue }
    }
    
    public class func ModelsFromFilterCriteria(_ models: [DeviceModel], filterCriteria: [DeviceFilterCriterion]) -> [String: FilterCriteriaRecordingDeviceModel] {
        
        var modelMap: [String: FilterCriteriaRecordingDeviceModel] = [:]
        for model in models {
            let criteria = filterCriteria.filter { $0.deviceId == model.deviceId && (model.profile?.attributeHasControls($0.attribute.id) ?? false) }
            if criteria.count == 0 { continue }
            let recordingModel = FilterCriteriaRecordingDeviceModel(model: model, copyState: false)
            recordingModel.filterCriteria = criteria
            recordingModel.isAvailable = true
            modelMap[model.deviceId] = recordingModel
            DDLogDebug("Added recording model \(String(reflecting: modelMap[model.deviceId]))")
        }
        
        return modelMap
    }
}

public class FilterCriteriaRecordingDeviceModel: RecordingDeviceModel, DeviceFilterCriteriaSource {

    // MARK: <DeviceFilterCriteriaOperable>
    
    public var attributeFilterOperations: [Int : DeviceFilterCriterion.Operation] = [:]
}

// MARK: Presentation helpers

public protocol DeviceInfoSource {
    
    /// Return the profile associated with the given device ID, if any.
    func profileForDeviceId(_ deviceId: String) -> DeviceProfile?
    
    /// Return te presentation associated with the given device ID, if any.
    func presentationForDeviceId(_ deviceId: String) -> DeviceProfile.Presentation?
    
    func displayNameForDeviceId(_ deviceId: String) -> String
    
}

public extension DeviceInfoSource {
    
    func presentationForDeviceId(_ deviceId: String) -> DeviceProfile.Presentation? {
        return profileForDeviceId(deviceId)?.presentation(deviceId)
    }
    
}
