//
//  DeviceModel.swift
//  iTokui
//
//  Created by Justin Middleton on 6/5/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
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

open class DeviceModel: DeviceModelable, CustomStringConvertible, Hashable, Comparable {
    
    static let ErrorDomain = "DeviceModel"
    
    enum ErrorCode: Int {
    case timeout = -1
    }

    fileprivate(set) open var writeState: DeviceWriteState = .reconciled {

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
    
    open var writeTimeout: TimeInterval = 10.0
    
    fileprivate func startWriteTimer(_ actions: [DeviceBatchAction.Request]) {
        
        self.writeTimer = Timer.schedule(repeatInterval: writeTimeout) {
            [weak self] _ in
            self?.writeTimer = nil
            let localizedDescription = NSLocalizedString("Timed out.", comment: "DeviceModel attribute write timeout error description")
            self?.writeState = .failed(actions: actions, error: NSError(code: .timeout, localizedDescription: localizedDescription))
        }
    }
    
    public init(id: String, state: DeviceState = DeviceState(), accountId: String, profileId: String? = nil, profile: DeviceProfile? = nil, attributeWriteable: DeviceBatchActionRequestable? = nil, profileResolver: DeviceProfileSource? = nil, viewingNotificationConsumer: @escaping NotifyDeviceViewing = { _ in }) {
        self.id = id
        self.accountId = accountId
        self.currentState = state
        self.profileId = profileId
        self.profile = profile
        self.profileSource = profileResolver
        self.attributeWriteable = attributeWriteable
        self.viewingNotificationConsumer = viewingNotificationConsumer
    }
    
    deinit {
        commandSignalDisposable = nil
    }
    
    // MARK: Signals and Pipes

    /**
    The `DeviceBatchActionRequestable` to which attribute writes are sent. These may
    go to Conclave or the API, depending upon how things are configured.
    By default, this is nil, so writes are ignored.
    */
    
    weak fileprivate(set) open var attributeWriteable: DeviceBatchActionRequestable? = nil
    
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
    
    open var eventSignal: DeviceEventSignal {
        return eventPipe.0
    }
    
    /**
    The `Sink` to which `currentState` is broadcast after being chaned.
    */
    
    open var eventSink: DeviceEventSink {
        return eventPipe.1
    }
    
    // MARK: Attribute signaling
    
    fileprivate var attributePipeTable: [Int: AttributeEventPipe] = [:]
    
    open func eventPipeForAttributeId(_ attributeId: Int?) -> AttributeEventPipe? {
        guard let attributeId = attributeId else { return nil }
        
        guard let eventPipe = attributePipeTable[attributeId] else {
            DDLogDebug("Creating new eventPipe for attribute id \(attributeId)", tag: TAG)
            let eventPipe = AttributeEventPipe()
            attributePipeTable[attributeId] = eventPipe
            return eventPipe
        }
        
        DDLogDebug("Found pre-existing eventPipe for attributeId \(attributeId)", tag: TAG)
        return eventPipe
    }
    
    open func eventSignalForAttributeId(_ attributeId: Int?) -> AttributeEventSignal? {
        return eventPipeForAttributeId(attributeId)?.signal
    }
    
    open func signalAttributeUpdate(_ attributeId: Int, value: AttributeValue) {

        guard let
            attributeDescriptor = descriptorForAttributeId(attributeId) else { return }
        
        let attributeOption = attributeOptionForAttributeId(attributeId)
        
        let event: AttributeEvent = .update(
            accountId: accountId,
            deviceId: id,
            attributeId: attributeId,
            attributeDescriptor: attributeDescriptor,
            attributeOption: attributeOption,
            attributeValue: value
        )
        
        DDLogDebug("Signaling AttributeEvent \(event)", tag: TAG)
        eventPipeForAttributeId(attributeId)?.sendNext(event)
    }
    
    fileprivate func completeAllAttributeSignals() {
        attributePipeTable.forEach {
            id, pipe in
            pipe.sendCompleted()
        }
        attributePipeTable.removeAll()
    }
    
    // MARK: <DeviceCommandConsuming>
    
    fileprivate var commandSignalDisposable: Disposable? = nil {
        willSet {
            commandSignalDisposable?.dispose()
        }
    }
    
    lazy fileprivate var commandPipe: (DeviceCommandSignal, DeviceCommandSink) = {
        let ret = DeviceCommandSignal.pipe()
        self.commandSignalDisposable = ret.0
            .observe(on: QueueScheduler.main)
            .observe {
            [weak self] event in switch event {
            case .value(let command):

                switch command {
                    
                case let .postBatchActions(actions, completion):
                    
                    let localCompletion = {
                        (results: DeviceBatchAction.Results?, error: Error?) -> Void in
                        self?.writeTimer = nil
                        completion(results, error)
                    }
                    
                    let localCommand = DeviceModelCommand.postBatchActions(
                        actions: actions,
                        completion: localCompletion
                    )
                    
                    self?.startWriteTimer(actions)
                    
                    self?.handleCommand(localCommand)
                }
                
            default: break
            }
        }
        return ret
    }()
    
    fileprivate var commandSignal: DeviceCommandSignal {
        return commandPipe.0
    }
    
    open var commandSink: DeviceCommandSink {
        return commandPipe.1
    }
    
    // MARK: <Hashable>
    
    open var hashValue: Int { return id.hashValue }
    
    // MARK: State
    
    open var id: String
    
    fileprivate(set) open var accountId: String
    
    open var friendlyName: String? {
        get { return currentState.friendlyName }
        set { currentState.friendlyName = newValue }
    }
    
    /**
    Whether or not the device is available, according to Conclave.
    */
    
    open var isAvailable: Bool {

        get {
            return self.currentState.isAvailable
        }
        
        set {
            if newValue == currentState.isAvailable {
                return
            }
            var state = self.currentState
            state.isAvailable = newValue
            self.currentState = state
        }

    }

    /**
     True of the device connects directly to Afero, false if it is connected via a hub.
     */
    
    open var isDirect: Bool {
        
        get {
            return self.currentState.isDirect
        }
        
        set {
            if newValue == currentState.isDirect {
                return
            }
            var state = self.currentState
            state.isDirect = newValue
            self.currentState = state
        }
        
    }

    public typealias NotifyDeviceViewing = (_ isViewing: Bool, _ deviceId: String) -> Void

    fileprivate var viewingNotificationConsumer: NotifyDeviceViewing = { _, _ in }
    
    open func notifyViewing(_ isViewing: Bool) {
        viewingNotificationConsumer(isViewing, id)
    }
    
    open func updateProfile(_ onDone: @escaping (_ success: Bool, _ error: Error?)->Void = { _, _ in }) {

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
                deviceId: id,
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
    
    fileprivate var profileSource: DeviceProfileSource?
    
    /**
    DeviceProfile ID for this device. When setting, will always result in an update sent
    on the `stateSink`. If the profileID differs from current, is non-nil,
    AND the resolver has been configured, this will result in a request to the resolver to fetch the profile,
    which on update will cause a seubsequent send on `stateSink`.
    */
    
    open var profileId: String? {

        get {
            return self.currentState.profileId
        }
        
        set {

            if newValue == self.currentState.profileId {
                return
            }
            
            currentState.profileId = newValue
            updateProfile()
        }
    }
    
    // MARK: Profile Shortcuts

    /**
    The profile associated with this device.
    */
    
    open var profile: DeviceProfile? {
        didSet {
            eventSink.send(value: .profileUpdate)
        }
    }
    
    // MARK: State
    
    /**
    The current state of the device; canonical storage for isAvailable, attributes, and profileId.
    */
    
    open var currentState: DeviceState = [:] {
        didSet {
            
            if oldValue == currentState { return }
            
            emitEventsForStateChange(oldValue, newState: currentState)
            writeState = .reconciled
        }
    }
    
    fileprivate func emitEventsForStateChange(_ oldState: DeviceState, newState: DeviceState) {
        eventSink.send(value: .stateUpdate(newState: newState))
    }
    
    open var deleted: Bool = false {
        didSet {
            if deleted {
                eventSink.send(value: .deleted)
            }
        }
    }
    
    // MARK: Printable
    
    open var description: String {
        get {
            return "<DeviceModel @\(Unmanaged.passUnretained(self).toOpaque())> Device id: \(id) profileId: \(String(reflecting: profileId))"
        }
    }
    
    open var debugDescription: String { return description }
    
    // MARK: OTA Handling
    
    var otaProgressWatchdog: Timer? {
        willSet {
            otaProgressWatchdog?.invalidate()
        }
    }
    
    open var pendingOTAVersion: String?
    
    open var otaProgress: Float? {
        
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
    
    // MARK: Error reporting
    open var deviceErrors = Set<DeviceErrorStatus>()
    
    open func error(_ error: DeviceError) {
        deviceErrors.insert(error.status)
        eventSink.send(value: .error(error))
    }
    
    open func dismissError(_ status: DeviceErrorStatus) {
        deviceErrors.removeAll()
        eventSink.send(value: .errorResolved(status: status))
    }
}

// MARK: RecordingDeviceModel

public extension RecordingDeviceModel {
    
    public class func ModelsFromActions(_ models: [DeviceModel],  actions: [DeviceRuleAction]) -> [String : RecordingDeviceModel] {
        
        var actionMap: [String: DeviceRuleAction] = [:]
        for action in actions {
            actionMap[action.deviceId] = action
        }
        
        var modelMap: [String: RecordingDeviceModel] = [:]
        for model in models {
            if let action = actionMap[model.id] {
                let recordingModel = RecordingDeviceModel(model: model, copyState: false)
                recordingModel.update(action)
                recordingModel.isAvailable = true
                modelMap[model.id] = recordingModel
                DDLogDebug("Added recording model \(String(reflecting: modelMap[model.id]))")
            }
        }
        
        return modelMap
    }
    
    public class func ModelsFromFilterCriteria(_ models: [DeviceModel], filterCriteria: [DeviceFilterCriterion]) -> [String: FilterCriteriaRecordingDeviceModel] {

        var modelMap: [String: FilterCriteriaRecordingDeviceModel] = [:]
        for model in models {
            let criteria = filterCriteria.filter { $0.deviceId == model.id && (model.profile?.attributeHasControls($0.attribute.id) ?? false) }
            if criteria.count == 0 { continue }
            let recordingModel = FilterCriteriaRecordingDeviceModel(model: model, copyState: false)
            recordingModel.filterCriteria = criteria
            recordingModel.isAvailable = true
            modelMap[model.id] = recordingModel
            DDLogDebug("Added recording model \(String(reflecting: modelMap[model.id]))")
        }
        
        return modelMap
    }
}

/**
A "Dummy" device model which records writeAttribute() in its `currentState`, acknowledges them, and emits DeviceActions.
*/

open class RecordingDeviceModel: DeviceModelable, DeviceBatchActionRequestable, CustomDebugStringConvertible, Hashable, Comparable {
    
    // MARK: CustomDebugStringConvertible
    
    open var debugDescription: String {
        return "<RecordingDeviceModel @\(Unmanaged.passUnretained(self).toOpaque())> Device id: \(id) profileId: \(String(reflecting: profileId)) currentState: \(currentState)"
    }
    
    // MARK: Hashable
    
    open var hashValue: Int { return id.hashValue }
    
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
    
    open var eventSignal: DeviceEventSignal {
        return eventPipe.0
    }
    
    /**
     The `Sink` to which `currentState` is broadcast after being changed.
     */
    
    open var eventSink: DeviceEventSink {
        return eventPipe.1
    }
    
    // MARK: Attribute signaling
    
    fileprivate var attributePipeTable: [Int: AttributeEventPipe] = [:]
    
    open func eventPipeForAttributeId(_ attributeId: Int?) -> AttributeEventPipe? {
        guard let attributeId = attributeId else { return nil }
        
        guard let eventPipe = attributePipeTable[attributeId] else {
            let eventPipe = AttributeEventPipe()
            attributePipeTable[attributeId] = eventPipe
            return eventPipe
        }
        
        return eventPipe
    }
    
    open func eventSignalForAttributeId(_ attributeId: Int?) -> AttributeEventSignal? {
        return eventPipeForAttributeId(attributeId)?.signal
    }
    
    fileprivate func eventSinkForAttributeId(_ attributeId: Int?) -> AttributeEventPipe? {
        return eventPipeForAttributeId(attributeId)
    }
    
    open func signalAttributeUpdate(_ attributeId: Int, value: AttributeValue) {
        
        guard let
            attributeDescriptor = descriptorForAttributeId(attributeId) else { return }
        
        let attributeOption = attributeOptionForAttributeId(attributeId)

        let event: AttributeEvent = .update(
            accountId: accountId,
            deviceId: id,
            attributeId: attributeId,
            attributeDescriptor: attributeDescriptor,
            attributeOption: attributeOption,
            attributeValue: value
        )
        
        DDLogDebug("Signaling AttributeEvent \(event)", tag: TAG)
        eventSinkForAttributeId(attributeId)?.sendNext(event)
    }
    
    fileprivate func completeAllAttributeSignals() {
        attributePipeTable.forEach {
            id, pipe in
            pipe.sendCompleted()
        }
        attributePipeTable.removeAll()
    }
    
    // MARK: <DeviceCommandConsuming>
    
    fileprivate var commandSignalDisposable: Disposable? = nil {
        willSet {
            commandSignalDisposable?.dispose()
        }
    }
    
    lazy fileprivate var commandPipe: (DeviceCommandSignal, DeviceCommandSink) = {
        let ret = DeviceCommandSignal.pipe()
        self.commandSignalDisposable = ret.0
            .observe(on: QueueScheduler.main)
            .observe {
                event in switch event {
                case .value(let command): self.handleCommand(command)
                default: break
                }
        }
        return ret
    }()
    
    fileprivate var commandSignal: DeviceCommandSignal {
        return commandPipe.0
    }
    
    open var commandSink: DeviceCommandSink {
        return commandPipe.1
    }
    
    // MARK: <DeviceModelable>
    
    
    open var attributeWriteable: DeviceBatchActionRequestable? {
        return self
    }
    
    /**
    Whether or not the device is available, according to Conclave.
    */
    
    open var isAvailable: Bool {
        
        get {
            return self.currentState.isAvailable
        }
        
        set {
            if newValue == currentState.isAvailable {
                return
            }
            var state = self.currentState
            state.isAvailable = newValue
            self.currentState = state
        }
        
    }
    
    /**
     True of the device connects directly to Afero, false if it is connected via a hub.
     - warning: This is only included in `RecordingDeviceModel` for protocol compliance,
                and is not used anywhere else.
     */
    
    open var isDirect: Bool {
        
        get {
            return self.currentState.isDirect
        }
        
        set {
            if newValue == currentState.isDirect {
                return
            }
            var state = self.currentState
            state.isDirect = newValue
            self.currentState = state
        }
        
    }

    open var accountId: String
    open var id: String
    open var profileId: String?
    open var profile: DeviceProfile?
    open var friendlyName: String?
    open var deviceErrors = Set<DeviceErrorStatus>()
    
    open var currentState: DeviceState = [:] {
        didSet {
            emitEventsForStateChange(oldValue, newState: currentState)
        }
    }
    
    fileprivate func emitEventsForStateChange(_ oldState: DeviceState, newState: DeviceState) {
        eventSink.send(value: .stateUpdate(newState: newState))
    }
    
    open func clearAttributes() {
        var state = currentState
        state.attributes.removeAll()
        currentState = state
    }
    
    public required init(id: String, accountId: String, profile: DeviceProfile? = nil, profileId: String? = nil, friendlyName: String? = nil, initialState: DeviceState? = nil) {
        
        self.id = id
        self.accountId = accountId
        self.profile = profile
        self.profileId = profileId ?? profile?.id
        self.friendlyName = friendlyName
        self.currentState = initialState ?? DeviceState()
    }
    
    public convenience init(model: DeviceModelable, copyState: Bool = false) {
        self.init(id: model.id, accountId: model.accountId, profile: model.profile, profileId: model.profileId, friendlyName: model.friendlyName, initialState: (copyState ? model.currentState : nil))
    }
    
    deinit {
        commandSignalDisposable = nil
        completeAllAttributeSignals()
    }

    /// Whether or not writes to this device cause state to accumulate. This value
    /// is used as the `accumulative` argument to underlying `update(*)` calls.
    
    var accumulative: Bool = true

    // MARK: <DeviceBatchActionRequestable>
    
    // We masquerade as a DeviceBatchActionRequestable so that we're able to be wired directly
    // to ProfileControls, which in turn allows us to both record and publish state changes
    // without going through a service.
    
    public func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone) {
        
        DDLogDebug("\(debugDescription) Posting \(actions) forDeviceId: \(deviceId), withAccountId: \(accountId)", tag: "RecordingDeviceModel")
        
        if accountId != self.accountId {
            onDone(nil, "Incorrect accountId \(accountId) (expected \(self.accountId))")
            return
        }
        
        if deviceId != self.id {
            onDone(nil, "Incorrect deviceId \(deviceId) (expected \(self.id))")
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
    
}

open class FilterCriteriaRecordingDeviceModel: RecordingDeviceModel, DeviceFilterCriteriaSource {

    // MARK: <DeviceFilterCriteriaOperable>
    
    open var attributeFilterOperations: [Int : DeviceFilterCriterion.Operation] = [:]
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
