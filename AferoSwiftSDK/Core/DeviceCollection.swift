
//
//  DeviceCollection.swift
//  iTokui
//
//  Created by Tony Myles on 11/20/14.
//  Copyright (c) 2014 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import PromiseKit
import CoreLocation

import CocoaLumberjack

typealias DeviceEventHandler = (_ sender: String, _ event: String, _ data: [String: Any]) -> ()

// MARK: - DeviceCollection -

/// A collection of Afero peripheral devices
///
/// The `DeviceCollection` provides a public interface for obtaining
/// `DeviceModel` objects, and ensures that the objects it vends
/// are kept up-to-date by sourcing changes to contents and individual
/// device state from the Afero cloud.
///
/// # State Observation
///
/// `DeviceCollection` `connectionState` refers to the state of an individual collection's
/// communication with its data sources on the Afero cloud, as distinct from
/// its *contents*. Changes to `connectionState` can be observed on the
/// `connectionStateSignal`.
///
/// `DeviceCollection` instances manage their own connections once started, attempting
/// reconnection to the Afero cloud in cases of unexpected disconnection. For this reason,
/// `connectionState` may change over the course of normal operation.
///
/// # Contents Observation
///
/// `DeviceCollection` contents changes are signaled separately from connection state,
/// and can be observed on the `contentsSignal`. Events emitted here indicate when
/// content changes begin and end, and which `DeviceModel`s are added and deleted.
///
/// # Lifecycle
///
/// `DeviceCollection` instance lifecycle can be managed with the following methods:
///
/// * `start()`: Ask the instance to start. The instance will attempt to connect
///   to the Afero cloud, and to stay connected while your app is in the foreground.
///
/// * `stop()`: Ask the instance to stop. Connections to the Afero cloud will
///   terminate immediately, and will not be resumed until `start()` is called.
///
/// * `reset()`: In addition to tasks carried out by `stop()`, `reset()` will also
///   clear all content, sending events for deleted devices, and revert to an `unloaded`
///   `connectionState`.
///
///
public class DeviceCollection: NSObject, MetricsReportable {
    
    fileprivate lazy var TAG: String = { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }()
    
    public override var debugDescription: String {
        return "<\(TAG)> accountId: \(accountId) state: \(connectionState) eventStream: \(eventStream.debugDescription)"
    }
    
    /// The id of the account this `DeviceCollection`.
    public var accountId: String { return eventStream.accountId }
    
    /// If `true`, additional debugging is turned on for realtime connections.
    /// Defaults to `false`.
    var isTraceEnabled: Bool = false {
        didSet {
            if oldValue != isTraceEnabled {
                restartEventStream()
            }
        }
    }
    
    private var _deviceRegistry: [String:DeviceModel] = [:]
    
    private var _allDevices: [DeviceModel] {
        return Array(_deviceRegistry.values)
    }
    
    internal var apiClient: AferoAPIClientProto
    
    internal let profileSource: CachedDeviceAccountProfilesSource
    internal var eventStream: DeviceEventStreamable
    
    /// All visible devices in this account
    public var devices: [DeviceModel] {
        return _allDevices.filter { $0.presentation != nil }
    }
    
    /// Whether or not this DeviceCollection's profile cache contains at least
    /// one profile with presentation.
    
    public var hasVisibleDevices: Bool {
        return profileSource.hasVisibleDevices
    }

    // MARK: - Lifecycle -
    
    /// Designated initializer
    /// - parameter apiClient: An AferoAPIClientProto instance
    /// - parameter deviceEventStreamable: A source of device events
    /// - parameter profileSource: A helper to fetch device profiles as needed
    
    init(apiClient: AferoAPIClientProto, deviceEventStreamable: DeviceEventStreamable) {
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
        DDLogDebug("Deinitializing.", tag: TAG)
        unregisterFromAppStateNotifications()
        stopEventStream()
        eventSignalDisposable = nil
    }
    
    // MARK: - Contents Change Observation -
    
    /// Events related to the contents of a `DeviceCollection`.
    ///
    /// Any time one or more, events are emitted on the collection's `contentsSignal`.
    /// Updates beging with a `.beginUpdates` event, and end with a `.endUpdates` event.
    /// For example, four devices *A*, *B*, *C*, and *D* are being removed, and
    /// two devices *X* and *Y* are being added, then the following events
    /// would be sent:
    ///
    /// 1. `.beginUpdates`
    /// 2. `.delete(A)`, … , `.delete(D)`
    /// 3. `.add(X)`,`.add(Y)`
    /// 4. `.endUpdates`
    ///
    /// ## Cases
    ///
    /// * `.beginUpdates`: The contents of the `DeviceCollection` are about to change.
    /// * `.create(DeviceModel)`: The `DeviceCollection` added the given device.
    /// * `.delete(DeviceModel)`: The `DeviceCollection` removed the given device.
    /// * `.resetAll`: The `DeviceCollection` has been reset; all devices have been removed.
    /// * `endUpdates`: The `DeviceCollection` has finished contents updates.
    ///
    public enum ContentEvent {
        
        /// The contents of the `DeviceCollection` are about to change.
        case beginUpdates
        
        /// The `DeviceCollection` added the given device.
        case create(DeviceModel)
        
        /// The `DeviceCollection` removed the given device.
        case delete(DeviceModel)
        
        /// The `DeviceCollection` has been reset; all devices have been removed.
        case resetAll
        
        /// The `DeviceCollection` has finished contents updates.
        case endUpdates
        
    }
    
    /// Observe this signal to get notifications of devices being added
    /// and removed from the collection.
    ///
    /// See `ContentsChange` for a discussion of the events
    /// emitted by this signal.
    
    fileprivate(set) public var contentsSignal: Signal<ContentEvent, Never>! = nil
    fileprivate var contentsSink: Signal<ContentEvent, Never>.Observer! = nil
    
    // MARK: - State Observation -
    
    /// Represents the connection state of the DeviceCollection.
    ///
    /// The `DeviceCollection` aggregates data from a number of sources, including
    /// the Afero Cloud API and the Conclave realtime service. `State` events represent
    /// the connection state of the `DeviceCollection`, but do not reflect contents state.
    ///
    /// It is possible that the `DeviceCollection` will appear empty
    /// even after a `loaded` is received; this event is more appropriate for
    /// dismissing progress indicators, etc. Observe `contentsSignal` for content-
    /// related events.
    ///
    /// Note that the `DeviceCollection` automatically manages its connection state,
    /// so it is possible that `State` events will be emitted at anytime during the course
    /// of app execution.
    ///
    /// ## Cases
    ///
    /// * `.unloaded`: The `DeviceCollection` is in an unloaded/unstarted state; no events
    ///               are being received.
    ///
    /// * `.loading`: The `DeviceCollection` is starting attempting to connect to its sources.
    ///
    /// * `.loaded`: The `DeviceCollection` has has started and is handling events.
    ///
    /// * `.error(Error?)`: The `DeviceCollection` is in an error state.
    ///
    public enum ConnectionState: Equatable {
        
        /// The `DeviceCollection` is in an unloaded/unstarted state; no events
        /// are being received.
        case unloaded
        
        /// The `DeviceCollection` is starting attempting to connect to its sources.
        case loading
        
        /// The `DeviceCollection` has has started and is handling events.
        ///  - note: It is possible that the `DeviceCollection` will appear empty
        ///  even after a `loaded` is received; this event is more appropriate for
        ///  dismissing progress indicators, etc. Observe `contentsSignal` for content-
        ///  related events.
        ///
        case loaded
        
        /// The `DeviceCollection` is in an error state.
        case error(Error?)
        
        public static func ==(lhs: DeviceCollection.ConnectionState, rhs: DeviceCollection.ConnectionState) -> Bool {
            
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
    
    fileprivate(set) public var connectionStateSignal: Signal<ConnectionState, Never>! = nil
    fileprivate var connectionStateSink: Signal<ConnectionState, Never>.Observer! = nil
    
    /// State of this device collection. For updates, observe `stateSignal`.
    fileprivate(set) public var connectionState: ConnectionState = .unloaded {
        didSet {
            if oldValue == connectionState { return }
            connectionStateSink.send(value: connectionState)
        }
    }
    
    fileprivate func setupSinks() {
        // Set up the signal for contents changes
        var localContentsSink: Signal<ContentEvent, Never>.Observer! = nil
        self.contentsSignal = Signal {
            sink, _ in localContentsSink = sink
        }
        self.contentsSink = localContentsSink
        
        // Set up the signal for state changes
        var localStateSink: Signal<ConnectionState, Never>.Observer! = nil
        self.connectionStateSignal = Signal {
            sink, _ in localStateSink = sink
        }
        self.connectionStateSink = localStateSink
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
    
    // MARK: - Metrics collection -
    
    private var _metricHelper: MetricHelper?
    
    internal var metricHelper: MetricHelper! {
        get {
            if let metricHelper = _metricHelper {
                return metricHelper
            }
            let metricHelper = MetricHelper(metricsReportable: self)
            _metricHelper = metricHelper
            return metricHelper
        }
        
        set { _metricHelper = newValue }
    }
    
    
    // MARK: - Private stream controls -
    
    private func startEventStream() {
        
        let TAG = self.TAG
        
        metricHelper.resetWakeUpTime()
        
        if connectionState == .loaded {
            DDLogDebug("EventStream already started; bailing.", tag: TAG)
            return
        }
        
        DDLogInfo("Starting eventStream.", tag: TAG)
        
        startObservingEventStream()
        
        connectionState = .loading
        
        let trace = isTraceEnabled
        
        _ = profileSource.fetchProfiles(for: accountId)
            .then {
                _ in return self.apiClient.fetchDevices(for: self.accountId)
            }.then {
                devicesJson in
                self.createOrUpdateDevices(with: devicesJson)
            }.then {
                _ in self.connectionState = .loaded
            }.then {
                self.eventStream.start(trace) {
                    maybeError in if let error = maybeError {
                        DDLogError(String(format: "ERROR starting device stream: %@", error.localizedDescription), tag: TAG)
                        self.connectionState = .error(error)
                        return
                    }
                }
            }.catch {
                err in
                DDLogError("Unable to fetch devices: \(String(reflecting: err))")
        }
        
    }
    
    private func stopEventStream() {
        metricHelper = nil
        eventStream.stop()
        connectionState = .unloaded
        for entry in _deviceRegistry {
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
    
    fileprivate func registerDevice(_ device: DeviceModel) -> Promise<DeviceModel> {
        addOrReplace(peripheral: device)
        return Promise(value: device)
    }
    
    fileprivate func removeDevice(_ deviceId: String?) {
        
        guard let deviceId = deviceId else { return }
        
        if let d = _deviceRegistry.removeValue(forKey: deviceId) {
            d.deleted = true
            contentsSink.send(value: .delete(d))
        }
        
    }
    
    // MARK: - EventStream Observation
    
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
    
    // MARK: Stream event handlers
    
    /// Handle a DeviceStreamEvent.
    /// - parameter event: The event to handle
    
    fileprivate func handleEvent(_ event: DeviceStreamEvent) {
        
        DDLogVerbose(String(format: "DeviceCollection got event: %@", String(reflecting: event)), tag: TAG)
        
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
            
            guard let invalidation = InvalidationEvent(kind: eventName, info: data) else {
                DDLogWarn("Unrecognized invalidation event kind \(eventName); ignoring.", tag: TAG)
                break
            }
            
            onInvalidate(maybePeripheralId: maybePeripheralId, event: invalidation, seq: seq)
            
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
        
        let currentDeviceIds = Set(_deviceRegistry.keys)
        
        let deviceIdsToKeep = Set(peripherals.map { $0.id })
        let deviceIdsToRemove = currentDeviceIds.subtracting(deviceIdsToKeep)
        
        notifyBeginUpdates()
            .then {
                () -> BulkCreateOrUpdateDeviceResult in
                
                deviceIdsToRemove.forEach {
                    [weak self] deviceId in asyncMain {
                        self?.removeDevice(deviceId)
                    }
                }
                let peripheralsToKeep = peripherals.filter { deviceIdsToKeep.contains($0.id) }
                return self.createOrUpdateDevices(with: peripheralsToKeep, notifyBegin: false, notifyEnd: true)
                
            }.then {
                _ -> Void in
                
                self.connectionState = .loaded
                
                //let coldStartupTime = MetricHelper.sharedInstance.coldStartUpTime
                if let wakeupTime = self.metricHelper.wakeUpTime {
                    DDLogInfo("wakup complete in \(wakeupTime)ms")
                    
                    let metric: DeviceEventStreamable.Metrics = [
                        "name": "WakeupTime",
                        "platform": "ios",
                        "deviceId": self.eventStream.clientId,
                        "elapsed": wakeupTime,
                        "success": true
                    ]
                    
                    self.metricHelper.addMetric(metric, forMetricType: "application")
                    self.metricHelper.reportMetrics()
                }
        }
        
    }
    
    fileprivate func handleCreateOrUpdateDeviceResult(_ maybeDevice: DeviceModel?, _ created: Bool) {
        
        if created {
            guard let device = maybeDevice else {
                let msg = "Expected a device, since we created it."
                assert(false, msg)
                DDLogError(msg)
                return
            }
            postAddedVisibleDeviceNotification()
            contentsSink?.send(value: .create(device))
        }
        
    }
    
    /// If necessary, create a device with the given deviceId and profileId.
    ///
    /// - parameter deviceId: The `id` of the device.
    /// - parameter profileId: The `id` of the device's profile.
    /// - returns: `true` if the device was created, `false` if not (device already existed)
    
    fileprivate func createDeviceIfNecessary(with deviceId: String, profileId: String) -> Promise<(device: DeviceModel, created: Bool)> {
        
        if let ret = _deviceRegistry[deviceId] {
            return Promise(value: (ret, false))
        }
        
        let ret = DeviceModel(
            deviceId: deviceId,
            accountId: accountId,
            associationId: nil,
            profileId: profileId,
            attributes: [:],
            deviceCloudSupporting: self,
            profileSource: profileSource
        )
        
        ret.shouldAttemptAutomaticUTCMigration = true
        return registerDevice(ret).then {
            (device: $0, created: true)
        }
        
    }
    
    fileprivate func notifyBeginUpdates() -> Promise<Void> {
        contentsSink.send(value: .beginUpdates)
        return Promise()
    }
    
    fileprivate func notifyEndUpdates(results: [BulkCreateOrUpdateDeviceResultValue]) -> BulkCreateOrUpdateDeviceResult {
        contentsSink.send(value: .endUpdates)
        return Promise(value: results)
    }
    
    typealias BulkCreateOrUpdateDeviceResultValue = PromiseKit.Result<CreateOrUpdateDeviceResultValue>
    typealias BulkCreateOrUpdateDeviceResult = Promise<[BulkCreateOrUpdateDeviceResultValue]>
    
    fileprivate func createOrUpdateDevices<P: Sequence>(
        with peripherals: P,
        notifyBegin: Bool = false,
        notifyEnd: Bool = true
        ) -> BulkCreateOrUpdateDeviceResult
        where
        P.Element == DeviceStreamEvent.Peripheral
    {
        return (notifyBegin ?
            notifyBeginUpdates()
            : Promise()
            ).then {
                when(resolved: peripherals.map {
                    self.createOrUpdateDevice(with: $0)
                        .then {
                            result -> CreateOrUpdateDeviceResultValue in
                            self.handleCreateOrUpdateDeviceResult(result.device, result.created)
                            return result
                    }
                })
            }.then {
                results -> BulkCreateOrUpdateDeviceResult in
                return notifyEnd ?
                    self.notifyEndUpdates(results: results)
                    : Promise(value: results)
        }
    }

    
    fileprivate func createOrUpdateDevices<J: Sequence>(
        with jsonElements: J,
        notifyBegin: Bool = true,
        notifyEnd: Bool = true
        ) -> BulkCreateOrUpdateDeviceResult
        where
        J.Element == [String: Any]
    {
        
        return (notifyBegin ?
            notifyBeginUpdates()
            : Promise()
            ).then {
                when(resolved: jsonElements.map {
                    self.createOrUpdateDevice(with: $0)
                        .then {
                            result -> CreateOrUpdateDeviceResultValue in
                            self.handleCreateOrUpdateDeviceResult(result.device, result.created)
                            return result
                    }
                })
            }.then {
                results -> BulkCreateOrUpdateDeviceResult in
                return notifyEnd ?
                    self.notifyEndUpdates(results: results)
                    : Promise(value: results)
        }

        
    }
    
    typealias CreateOrUpdateDeviceResultValue = (device: DeviceModel?, created: Bool)
    typealias CreateOrUpdateDeviceResult = Promise<CreateOrUpdateDeviceResultValue>
    
    fileprivate func createOrUpdateDevice(with json: [String: Any]) -> CreateOrUpdateDeviceResult {
        
        guard
            let deviceId = json["deviceId"] as? String,
            let profileId = json["profileId"] as? String else {
                DDLogError("No deviceId in json; bailing create.", tag: TAG)
                return Promise(value: (nil, false))
        }
        
        if !profileSource.containsProfile(for: profileId),
            let profile: DeviceProfile = |<(json["profile"] as? [String: Any]) {
            profileSource.add(profile: profile)
        }
        
        return createDeviceIfNecessary(with: deviceId, profileId: profileId)
            .then {
                maybeDevice, created in
                
                self.updateDevice(with: json)
                    .then {
                        maybeDevice -> CreateOrUpdateDeviceResultValue in
                        
                        assert(maybeDevice != nil, "Expected maybeDevice not to be nil, since we just created it.")
                        
                        guard let device = maybeDevice else {
                            let msg = "Expected maybeDevice not to be nil, since we just created it."
                            DDLogError(msg, tag: self.TAG)
                            throw msg
                        }
                        
                        return (device, created)
                }
                
        }
        
        
    }
    
    /// Create a device, from the given peripheral struct instance.
    ///
    /// - parameter peripheral: The peripheral for which the device should be created.
    /// - parameter seq: The sequence number of the event stream message, if any.
    /// - note: sequence numbers are currently ignored.
    
    fileprivate func createOrUpdateDevice(with peripheral: DeviceStreamEvent.Peripheral, seq: DeviceStreamEventSeq? = nil) -> CreateOrUpdateDeviceResult {
        
        let deviceId = peripheral.id
        
        return createDeviceIfNecessary(with: deviceId, profileId: peripheral.profileId)
            .then {
                maybeDevice, created in
                
                self.updateDevice(with: peripheral)
                    .then {
                        maybeDevice -> CreateOrUpdateDeviceResultValue in
                        assert(maybeDevice != nil, "Expected maybeDevice not to be nil, since we just created it.")
                        
                        guard let device = maybeDevice else {
                            let msg = "Expected maybeDevice not to be nil, since we just created it."
                            DDLogError(msg, tag: self.TAG)
                            throw msg
                        }
                        
                        return (device, created)
                }
                
        }
        
        
    }
    
    typealias UpdateDeviceResult = Promise<DeviceModel?>
    
    fileprivate func updateDevice(with json: [String: Any]) -> UpdateDeviceResult {
        
        let tag = TAG
        
        guard
            let deviceId = json["deviceId"] as? String,
            let device = _deviceRegistry[deviceId] else {
                DDLogWarn("No deviceId or device; bailing", tag: tag)
                return Promise(value: nil)
        }
        
        guard
            let profileId = json["profileId"] as? String,
            let modelState: DeviceModelState = |<(json["deviceState"] as? [String: Any]),
            let attributes = json["attributes"] as? [[String: Any]] else {
                let msg = "Cannot decode device from \(String(reflecting: json)); bailing"
                DDLogError(msg, tag: tag)
                return Promise(error: msg)
        }
        
        if let timeZoneState: TimeZoneState = |<(json["timezone"] as? [String: Any]) {
            device.timeZoneState = timeZoneState
        }
        
        device.associationId = json["associationId"] as? String
        device.friendlyName = json["friendlyName"] as? String
        device.currentState.connectionState = modelState
        device.profileId = profileId
        
        if let tags: [DeviceTagCollection.DeviceTag.Model] = |<(json["deviceTags"] as? [[String: Any]]) {
            device.deviceTags = Set(tags.map { return DeviceTagCollection.DeviceTag(model: $0) } )
        }
        
        return Promise {
            
            fulfill, reject in
            
            device.updateProfile {
                
                [weak device] updateProfileSuccess, maybeError in
                
                guard updateProfileSuccess else {
                    var msg = "Unable to update profile for device."
                    
                    if let error = maybeError {
                        msg = "\(msg) Error: \(String(reflecting: error))"
                    }
                    
                    DDLogError(msg, tag: tag)
                    reject(msg)
                    return
                }
                
                guard let device = device else {
                    DDLogDebug(String(format: "Device %@ has already been reaped; bailing.", deviceId), tag: tag)
                    fulfill(nil)
                    return
                }
                
                device.update(with: attributes)
                fulfill(device)
            }
        }
        
        
        
    }
    
    fileprivate func updateDevice(with peripheral: DeviceStreamEvent.Peripheral) -> UpdateDeviceResult {
        
        let tag = TAG
        
        guard let device = _deviceRegistry[peripheral.id] else {
            DDLogWarn("No device \(peripheral.id); bailing", tag: tag)
            return Promise(value: nil)
        }
        
        device.deviceTags = Set(peripheral.deviceTags)
        
        return Promise {
            fulfill, reject in
            
            device.updateProfile {
                
                [weak device] updateProfileSuccess, maybeError in
                
                guard updateProfileSuccess else {
                    var msg = "Unable to update profile for device."
                    
                    if let error = maybeError {
                        msg = "\(msg) Error: \(String(reflecting: error))"
                    }
                    
                    DDLogError(msg, tag: tag)
                    reject(msg)
                    return
                }
                
                guard let device = device else {
                    DDLogDebug(String(format: "Device %@ has already been reaped; bailing.", peripheral.id), tag: tag)
                    return
                }
                
                device.update(with: peripheral)
                fulfill(device)
                
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
        
        var state = device.currentState
        state.connectionState.update(with: status)
        device.currentState = state
        
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
    
    fileprivate func onInvalidate(maybePeripheralId: String?, event: InvalidationEvent, seq: DeviceStreamEventSeq?) {
        
        guard
            let peripheralId = maybePeripheralId,
            let device = peripheral(for: peripheralId) else { return }
        
        switch event.kind {
            
        case .profiles:
            device.profileId = nil
            
        case .location:
            updateLocation(for: peripheralId, retryInterval: 10.0)
            
        case .timezone:
            updateTimeZoneState(for: peripheralId, retryInterval: 10.0)
            
        case .tags:
            
            guard let info = event.info else {
                let msg = "Got tags invalidation for \(peripheralId):\(String(reflecting: event)), but no info."
                DDLogWarn(msg, tag: TAG)
                assert(false, msg)
                return
            }
            
            applyTagUpdate(for: peripheralId, info: info)
            
        default:
            break
            
        }
    }
    
    /// Update the location for the given peripheral id, optionally retrying upon failure.
    ///
    /// - parameter peripheralId: The id of the peripheral whose `locationState` should be updated.
    /// - parameter retryInterval: If non-`nil`, retry upon failure after `retryInterval` seconds.
    ///                            If `nil`, do not retry.
    
    func updateLocation(for peripheralId: String, retryInterval: TimeInterval? = nil) {
        
        guard let peripheral = peripheral(for: peripheralId) else { return }
        
        guard peripheral.locationState != .pendingUpdate else {
            DDLogDebug("We already have a location pending, not trying again.")
            return
        }
        
        peripheral.locationState = .pendingUpdate
        
        _ = apiClient.getLocation(for: peripheralId, in: accountId)
            .then {
                
                [weak peripheral] maybeLocation -> Void in
                switch maybeLocation {
                case let .some(location):
                    peripheral?.locationState = .located(at: location)
                case .none:
                    peripheral?.locationState = .notLocated
                }
                
            }.catch {
                
                [weak peripheral] error in
                
                DDLogError("Error updating location for \(peripheralId): \(String(reflecting: error))", tag: self.TAG)
                peripheral?.locationState = .invalid(error: error)
                
                guard let retryInterval = retryInterval else {
                    DDLogDebug("Location update for \(peripheralId) failed; not retrying.", tag: self.TAG)
                    return
                }
                
                DDLogInfo("Retrying location update for \(peripheralId) in \(retryInterval) secs.", tag: self.TAG)
                
                after(retryInterval) {
                    [weak self] in self?.updateLocation(for: peripheralId)
                }
            }.always {
                [weak peripheral] in
                DDLogDebug("After locationState update of \(peripheralId): \(String(reflecting: peripheral))", tag: self.TAG)
        }
        
    }
    
    /// Update the timeZoneState for the given peripheral id, optionally retrying upon failure.
    ///
    /// - parameter peripheralId: The id of the peripheral whose `timeZoneState` should be updated.
    /// - parameter retryInterval: If non-`nil`, retry upon failure after `retryInterval` seconds.
    ///                            If `nil`, do not retry.
    func updateTimeZoneState(for peripheralId: String, retryInterval: TimeInterval? = nil) {
        
        guard let peripheral = peripheral(for: peripheralId) else { return }
        
        guard peripheral.timeZoneState != .pendingUpdate else {
            DDLogDebug("We already have a timezone update pending, not trying again.")
            return
        }
        
        peripheral.timeZoneState = .pendingUpdate
        
        _ = apiClient.getTimeZone(for: peripheralId, in: accountId)
            .then {
                [weak peripheral] timeZoneState -> Void in
                peripheral?.timeZoneState = timeZoneState
            }.catch {
                
                [weak peripheral] error in
                
                DDLogError("Error updating timeZoneState for \(peripheralId): \(String(reflecting: error))", tag: self.TAG)
                peripheral?.timeZoneState = .invalid(error: error)
                
                guard let retryInterval = retryInterval else {
                    DDLogDebug("TimeZoneState update for \(peripheralId) failed; not retrying.", tag: self.TAG)
                    return
                }
                
                DDLogInfo("Retrying timeZoneState update for \(peripheralId) in \(retryInterval) secs.", tag: self.TAG)
                
                after(retryInterval) {
                    [weak self] in self?.updateTimeZoneState(for: peripheralId)
                }
            }.always {
                [weak peripheral] in
                DDLogDebug("After timeZoneState update of \(peripheralId): \(String(reflecting: peripheral))", tag: self.TAG)
        }
        
    }
    
    func applyTagUpdate(for peripheralId: String, info: InvalidationEvent.EventInfo) {
        
        guard let peripheral = peripheral(for: peripheralId) else {
            DDLogWarn("No peripheral found for id \(peripheralId); ignoring tag update \(String(reflecting: info))", tag: TAG)
            return
        }
        
        enum TagAction: String {
            case add = "ADD"
            case update = "UPDATE"
            case delete = "DELETE"
        }
        
        guard
            let actionName = info["deviceTagAction"] as? TagAction.RawValue,
            let action = TagAction(rawValue: actionName) else {
                DDLogWarn("No tag action found in \(String(reflecting: info))", tag: TAG)
                return
        }
        
        switch action {
        case .add: fallthrough
        case .update:
            guard let deviceTag: DeviceModelable.DeviceTag.Model = |<info["deviceTag"] else {
                DDLogWarn("Unable to decode tag from \(String(describing: info))", tag: TAG)
                return
            }
            peripheral._addOrUpdate(tag: DeviceModelable.DeviceTag(model: deviceTag))
            
        case .delete:
            guard
                let deviceTag: DeviceModelable.DeviceTag.Model = |<info["deviceTag"],
                let deviceTagId = deviceTag.id else {
                    DDLogWarn("Unable to decode tag from \(String(describing: info))", tag: TAG)
                    return
            }
            peripheral._removeTag(with: deviceTagId)
        }
        
    }
    
    // MARK: - Public Stream Controls
    
    public func refresh() {
        stop()
        start()
    }
    
    // MARK: - Public stream controls
    
    private var shouldBeRunning: Bool = false {
        didSet {
            if shouldBeRunning {
                registerForAppStateNotifications()
                return
            }
            unregisterFromAppStateNotifications()
        }
    }
    
    public func start() {
        shouldBeRunning = true
        startEventStream()
    }
    
    public func stop() {
        shouldBeRunning = false
        stopEventStream()
    }
    
    public func reset() {
        eventStream.stop()
        
        let sink = contentsSink
        let devices = _allDevices
        
        _deviceRegistry.removeAll(keepingCapacity: true)
        
        for device in devices {
            sink?.send(value: .delete(device))
        }
        
        profileSource.reset()
        self.connectionState = .unloaded
    }
    
    // MARK: underlying store abstraction
    
    /// Get a peripheral for the given id, if available.
    public func peripheral(for id: String) -> DeviceModel? {
        guard let device = _deviceRegistry[id], let _ = device.profile else {
            return nil
        }
        return device
    }
    
    func addOrReplace(peripheral: DeviceModel) {
        let shouldPostNonemptyNotification = _deviceRegistry.count == 0
        _deviceRegistry[peripheral.deviceId] = peripheral
        if shouldPostNonemptyNotification {
            postNonemptyNotification()
        }
    }
    
    func removePeripheral(for id: String) {
        _deviceRegistry.removeValue(forKey: id)
    }
    
    // MARK: App State Observation
    
    func registerForAppStateNotifications() {
        
        #if os(iOS) || os(tvOS)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleEnteredBackgroundNotification),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleEnteredForegroundNotification),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        #endif
        
    }
    
    func unregisterFromAppStateNotifications() {
        #if os(iOS)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        #endif
    }
    
    @objc func handleEnteredBackgroundNotification() {
        DDLogInfo("Notified entered background", tag: TAG)
        stopEventStream()
    }
    
    @objc func handleEnteredForegroundNotification() {
        DDLogInfo("Notified entered foreground", tag: TAG)
        startEventStream()
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

public extension DeviceCollection {
    
    typealias AddDeviceOnDone = (DeviceModel?, Error?) -> Void
    
    /// Add a device to the device collection.
    ///
    /// - parameter associationId: The associationId for the device. Note that this is different from the deviceId.
    /// - parameter location: The location, if any, to associate with the device.
    /// - parameter isOwnershipChangeVerified: If the device is eligible for ownership change (see note), and
    ///                                        `isOwnershipChangeVerified` is `true`, then the device being scanned
    ///                                        will be disassociated from its existing account prior to being
    ///                                        associated with the new one.
    /// - parameter timeZone: The timezone to use for the device. Defaults to `TimeZone.current`.
    /// - parameter timeZoneIsUserOverride: If true, indicates the user has explicitly set the timezone
    ///                             on this device (rather than it being inferred by location).
    ///                             If false, timeZone is the default timeZone of the phone.
    /// - parameter onDone: The completion handler for the call.
    ///
    /// ## Ownership Transfer
    /// Some devices are provisioned to have their ownership transfer automatically. If upon an associate attempt
    /// with `isOwnershipTransferVerified == false` is made upon a device that's assocaiated with another account,
    /// and an error is returned with an attached URLResponse with header `transfer-verification-enabled: true`,
    /// then the call can be retried with `isOwnershipTranferVerified == true`, and the service will disassociate
    /// said device from its existing account prior to associating it with the new account.
    
    func addDevice(with associationId: String, location: CLLocation? = nil, isOwnershipChangeVerified: Bool = false, timeZone: TimeZone = TimeZone.current, timeZoneIsUserOverride: Bool = false, onDone: @escaping AddDeviceOnDone) {
        
        apiClient.associateDevice(
            with: associationId,
            to: accountId,
            locatedAt: location,
            ownershipTransferVerified: isOwnershipChangeVerified
            ).then {
                
                (deviceJson: [String: Any]) -> Void in
                
                self.createOrUpdateDevice(with: deviceJson).then {
                    
                    maybeDevice, created -> Void in
                    guard let deviceModel = maybeDevice else {
                        onDone(nil, "No deviceModel returned.")
                        return
                    }
                    
                    _ = self.apiClient
                        .setTimeZone(
                            as: timeZone,
                            isUserOverride: timeZoneIsUserOverride,
                            for: deviceModel.deviceId,
                            in: self.accountId
                        ).then {
                            _ -> Void in
                            self.handleCreateOrUpdateDeviceResult(maybeDevice, created)
                            onDone(deviceModel, nil)
                        }.catch {
                            err in
                            onDone(deviceModel, err)
                    }
                }
                
            }.catch {
                err in onDone(nil, err)
        }
    }
    
    typealias RemoveDeviceOnDone = (String?, Error?) -> Void
    
    /// Remove a device from the collection.
    ///
    /// This call results in a disassociate being called against the Afero service.
    /// - parameter deviceId: The id of the device to remove.
    /// - parameter onDone: The completion handler for the call.
    
    func removeDevice(with deviceId: String, onDone: @escaping RemoveDeviceOnDone) {
        apiClient.removeDevice(with: deviceId, in: accountId).then {
            ()->Void in
            self.removeDevice(deviceId)
            onDone(deviceId, nil)
            }.catch {
                err in
                onDone(nil, err)
        }
    }
    
}

extension DeviceStreamEvent.Peripheral {
    var deviceTags: [DeviceTagCollection.DeviceTag] {
        return tags.map { DeviceTagCollection.DeviceTag(model: $0) }
    }
}

// MARK: - Deprecations -

extension DeviceCollection {
    
    @available(*, renamed: "ContentEvent")
    public typealias ContentsChange = ContentEvent
    
    @available(*, deprecated, renamed: "ConnectionState")
    public typealias State = ConnectionState
    
    @available(*, deprecated, renamed: "connectionStateSignal")
    public var stateSignal: Signal<ConnectionState, Never>! { return connectionStateSignal }
    
    @available(*, deprecated, renamed: "connectionState")
    public var state: ConnectionState { return connectionState }
    
    @available(*, deprecated, message: "Public access to `allDevices` is deprecated; use `devices` instead.")
    public var allDevices: [DeviceModel] { return _allDevices }
    
    @available(*, deprecated, renamed: "devices")
    public var visibleDevices: [DeviceModel] { return devices }
    
}

