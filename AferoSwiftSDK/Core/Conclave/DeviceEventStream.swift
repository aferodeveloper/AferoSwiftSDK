//
//  DeviceEventStream.swift
//  iTokui
//
//  Created by Tony Myles on 11/26/14.
//  Copyright (c) 2014-2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import CocoaLumberjack

public typealias DeviceStreamEventName = String
public typealias DeviceStreamEventData = [String: Any]
public typealias DeviceStreamEventSeq = Int
public typealias DeviceStreamEventTarget = String
public typealias DeviceStreamEventTimestamp = NSNumber

public typealias DeviceStreamEventSignal = Signal<DeviceStreamEvent, NSError>
public typealias DeviceStreamEventSink = Observer<DeviceStreamEvent, NSError>
public typealias DeviceStreamEventPipe = (DeviceStreamEventSignal, DeviceStreamEventSink)

protocol DeviceEventStreamable: class, CustomDebugStringConvertible {
    
    var TAG: String { get }
    var clientId: String { get }
    var accountId: String { get }
    var eventSignal: DeviceStreamEventSignal? { get }
    func start(_ trace: Bool, onDone: @escaping (Error?)->())
    func stop()
    func publishDeviceListRequest()
    func publishIsViewingNotification(_ isViewing: Bool, deviceId: String)
    //    func addMetric(_ metric: [String : Any], forMetricType metricType: String)
    
    typealias Metrics = [String: Any]
    func publish(metrics: Metrics)
}

extension DeviceEventStreamable {
    
    var TAG: String { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }
    
    var debugDescription: String {
        return "<\(TAG)> accountId:\(accountId) clientId:\(clientId) "
    }

}

// MARK: - ConclaveDeviceEventStream

class ConclaveDeviceEventStream: DeviceEventStreamable, CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "<\(TAG)> accountId:\(accountId) clientType:\(String(describing: clientType)) clientVersion:\(String(describing: clientVersion)) access: \(conclaveAccess.debugDescription) token: \(conclaveAccessToken.debugDescription) client:\(conclaveClient.debugDescription)"
    }
    
    /// The object responsible for handling Conclave authentication.
    fileprivate(set) var conclaveAuthable: ConclaveAuthable
    
    /// The `type` string passed through to Conclave on `.Login` messages.
    var clientType: String? { return conclaveAuthable.conclaveClientType }
    
    /// The `version` string passed through to Conclave on .Login` messages.
    var clientVersion: String? { return conclaveAuthable.conclaveClientVersion }
    
    /// The `mobileDeviceId` string passed through to Conclave `.Login` messages, for.
    fileprivate(set) public var clientId: String
    
    /// The `accountId` this for which this `DeviceEventStream` should attempt to connect to
    /// Conclave. This will usually, but _may not_, be the same as the `channelId`.
    fileprivate(set) public var accountId: String
    
    fileprivate(set) var userId: String
    
    /// The `ConclaveAccess` info currently being used. `nil` if not connected.
    fileprivate(set) var conclaveAccess: ConclaveAccess? = nil
    
    /// The curent Conclave connection token being used. `nil` if not connected.
    var conclaveAccessToken: ConclaveAccess.Token? {
        return conclaveAccess?.token
    }
    
    var host: ConclaveHost? {
        return conclaveAccess?.conclaveHosts.hostsForType("socket").first
    }
    
    /// The current host being used by this connection. `nil` if not connected.
    open var hostName: String? { return host?.host }
    
    /// The current port being used by this connection. `nil` if not connected.
    /// At the moment this forces `JSONPlaintext` regardless of what the any current
    /// non-nil `conclaveAccess` value reports.
    
    open var port: ConclaveHost.Port? {
        return host?.port
    }
    
    open var encrypted: Bool? {
        return host?.encrypted
    }
    
    open var compressed: Bool? {
        return host?.compressed
    }
    
    /// The current channelId being used by this connection. `nil` if not connected.
    open var channelId: String? { return conclaveAccessToken?.channelId }
    
    public init(authable: ConclaveAuthable, accountId: String, userId: String, clientId: String) {
        self.conclaveAuthable = authable
        self.accountId = accountId
        self.userId = userId
        self.clientId = clientId
    }
    
    // MARK: Conclave Client
    
    lazy fileprivate(set) var conclaveScheduler: QueueScheduler = {
        return QueueScheduler(qos: DispatchQoS.default, name: "io.afero.deviceEventStream")
    }()
    
    fileprivate var conclaveClient: ConclaveClient? = nil {
        
        willSet {
            conclaveClient?.disconnect()
            conclaveClientDisposable = nil
        }
        
        didSet {
            
            guard let conclaveClient = conclaveClient else {
                return
            }
            
            let TAG = self.TAG
            
            conclaveClientDisposable = conclaveClient.eventSignal
                .observe(on: conclaveScheduler)
                .observe {
                    [weak self] event in
                    
                    DDLogVerbose("Got event: \(event)", tag: TAG)
                    
                    switch event {
                    case .failed(let err):
                        self?.handleClientFatalError(err)
                    case .interrupted:
                        self?.handleClientInterrupted()
                    case .value(let conclaveMessage):
                        self?.handleClientNext(conclaveMessage)
                    case .completed:
                        self?.handleClientCompleted()
                    }
            }
        }
    }
    
    fileprivate var conclaveClientDisposable: Disposable? = nil {
        willSet {
            conclaveClientDisposable?.dispose()
        }
    }
    
    // MARK: Connect / reconnect logic
    
    fileprivate func invalidateConnectionTimer() {
        connectTimer = nil
        connectionAttempt = 0
    }
    
    fileprivate var shouldAttemptReconnection = true
    fileprivate var connectionAttempt: Int = 0
    fileprivate var connectionDelay: TimeInterval {
        switch(connectionAttempt) {
        case 0..<10:
            return TimeInterval(pow(Double(connectionAttempt), 2.0) / 5.0)
        default:
            return TimeInterval(20)
        }
    }
    
    fileprivate var connectTimer: Timer? {
        willSet { connectTimer?.invalidate() }
    }
    
    fileprivate func scheduleConnect(_ trace: Bool = false, onConnect: @escaping (Error?)->Void) {
        
        DDLogInfo("Connection attempt \(connectionAttempt) scheduling connect in \(connectionDelay) secs.", tag: TAG)
        
        let localOnConnect: (Error?)->Void = {
            [weak self] maybeError in
            if let _ = maybeError {
                self?.scheduleConnect(trace, onConnect: onConnect)
                return
            }
            onConnect(maybeError)
        }
        
        self.connectTimer = Timer.schedule(delay: connectionDelay) {
            [weak self] timer in
            self?.connectTimer = nil
            self?.connect(trace, onDone: localOnConnect)
        }
        connectionAttempt += 1
        
    }
    
    fileprivate func bringUp(_ conclaveAccess: ConclaveAccess, trace: Bool = false, onDone: (Error?)->Void) {
        
        DDLogDebug("Bringing up conclave with access: \(conclaveAccess) accountId: \(accountId)", tag: TAG)
        
        self.conclaveAccess = conclaveAccess
        
        guard let
            connectionToken = conclaveAccessToken,
            let clientType = clientType else {
                self.conclaveAccess = nil
                let msg = "Missing conclaveAccessToken; bailing."
                DDLogWarn(msg, tag: TAG)
                let error = NSError(domain: "ConclaveDeviceEventStream", code: -1, localizedDescription: msg)
                state = .disconnected
                onDone(error)
                return
        }
        
        let conclaveClient = ConclaveClient(
            token: connectionToken,
            type: clientType,
            deviceId: nil,
            mobileDeviceId: clientId,
            version: clientVersion,
            trace: trace
        )
        
        guard let
            host = hostName,
            let port = port,
            let encrypted = encrypted,
            let compressed = compressed else {
                let msg = "Missing Conclave host and/or port! Bailing."
                DDLogWarn(msg, tag: TAG)
                let error = NSError(domain: "ConclaveDeviceEventStream", code: -2, localizedDescription: msg)
                state = .disconnected
                onDone(error)
                return
        }
        
        let conclaveConnection = ConclaveSocketConnection(
            host: host,
            port: port,
            encrypted: encrypted,
            compressed: compressed
        )
        
        self.conclaveClient = conclaveClient
        
        do {
            try self.conclaveClient?.connect(conclaveConnection)
            onDone(nil)
        } catch {
            onDone(error)
        }
        
    }
    
    fileprivate func tearDown() {
        invalidateConnectionTimer()
        shouldAttemptReconnection = false
        conclaveClient = nil
        conclaveAccess = nil
        state = .disconnected
    }
    
    enum State {
        case disconnected
        case connecting
        case connected
    }
    
    fileprivate(set) var state: State = .disconnected {
        didSet {
            DDLogDebug("Transitioned from \(oldValue) to \(state)", tag: TAG)
        }
    }
    
    fileprivate func connect(_ trace: Bool = false, onDone: @escaping (Error?)->()) {
        
        if state != .disconnected {
            DDLogDebug("state: \(state); ignoring redundant connection request", tag: TAG)
            return
        }
        
        state = .connecting
        
        let tag = TAG
        
        conclaveAuthable.authConclave(accountId: accountId) {
            [weak self] maybeInfo, maybeError in asyncMain {
                switch (maybeInfo, maybeError) {
                    
                case let (.some(access), .none):
                    DDLogInfo("Successfully authed to conclave; bringin 'er up.", tag: tag)
                    self?.bringUp(access, trace: trace, onDone: onDone)
                    
                case let (.none, .some(error)):
                    DDLogError("ERROR: Failed to auth to conclave: \(error.localizedDescription)", tag: tag)
                    self?.state = .disconnected
                    onDone(error)
                    
                default:
                    fatalError("Expected either conclaveAccess or an error; got \(maybeInfo, maybeError)")
                    
                }
            }
        }
    }
    
    // MARK: Client event handling
    
    fileprivate func handleClientCompleted() {
        DDLogInfo("Got client completed.", tag: TAG)
        // NOTE: Reconnect attempts will be handled through state changes
    }
    
    fileprivate func handleClientInterrupted() {
        // NOTE: Reconnect attempts will be handled through state changes
        DDLogWarn("Got client interrupted.", tag: TAG)
    }
    
    fileprivate func handleClientFatalError(_ error: Error?) {
        // NOTE: Reconnect attempts will be handled through state changes
        let tag = TAG
        DDLogError("Got client error: \(String(describing: error))", tag: tag)
        scheduleConnect {
            DDLogWarn("Connection attempt failed (\(String(describing: $0))); will retry.", tag: tag)
        }
    }
    
    fileprivate func handleClientNext(_ event: ConclaveClient.ClientEvent) {
        switch (event) {
            
        case let .data(event, data, seq, target):
            DDLogVerbose("Got event: \(event) seq: \(String(describing: seq)) target: \(String(describing: target)) data: \(data)", tag: TAG)
            handleDataEvent(event, seq: seq, target: target, data: data)
            
        case let .stateChange(newState):
            DDLogVerbose("Got new client state: \(newState)", tag: TAG)
            handleStateEvent(newState)
            break
            
        case let .transientError(error):
            handleTransientErrorEvent(error)
            break
        }
    }
    
    // MARK: Errors
    
    fileprivate func handleTransientErrorEvent(_ error: Error?) {
        DDLogWarn("Conclave transient error: \(String(describing: error))", tag: TAG)
    }
    
    // MARK: Data Events
    
    fileprivate func handleDataEvent(_ eventName: DeviceStreamEventName, seq: DeviceStreamEventSeq?, target: DeviceStreamEventTarget?, data: DeviceStreamEventData) {
        
        /// Intercept invalidate messages here, as they don't have anything to do with devices.
        
        if eventName == "invalidate" {
            
            guard
                let kindName = data["kind"] as? InvalidationEvent.Kind.RawValue,
                let kind = InvalidationEvent.Kind(rawValue: kindName) else {
                    return
            }
            
            handleInvalidation(InvalidationEvent(kind: kind, info: data["data"] as? InvalidationEvent.EventInfo))
        }
        
        guard let event = DeviceStreamEvent(name: eventName, seq: seq, data: data, target: target) else {
            DDLogError("Unrecognized DeviceStreamEvent name: \(eventName) seq: \(String(describing: seq)) sender: \(String(describing: target)) data: \(data)")
            return
        }
        
        eventSink.send(value: event)
    }
    
    // MARK: Account Invalidations
    
    fileprivate func handleInvalidation(_ event: InvalidationEvent?) {

        guard
            let name = event?.kind.notificationName else { return }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: self, userInfo: event?.info)
    }
    
    // MARK: Client State
    
    fileprivate func handleStateEvent(_ newState: ConnectionState) {
        
        asyncMain {
            [weak self] in switch(newState) {
                
            case .disconnected:
                self?.state = .disconnected
                self?.scheduleConnect {
                    if let
                        error = $0,
                        let sink = self?.eventSink {
                        sink.send(error: error as NSError)
                    }
                }
                
            case .connected:
                self?.state = .connected
                self?.connectionAttempt = 0
                
            case .connecting:
                self?.state = .connecting
                break
            }
        }
        
    }
    
    // MARK: Outbound Message Handling
    
    fileprivate var serverBoundQueue: [ConclaveMessage] = []
    
    fileprivate func flush() {
        
        guard let conclaveClient = conclaveClient else {
            DDLogWarn("flush() called before client initialized; bailing.", tag: TAG)
            return
        }
        
        if conclaveClient.connectionState != .connected {
            DDLogWarn("flush() called when in connection state \(conclaveClient.connectionState); bailing.", tag: TAG)
            return
        }
        
        let messages = self.serverBoundQueue
        
        self.serverBoundQueue.removeAll(keepingCapacity: false)
        
        for message in messages {
            publish(message)
        }
    }
    
    fileprivate func publish(_ message: ConclaveMessage) {
        if let sink = conclaveClient?.messageSink {
            DDLogVerbose("Publishing message: \(message)", tag: TAG)
            sink.send(value: message)
        }
    }
    
    fileprivate func enqueue(_ message: ConclaveMessage) {
        self.serverBoundQueue.append(message)
        flush()
    }
    
    lazy fileprivate var eventPipe: DeviceStreamEventPipe = {
        return Signal.pipe()
    }()
    
    fileprivate var eventSink: DeviceStreamEventSink {
        return eventPipe.1
    }
    
    // MARK: <DeviceEventStreamable>
    // MARK: .. Signals
    
    open var eventSignal: DeviceStreamEventSignal? {
        return eventPipe.0
    }
    
    open func start(_ trace: Bool = false, onDone: @escaping (Error?) -> ()) {
        
        DDLogInfo("Received request to start ConclaveDeviceEventStream \(self)", tag: TAG)
        
        invalidateConnectionTimer()
        shouldAttemptReconnection = true
        
        scheduleConnect(trace) {
            [TAG] in if let error = $0 {
                DDLogError("Conclave connection attempt: \(error.localizedDescription)", tag: TAG)
            }
            onDone($0)
        }
    }
    
    // MARK: .. Lifecycle
    
    open func stop() {
        tearDown()
    }
    
    // MARK: .. Messaging
    
    open func publishDeviceListRequest() {
        enqueue(
            ConclaveMessage.say(
                event: "snapshot?",
                data: nil
            )
        )
    }
    
    open func publishIsViewingNotification(_ isViewing: Bool, deviceId: String) {
        
        let payload: [String: Any] = [
            "deviceId": deviceId as Any,
            "viewing": isViewing as Any,
            ]
        
        enqueue(
            ConclaveMessage.say(
                event: "device:view",
                data: payload
            )
        )
    }
    
    open func publish(metrics: DeviceEventStreamable.Metrics) {
        enqueue(
            ConclaveMessage.say(
                event: "metrics",
                data: metrics
            )
        )
    }
    
    
}
