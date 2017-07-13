
//
//  DeviceCollection.swift
//  iTokui
//
//  Created by Tony Myles on 11/20/14.
//  Copyright (c) 2014 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

import CocoaLumberjack

// MARK: - Profile Registries

internal class CachedDeviceAccountProfilesSource: DeviceAccountProfilesSource {
    
    let TAG = "DeviceProfileRegistry"
    
    /// Strongly-held uncached source for profiles
    var source: DeviceAccountProfilesSource
    
    init(profileSource: DeviceAccountProfilesSource) {
        self.source = profileSource
    }
    
    fileprivate var profileCache: [String: DeviceProfile] = [:]
    
    func reset() {
        profileCache.removeAll(keepingCapacity: false)
    }
    
    lazy fileprivate(set) var hasVisibleDevices: Bool! = {
        return self.profileCache.reduce(false) {
            curr, next in
            if curr == true { return true }
            return next.1.presentation() != nil
        }
    }()
    
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
                
                self?.profileCache[profileId] = profile
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
                
                self?.profileCache[profileId] = profile
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
                guard let profileId = profile.id else { return }
                self?.profileCache[profileId] = profile
                self?.hasVisibleDevices = nil
            }
            
            DDLogInfo("Fetched profiles for accountId:\(accountId)", tag: TAG)
            onDone(profiles, nil)
        }
    }
    
}

// This maps our `DeviceBatchActionRequestable` so that we can report metrics.

extension DeviceCollection: DeviceBatchActionRequestable {
    
    public func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping WriteAttributeOnDone) {
        
        let startTime = mach_absolute_time()
        
        apiClient.post(actions: actions, forDeviceId: deviceId, withAccountId: accountId) {
            maybeResults, maybeError in
            maybeResults?.requestIds.forEach {
                self.metricHelper.begin(requestId: $0, accountId: accountId, deviceId: deviceId, time: startTime)
            }
            onDone(maybeResults, maybeError)
        }
        
    }
}


typealias DeviceEventHandler = (_ sender: String, _ event: String, _ data: [String: Any]) -> ()

struct DeviceRequestId: Hashable {
    
    let deviceId: String
    let requestId: Int
    
    var hashValue : Int {
        get {
            return requestId.hashValue ^ deviceId.hashValue
        }
    }
    
    public static func ==(lhs: DeviceRequestId, rhs: DeviceRequestId) -> Bool {
        return lhs.requestId == rhs.requestId && lhs.deviceId == rhs.deviceId
    }
    
}


/// A collection of Afero peripheral devices

public class DeviceCollection: NSObject, MetricsReportable {
    
    let TAG = "DeviceCollection"

    /// Represents the state of the collection overall.
    public enum State: Equatable {

        /// The `DeviceCollection` is in an unloaded/unstarted state.
        case unloaded
        
        /// The `DeviceCollection` is currently loading data.
        case loading
        
        /// The `DeviceCollection` has loaded and is ready to go.
        case loaded
        
        /// The `DeviceCollection` is in an error state.
        case error(Error?)
        
        public static func ==(lhs: DeviceCollection.State, rhs: DeviceCollection.State) -> Bool {
            
            switch (lhs, rhs) {
            case (.loading, .loading): fallthrough
            case (.loaded, .loaded): fallthrough
            case (.unloaded, .unloaded): fallthrough
            case (.error, .error):
                return true
                
            default:
                return false
            }
            
        }

    }
    
    fileprivate var _devices: [String:DeviceModel] = [:]
    
    public var allDevices: [DeviceModel] {
        return Array(_devices.values)
    }
    
    /// Whether or not this DeviceCollection's profile cache contains at least
    /// one profile with presentation.
    
    public var hasVisibleDevices: Bool {
        return profileSource.hasVisibleDevices
    }
    
    public var visibleDevices: [DeviceModel] {
        return allDevices.filter { $0.presentation != nil }
    }

    public var accountId: String { return eventStream.accountId }
    
    var isTraceEnabled: Bool = false {
        didSet {
            if oldValue != isTraceEnabled {
                restartEventStream()
            }
        }
    }
    
    var apiClient: AferoAPIClientProto
    
    internal let profileSource: CachedDeviceAccountProfilesSource
    internal var eventStream: DeviceEventStreamable
    
    // MARK: Lifecycle
    
    /// Designated initializer
    /// - parameter apiClient: An AferoAPIClientProto instance
    /// - parameter deviceEventStreamable: A source of device events
    /// - parameter profileSource: A helper to fetch device profiles as needed
    
    public init(apiClient: AferoAPIClientProto, deviceEventStreamable: DeviceEventStreamable) {
        eventStream = deviceEventStreamable
        self.profileSource = CachedDeviceAccountProfilesSource(profileSource: apiClient)
        self.apiClient = apiClient
        super.init()
        setupSinks()
    }
    
    /// Convenience initializer to create a DeviceCollection with a ConclaveDeviceEventStream.
    /// - parameter profileSource: The DeviceProfileResolvable that will be used by DeviceModel members
    ///                                to resolve profiles.
    /// - parameter accountId: The `AccountId` that will be assigned to the eventStream.
    
    public convenience init(apiClient: AferoAPIClientProto, conclaveAuthable: ConclaveAuthable, accountId: String, userId: String, mobileDeviceId: String) {

        let eventStream = ConclaveDeviceEventStream(
            authable: conclaveAuthable,
            accountId: accountId,
            userId: userId,
            clientId: mobileDeviceId
        )
        
        self.init(apiClient: apiClient, deviceEventStreamable: eventStream)
    }
    
    deinit {
        DDLogDebug("Deinitializing deviceCollection for accountId: \(accountId)")
        stopEventStream()
        eventSignalDisposable = nil
    }
    
    // MARK: Contents Observation
    
    public enum ContentsChange {
        case create(DeviceModel)
        case delete(DeviceModel)
        case resetAll
    }

    /// Observe this signal to get notifications of devices being added
    /// and removed from the collection
    
    fileprivate(set) public var contentsSignal: Signal<ContentsChange, NoError>! = nil
    fileprivate var contentsSink: Signal<ContentsChange, NoError>.Observer! = nil
    

    // MARK: State Observation
    
    fileprivate(set) public var stateSignal: Signal<State, NoError>! = nil
    fileprivate var stateSink: Signal<State, NoError>.Observer! = nil
    
    /// State of this device collection. For updates, observe `stateSignal`.
    fileprivate(set) public var state: State = .unloaded {
        didSet {
            if oldValue == state { return }
            stateSink.send(value: state)
        }
    }
    
    fileprivate func setupSinks() {
        // Set up the signal for contents changes
        var localContentsSink: Signal<ContentsChange, NoError>.Observer! = nil
        self.contentsSignal = Signal {
            sink in localContentsSink = sink
            return nil
        }
        self.contentsSink = localContentsSink
        
        // Set up the signal for state changes
        var localStateSink: Signal<State, NoError>.Observer! = nil
        self.stateSignal = Signal {
            sink in localStateSink = sink
            return nil
        }
        self.stateSink = localStateSink
    }

    
    static let NonemptyNotification = "DeviceCollectionNonemptyNotification"

    fileprivate func postNonemptyNotification() {
        
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: type(of: self).NonemptyNotification),
            object: self
        )
        
    }
    
    
    public static let AddedVisibleDeviceNotification = "DeviceCollectionAddedVisibleDeviceNotification"
    
    fileprivate func postAddedVisibleDeviceNotification() {
        
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: type(of: self).AddedVisibleDeviceNotification),
            object: self
        )
        
    }
    
    lazy fileprivate var metricHelper: MetricHelper! = {
        return MetricHelper(metricsReportable: self)
    }()

    // MARK: Private stream controls

    private func startEventStream() {

        let TAG = self.TAG
        
        if state == .loaded {
            DDLogDebug("EventStream already started; bailing.", tag: TAG)
            return
        }

        DDLogInfo("Starting eventStream.", tag: TAG)
        
        startObservingEventStream()
        
        state = .loading
        
        let trace = isTraceEnabled

        profileSource.fetchProfiles(accountId: accountId) {
            [weak self] _, _ in self?.eventStream.start(trace) {
                maybeError in if let error = maybeError {
                    DDLogError(String(format: "ERROR starting device stream: %@", error.localizedDescription), tag: TAG)
                    self?.state = .error(error)
                    return
                }
            }
        }
    }
    
    private func stopEventStream() {
        eventStream.stop()
        state = .unloaded
        for entry in _devices {
            var state = entry.1.currentState
            state.isAvailable = false
            entry.1.currentState = state
        }
        stopObservingEventStream()
    }
    
    private func restartEventStream() {
        stopEventStream()
        startEventStream()
    }
    
    // MARK: - Model
    
    /**
    Asynchronously update a device, and pass it to the optional onDone handler.
    The handler is guaranteed not to be called if either the profileId or the deviceId
    is nil on the device.
    
    - parameter device: The device to update
    - parameter onDone: An optional ``(DeviceModel)->Void`` to receive the updated device. It
    will never receive a nil device.
    */
    
    fileprivate func registerDevice(_ device: DeviceModel, onDone: ((DeviceModel)->Void)?) {
        addOrReplace(peripheral: device)
        onDone?(device)
    }
    
    fileprivate func removeDevice(_ deviceId: String?) {
        
        guard let deviceId = deviceId else { return }
        
        if let d = _devices.removeValue(forKey: deviceId) {
            d.deleted = true
            contentsSink.send(value: .delete(d))
        }
        
    }
    
    // EventStream Observation
    
    fileprivate var eventSignalDisposable: Disposable? = nil {
        willSet { eventSignalDisposable?.dispose() }
    }
    
    fileprivate func startObservingEventStream() {
        
        eventSignalDisposable = eventStream.eventSignal!
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] event in
                switch event {
                    
                case .value(let deviceEvent):
                    self?.handleEvent(deviceEvent)
                    
                case .failed(let err):
                    DDLogError(String(format: "DeviceEventStream error received: %@", err))
                    
                case .interrupted:
                    DDLogInfo("DeviceEventStream interrupted.")
                    
                case .completed:
                    DDLogInfo("DeviceEventStream completed.")
                }
        }
        
    }
    
    fileprivate func stopObservingEventStream() {
        eventSignalDisposable = nil
    }
    
    // MARK: - Stream event handlers
    
    /// Handle a DeviceStreamEvent.
    /// - parameter event: The event to handle
    
    fileprivate func handleEvent(_ event: DeviceStreamEvent) {
        
        DDLogDebug(String(format: "DeviceCollection got event: %@", String(reflecting: event)), tag: TAG)
        
        switch (event) {

        case let .peripheralList(peripherals, currentSeq):
            onPeripheralList(peripherals: peripherals, seq: currentSeq)

        case let .attributeChange(seq, peripheralId, requestId, state, reason, attribute, sourceHubId):
            onAttributeChange(peripheralId: peripheralId, attribute: attribute, requestId: requestId, seq: seq, state: state, reason: reason, sourceHubId: sourceHubId)
            
        case let .statusChange(seq, peripheralId, status):
            onStatusChange(peripheralId: peripheralId, status: status, seq: seq)
            
        case let .deviceOTA(seq, peripheralId, packageInfo):
            onDeviceOTA(peripheralId: peripheralId, packageInfo: packageInfo, seq: seq)
            
        case let .deviceOTAProgress(seq, peripheralId, progress):
            onDeviceOTAProgress(peripheralId: peripheralId, progress: progress, seq: seq)
            
        case let .invalidate(seq, maybePeripheralId, eventName, data):
            DDLogDebug(String(format: "invalidate received: %@", data), tag: TAG)
            onInvalidate(maybePeripheralId: maybePeripheralId, eventName: eventName, data: data, seq: seq)
            
        case let .deviceError(seq, _, error):
            onDeviceError(error: error, seq: seq)
            
        case let .deviceMute(seq, peripheralId, timeout):
            onDeviceMuted(peripheralId: peripheralId, timeout: timeout, seq: seq)
        }
    }
    
    /// Handle a DeviceStreamEvent.DeviceError event
    /// - parameter peripherals: The new list of peripherals associated with this collection.
    /// - parameter error: The `DeviceStreamEvent.DeviceError` that was emitted.
    /// - parameter seq: The sequence number for the eventStream message.
    /// - note: Sequence numbers are currently ignored.

    fileprivate func onDeviceError(error: DeviceStreamEvent.DeviceError, seq: DeviceStreamEventSeq?) {

        DDLogDebug("error:\(String(describing: error)) seq: \(String(describing: seq))", tag: TAG)

        guard let device = peripheral(for: error.peripheralId) else {
            return
        }
        
        if let requestId = error.requestId {
            metricHelper.end(requestId: requestId, time: mach_absolute_time(), success: false, failureReason: error.status)
        }
        
        device.error(error)
    }

    /// Handle a DeviceMuted event.
    /// - parameter peripheralId: The id of the peripheral device that was muted.
    /// - parameter timeout: The duration for the mute action.
    /// - parameter seq: The sequence number for the eventStream message.
    /// - note: Sequence numbers are currently ignored.

    func onDeviceMuted(peripheralId: String, timeout: TimeInterval, seq: DeviceStreamEventSeq?) {
        // TODO: Implement onDeviceMuted.
        DDLogDebug("TODO: mute device \(peripheralId) for \(timeout)s.")
    }
    
    /// Handle a `DeviceStreamEvent.peripheralList` event.
    ///
    /// `.peripheralList` messages are received when the DeviceEventStream starts,
    /// and whenever the peripheral device membership of the associated account changes.
    ///
    /// - parameter peripherals: The new list of peripherals associated with this collection.
    /// - parameter seq: The sequence number for the eventStream message.
    /// - note: Sequence numbers are currently ignored.
    
    fileprivate func onPeripheralList(peripherals: [DeviceStreamEvent.Peripheral], seq: DeviceStreamEventSeq) {

        let currentDeviceIds = Set(Array(_devices.keys))
        
        let deviceIdsToKeep = Set(peripherals.map { $0.id })
        let deviceIdsToRemove = currentDeviceIds.subtracting(deviceIdsToKeep)
        let deviceIdsToAdd = deviceIdsToKeep.subtracting(currentDeviceIds)
        let deviceIdsToUpdate = deviceIdsToKeep.subtracting(deviceIdsToAdd)
        
        deviceIdsToRemove.forEach { removeDevice($0) }

        let peripheralsToAdd = peripherals.filter { deviceIdsToAdd.contains($0.id) }
        peripheralsToAdd.forEach { createDevice(with: $0, seq: seq) }
        
        let peripheralsToUpdate = peripherals.filter { deviceIdsToUpdate.contains($0.id) }
        peripheralsToUpdate.forEach {
            updateDevice(with: $0) {
                device in DDLogDebug("Updated \(device?.id ?? "<nil>"))")
            }
        }
        
        self.state = .loaded
        
        //let coldStartupTime = MetricHelper.sharedInstance.coldStartUpTime
        if let wakeupTime = metricHelper.wakeUpTime {
            DDLogInfo("wakup complete in \(wakeupTime)ms")
            
            let metric: DeviceEventStreamable.Metrics = [
                "name": "WakeupTime",
                "platform": "ios",
                "deviceId": eventStream.clientId,
                "elapsed": wakeupTime,
                "success": true
            ]
            
            metricHelper.addMetric(metric, forMetricType: "application")
            metricHelper.reportMetrics()
        }
        
    }
    
    /// Create a device, from the given peripheral struct instance.
    ///
    /// - parameter peripheral: The peripheral for which the device should be created.
    /// - parameter seq: The sequence number of the event stream message, if any.
    /// - note: sequence numbers are currently ignored.
    
    fileprivate func createDevice(with peripheral: DeviceStreamEvent.Peripheral, seq: DeviceStreamEventSeq? = nil) {
        
        let deviceId = peripheral.id
        
        var device = _devices[peripheral.id]
        
        if device == nil {
            device = DeviceModel(id: deviceId, accountId: accountId, profileId: peripheral.profileId, profile: nil, attributeWriteable: self, profileResolver: profileSource, viewingNotificationConsumer: {
                [weak self] isViewing, deviceId in
                self?.notifyIsViewing(isViewing, deviceId: deviceId)
            })
            registerDevice(device!, onDone: nil)
        }
        
        updateDevice(with: peripheral) {
            [weak self] maybeDevice in
            guard let device = maybeDevice else {
                return
            }
            self?.postAddedVisibleDeviceNotification()
            self?.contentsSink?.send(value: .create(device))
        }
        
    }
    
    fileprivate func updateDevice(with peripheral: DeviceStreamEvent.Peripheral, onDone: @escaping (DeviceModel?)->Void) {

        let tag = TAG
        
        guard let device = _devices[peripheral.id] else {
            DDLogWarn("No device \(peripheral.id); bailing", tag: tag)
            onDone(nil)
            return
        }
        
        device.updateProfile {
            
            [weak self, weak device] updateProfileSuccess, maybeError in
            
            if updateProfileSuccess {
                
                guard let device = device else {
                    DDLogDebug(String(format: "Device %@ has already been reaped; bailing.", peripheral.id), tag: tag)
                    return
                }
                
                guard let _ = device.presentation else {
                    DDLogDebug(String(format: "No profile or presentation for device: \(device); bailing.", peripheral.id), tag: tag)
                    self?.removeDevice(device.id)
                    onDone(nil)
                    return
                }
                
                device.update(with: peripheral, attrsOnly: false)
                onDone(device)
            }
            
            if let error = maybeError {
                DDLogError("Unable to update profile for device: \(String(reflecting: error))", tag: tag)
            }
            
        }
        
    }
    
    /// Handle a `DeviceStreamEvent.attributeChange` message.
    /// - parameter peripheralId: the `id` of the peripheral device for which to apply the update.
    /// - parameter attribute: The new attribute value to apply to the device.
    /// - parameter requestId: The requestId, if any, of the clientAPI call that caused the update
    /// - parameter seq: The sequence number, if any, of the event
    /// - parameter state: The state, if any, of the update.
    /// - parameter reason: The reason, if any, for the change.
    /// - parameter sourceHubId: The hub, if any, that handled the change.
    ///
    /// - note: Only `.update` states are honored.
    /// - note: Request ids and sequence ids are currently ignored.
    
    fileprivate func onAttributeChange(peripheralId: String, attribute: DeviceStreamEvent.Peripheral.Attribute, requestId: Int, seq: DeviceStreamEventSeq?, state: DeviceStreamEvent.Peripheral.UpdateState?, reason: DeviceStreamEvent.Peripheral.UpdateReason?, sourceHubId: String?) {
        
        DDLogDebug("peripheralId:\(peripheralId) attribute:\(String(describing: attribute)) reqId:\(requestId) seq:\(String(describing: seq)) state:\(String(reflecting: state)) reason:\(String(reflecting: reason)) sourceHubId:\(String(describing: sourceHubId))", tag: TAG)
        
        guard case .some(.updated) = state else {
            DDLogDebug("Ignoring update for deviceId \(peripheralId) due to updateState \(String(describing: state))", tag: TAG)
            return
        }
        
        guard let device = peripheral(for: peripheralId) else {
            DDLogInfo("No device with id \(peripheralId); ignoring.", tag: TAG)
            return
        }
        
        device.update(with: attribute)
    }
    
    /// Handle a `DeviceStreamEvent.statusChange` event.
    /// - parameter peripheralId: The id of the peripheral device whose status changed.
    /// - parameter status: The device's new status
    /// - parameter seq: The sequence id for the change, if any.
    /// - note: Sequence ids are currently ignored.
    
    fileprivate func onStatusChange(peripheralId: String, status: DeviceStreamEvent.Peripheral.Status, seq: DeviceStreamEventSeq?) {
        
        DDLogDebug("peripheralId:\(peripheralId) status:\(String(reflecting: status)) seq:\(String(describing: seq))", tag: TAG)

        guard let device = peripheral(for: peripheralId) else {
            DDLogInfo("No device with id \(peripheralId); ignoring.", tag: TAG)
            return
        }
        
        device.isAvailable = status.isAvailable
        device.isDirect = status.isDirect

        // TODO: Need to wireup isVisible
        
    }
    
    /// Handle a `DeviceStreamEvent.deviceOTA` message
    ///
    /// - parameter peripheralId: The id of the peripheral device receiving the update.
    /// - parameter packageInfos: An array of `DeviceStreamEvent.OTAPackageInfo` instances
    /// - parameter seq: The sequence id for the event stream message, if any.
    /// - note: Sequence ids are currently ignored.
    
    fileprivate func onDeviceOTA(peripheralId: String, packageInfo: [DeviceStreamEvent.OTAPackageInfo], seq: DeviceStreamEventSeq?) {
        
        DDLogDebug("peripheralId:\(peripheralId) packageInfo:\(String(describing: packageInfo)) seq:\(String(describing: seq))", tag: TAG)
        
        guard
            let device = peripheral(for: peripheralId) else {
            return
        }
        
        packageInfo.forEach {
            guard $0.packageTypeId == 3 else { return }
            device.pendingOTAVersion = $0.version
        }
        
    }
    
    /// Handle a `DeviceStreamEvent.OTAProgress` message
    ///
    /// - parameter peripheralId: The id of the peripheral device receiving the OTA
    /// - parameter progress: The `DeviceStreamEvent.OTAProgress` instance representing progress.
    /// - parameter seq: The sequence id for the event stream message, if any.
    /// - note: Sequence ids are currently ignored.
    
    fileprivate func onDeviceOTAProgress(peripheralId: String, progress: DeviceStreamEvent.OTAProgress, seq: DeviceStreamEventSeq?) {
        
        DDLogDebug("peripheralId:\(peripheralId) otaProgress:\(String(describing: progress)) seq:\(String(describing: seq))", tag: TAG)
        
        guard let device = peripheral(for: peripheralId) else {
                return
        }
        
        device.otaProgress = progress.progress
    }
    
    /// Handle a `DeviceStreamEvent.invalidate` message.
    ///
    /// - parameter maybePeripheralId: The id of the peripheral targeted by the invalidation, if any
    /// - parameter eventName: The name of the invalidation event.
    /// - parameter data: The raw value that was received for this message.
    /// - parameter seq: The sequence id for the change, if any.
    /// - note: Sequence ids are currently ignored.
    /// - note: Invalidation events are inherently loosely-typed, and many of them
    ///         are computed and sent by the service based upon internal state changes.
    ///         For this reason, we only forward the name and the raw daa.
    
    fileprivate func onInvalidate(maybePeripheralId: String?, eventName: InvalidationEventKind, data: [String: Any], seq: DeviceStreamEventSeq?) {

        guard
            let peripheralId = maybePeripheralId,
            let device = peripheral(for: peripheralId) else { return }
        
        switch eventName {
            
        case InvalidationEvent.profiles.rawValue:
            device.profileId = nil
            
        case "location":
            device.currentState.locationState = .invalid
            
        default:
            break
        }
    }
    

    // MARK: - Public Stream Controls

    public func refresh() {
        stop()
        start()
    }

    // MARK: - Public stream controls
    
    public func start() {
        metricHelper.resetWakeUpTime()
        startEventStream()
    }
    
    public func stop() {
        metricHelper = nil
        stopEventStream()
    }
    
    
    public func reset() {
        eventStream.stop()

        let sink = contentsSink
        let devices = allDevices

        self._devices.removeAll(keepingCapacity: true)
        
        for device in devices {
            sink?.send(value: .delete(device))
        }

        profileSource.reset()
        self.state = .unloaded
    }
   
    // MARK: underlying store abstraction
    
    var devices: [DeviceModel] {
        return Array(_devices.values.filter { $0.profile != nil })
    }
    
    var deviceIds: [String] {
        return devices.map { $0.id }
    }
    
    /// Get a peripheral for the given id, if available.
    public func peripheral(for id: String) -> DeviceModel? {
        guard let device = _devices[id], let _ = device.profile else {
            return nil
        }
        return device
    }
    
    func addOrReplace(peripheral: DeviceModel) {
        let shouldPostNonemptyNotification = _devices.count == 0
        _devices[peripheral.id] = peripheral
        if shouldPostNonemptyNotification {
            postNonemptyNotification()
        }
    }
    
    func removePeripheral(for id: String) {
        _devices.removeValue(forKey: id)
    }
    
    // MARK: View Notification
    
    public func notifyIsViewing(_ isViewing: Bool, deviceId: String) {
        DDLogDebug(String(format: "DeviceCollection notifyIsViewing: %@ device: %@", isViewing as CVarArg, deviceId))
        eventStream.publishIsViewingNotification(isViewing, deviceId: deviceId)
    }
    
    // MARK: Queries
    
    func reportMetrics(metrics: DeviceEventStreamable.Metrics) {
        eventStream.publish(metrics: metrics)
    }
    
}

extension DeviceCollection: DeviceInfoSource {
    
    public func profileForDeviceId(_ deviceId: String) -> DeviceProfile? {
        return peripheral(for: deviceId)?.profile
    }
    
    public func displayNameForDeviceId(_ deviceId: String) -> String {
        return peripheral(for: deviceId)?.displayName ?? NSLocalizedString("Unknown device", comment: "Device collection DeviceInfoSource implementation default device displayName")
    }
    
}

