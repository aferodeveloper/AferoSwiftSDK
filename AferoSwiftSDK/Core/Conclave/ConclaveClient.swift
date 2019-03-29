//
//  ConclaveClient.swift
//  iTokui
//
//  Created by Justin Middleton on 6/16/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import CocoaZ

import CocoaLumberjack


// MARK: - ConclaveClient

/// Client state
enum ConnectionState: Int, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch(self) {
        case .disconnected: return "<ConnectionState> .Disconnected"
        case .connecting: return "<ConnectionState> .Connecting"
        case .connected: return "<ConnectionState> .Connected"
        }
    }
    
    case disconnected = 0
    case connecting = 1
    case connected = 2
}

class ConclaveClient: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "<\(TAG)> connectionState: \(connectionState) (connection: \(String(describing: conclaveConnection)))"
    }
    
    fileprivate lazy var TAG: String = { return "\(Swift.type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }()

    static let ConclaveClientErrorDomain = "ConclaveClient"

    /// Emitted errors
    enum Error: Int {
        
        case observerError = -1000 // Unable to observe server
        case connectionErrorRemoteConnectionFailed = -1001 // Unable to connect
        case connectionErrorAlreadyConnected = -1002
        case timeoutWillRetry = -1003
        case timeoutFatal = -1004
        case underlyingConnectionError = -1005
    }
    
    /// Events passed on the eventSignal
    enum ClientEvent: Equatable, CustomDebugStringConvertible {
        
        public var debugDescription: String {
            switch(self) {

            case let .stateChange(newState):
                return "<ConclaveClient.StateChange(\(newState))>"

            case let .transientError(error):
                return "<ConclaveClient.TransientError(\(error))>"

            case let .data(event, data, seq, target):
                return "<ConclaveClient.Data>: event: \(event) seq: \(String(describing: seq)) sender: \(String(describing: target)) data: \(data))"
            }
        }
        
        /// The connection state of the client changed.
        case stateChange(ConnectionState)
        
        /// The client experienced a transient error.
        case transientError(NSError)
        
        /// The client received data.
        case data(event: DeviceStreamEventName, data: DeviceStreamEventData, seq: DeviceStreamEventSeq?, target: DeviceStreamEventTarget?)
        
        // MARK: Equatable
        
        static func ==(lhs: ConclaveClient.ClientEvent, rhs: ConclaveClient.ClientEvent) -> Bool {
            switch (lhs, rhs) {
                
            case let (.stateChange(lstate), .stateChange(rstate)):
                return lstate == rstate
                
            case let (.transientError(lerr), .transientError(rerr)):
                return lerr == rerr
                
            case let (.data(levt, _, lseq, ltarg), .data(revt, _, rseq, rtarg)):
                return levt == revt && lseq == rseq && ltarg == rtarg
                
            default:
                return false
            }
        }

    }
    
    fileprivate(set) var connectionState: ConnectionState = .disconnected {
        
        willSet{
            DDLogInfo("\(self) will transition from state \(connectionState) to \(newValue)", tag: TAG)
        }
        
        didSet {
            if (oldValue == connectionState) {
                return
            }
            DDLogInfo("Connection state update: \(self)", tag: TAG)
            eventSink.send(value: ClientEvent.stateChange(connectionState))
        }
    }
    
    /// The account ID of the channel to join
    open var channelId: String {
        return token.channelId
    }
    
    /// Auth token (currently not used)
    fileprivate(set) var token: ConclaveAccess.Token
    
    /// Agent type (“hub”, “android”, “postmaster”, …)
    fileprivate(set) var type: String
    
    /// The hub’s device ID
    fileprivate(set) var deviceId: String?
    
    /// A client’s unique ID, unused by conclave itself, but reported to other clients
    fileprivate(set) var mobileDeviceId: String?
    
    /// For debugging information only
    fileprivate(set) var version: String?
    
    let `protocol`: Int = 2
    
    /// Tells the Conclave server to turn on extended debugging.
    fileprivate(set) var trace: Bool = false
    
    fileprivate(set) var sessionId: Int? = nil
    
    /**
    Designated initializer.
    
    - parameter accountId: The account ID of the channel to join
    - parameter userId: The user to authenticate as
    - parameter token: Auth token (currently not used)
    - parameter type: Agent type (“hub”, “android”, “postmaster”, …)
    - parameter deviceId: The hub’s device ID
    
    */
    
    init(token: ConclaveAccess.Token, type: String, deviceId: String? = nil, mobileDeviceId: String? = nil, version: String? = nil, trace: Bool = false) {
        self.token = token
        self.type = type
        self.deviceId = deviceId
        self.mobileDeviceId = mobileDeviceId
        self.version = version
        self.trace = trace
    }
    
    deinit {
        tearDown()
    }
    
    func tearDown() {
        cullWatchdog()
        serverReadSignalDisposable?.dispose()
        serverReadSignalDisposable = nil
        messageSink = nil
        conclaveConnection = nil
        connectionState = .disconnected
    }
    
    // Observer Interface
    // "application-level" events are emitted through this interface.
    
    lazy fileprivate var eventPipe: (Signal<ClientEvent, NSError>, Observer<ClientEvent, NSError>) = {
        let ret: (Signal<ClientEvent, NSError>, Observer<ClientEvent, NSError>) = Signal.pipe()
        
        return Signal.pipe()
    }()
    
    var eventSignal: Signal<ClientEvent, NSError> {
        return eventPipe.0
    }
    
    fileprivate var eventSink: Observer<ClientEvent, NSError> {
        return eventPipe.1
    }

    // Server Communication
    // Connection state is handled through this interface
    
    fileprivate(set) var messageSink: ConclaveMessageSink? = nil
    fileprivate var serverReadSignalDisposable: Disposable? = nil

    // MARK: Public
    
    fileprivate(set) var conclaveConnection: ConclaveConnection? = nil
    
    lazy fileprivate(set) var conclaveReadQueueScheduler: QueueScheduler = {
        return QueueScheduler(qos: DispatchQoS.userInitiated, name: "io.afero.conclaveRead")
    }()
    
    /**
    Connect to the associated server. This sets up local sinks and signals, and issues a Connect
    command to the server. 
    
    - parameter connection: A ConclaveConnection instance to use for actual server communications.
    - parameter error: A pointer to an error that will be populated if the connection fails for any reason. The error
                  domain will be the value of `ConclaveClientErrorDomain`, and the code one of `ConclaveError`. Any underlying
                  error will be attached to `userInfo[NSUnderlyingErrorKey]`.
    */
    
    func connect(_ connection: ConclaveConnection) throws {
        
        if connectionState != .disconnected {
            throw NSError(
                domain: Swift.type(of: self).ConclaveClientErrorDomain,
                code: Error.connectionErrorAlreadyConnected.rawValue,
                userInfo: [NSLocalizedDescriptionKey: "Already connected."]
            )
        }
        
        self.conclaveConnection = connection
        connectionState = .connecting
        
        // Set up the server observables

        self.messageSink = connection.writeSink
        if let readSignalDisposable = connection.readSignal
            .observe(on: conclaveReadQueueScheduler)
            .observe({
                [weak self] event in switch event {
                case .failed(let err):
                    self?.handleError(err)
                    
                case .interrupted:
                    self?.handleInterrupted()
                    
                case .value(let msg):
                    self?.handleNext(msg)
                    
                case .completed:
                    self?.handleCompleted()
                }
        }) {
                self.serverReadSignalDisposable = readSignalDisposable
        } else {
            throw NSError(
                domain: Swift.type(of: self).ConclaveClientErrorDomain,
                code: Error.observerError.rawValue,
                userInfo: nil
            )
        }
        
        // Bring up the underlying connection.
        
        do {

            try conclaveConnection!.connect()

        } catch let connectionError as NSError {
            
            var userInfo: [String: AnyObject] = [:]
            userInfo[NSUnderlyingErrorKey] = connectionError
            
            let localError = NSError(
                domain: Swift.type(of: self).ConclaveClientErrorDomain,
                code: Error.connectionErrorRemoteConnectionFailed.rawValue,
                userInfo: userInfo)
            
            connectionState = .disconnected
            self.conclaveConnection = nil
            throw localError
        }
        
    }
    
    /**
    Send the server a "bye", causing it to gracefully disconnect.
    
    - parameter force: If `true`, the connection will be shut down immediately. If false,
                  a "graceful" shutdown (with a `.Bye`) will be executed.
    */
    
    func disconnect(_ force: Bool = false) {

        if (connectionState == .disconnected) {
            return
        }

        assert(messageSink != nil, "writeSink nil in a non-disconnected state")
        
        if (force) {
            handleCompleted()
        }
        
        if let sink = self.messageSink {
            sink.send(value: .bye)
        }
    }
    
    // MARK: Message Handling
    
    /// Sequence number of last seen message
    fileprivate(set) var seqNum: Int = 0
    
    /// Maximum size of outbound message
    fileprivate(set) var bufferSize: Int = 0

    func handleNext(_ next: ConclaveConnectionEvent) {
        
        let t = mach_absolute_time()
        
        asyncMain { [weak self] in self?.resetWatchdog() }
        
        switch(next) {
            
        case .stateChange(let connectionState):
            DDLogInfo("Connection state now: \(connectionState) t:\(t)", tag: TAG)
            break
            
        case .transientError(let error):
            DDLogError("(conclave) \(error.localizedDescription)", tag: TAG)
            break
            
        case .message(let message):
            
            DDLogDebug("TTT t:\(t) Got message: \(message)", tag: TAG)
            
            switch(message) {
                
            case let .hello(_, bufferSize, heartbeat):
                self.heartbeatInterval = TimeInterval(heartbeat)
                self.bufferSize = bufferSize
                
                let loginMessage = ConclaveMessage.login(
                    channelId: channelId,
                    accessToken: token.token,
                    type: type,
                    deviceId: deviceId,
                    mobileDeviceId: mobileDeviceId,
                    version: version,
                    trace: trace,
                    protocol: `protocol`
                )
                
                DDLogDebug("Logging in with \(loginMessage)", tag: TAG)
                
                messageSink!.send(value: loginMessage)
                
            case let .welcome(sessionId, seq, _, _):
                seqNum = seq
                self.sessionId = sessionId
                connectionState = .connected
                
            case .heartbeat:
                handleHeartbeat()
                
            case let .public(seq, _, event, data):
                seqNum = seq
                eventSink.send(value: ClientEvent.data(event: event, data: data, seq: seq, target: nil))
                
            case let .private(seq, _, target, event, data):
                if let seq = seq {
                    seqNum = seq
                }
                eventSink.send(value: ClientEvent.data(event: event, data: data, seq: seq, target: target))
                break
                
            case .join: fallthrough
            case .leave: fallthrough
                
            default:
                break
                
            }
            
        }
        
    }
    
    func handleHeartbeat() {
        DDLogVerbose("Got heartbeat, back atcha.", tag: TAG)
        messageSink!.send(value: ConclaveMessage.heartbeat)
    }

    func handleError(_ error: NSError) {
        DDLogInfo("Got error from server connection: \(error)", tag: TAG)

        let forwardedError = NSError(
            domain: Swift.type(of: self).ConclaveClientErrorDomain,
            code: Error.underlyingConnectionError.rawValue,
            userInfo: [NSUnderlyingErrorKey: error]
        )

        asyncMain {
            [weak self] in
            self?.tearDown()
            guard let sink = self?.eventSink else { return }
            sink.send(error: forwardedError)
        }
        
    }
    
    func handleCompleted() {
        asyncMain {
            [weak self] in
            self?.tearDown()
            guard let sink = self?.eventSink else { return }
            sink.sendCompleted()
        }
    }
    
    func handleInterrupted() {
    }

    // MARK: Watchdog
    
    var watchdog: Timer! = nil
    
    open var heartbeatSlack: UInt = 30 // seconds
    
    fileprivate(set) open var heartbeatInterval: TimeInterval? = nil {
        didSet {
            asyncMain { [weak self] in self?.resetWatchdog() }
        }
    }
    
    func cullWatchdog() {
        watchdog?.invalidate()
        watchdog = nil
    }
    
    func resetWatchdog() {
        watchdog?.invalidate()
        if let heartbeatInterval = heartbeatInterval {
            let delay = heartbeatInterval + TimeInterval(heartbeatSlack)
            DDLogVerbose("Scheduling watchdog to fire in \(delay)", tag: TAG)
            self.watchdog = Timer.schedule(delay: delay) {
                [weak self] timer in self?.watchdogFired()
            }
        }
    }
    
    func sendTransientError(_ error: NSError) {
        eventSink.send(value: ClientEvent.transientError(error))
    }
    
    func watchdogFired() {
        
        DDLogError("conclave watchdog fired!", tag: TAG)

        // For now, just send a fatal timeout.
        
        let localizedDescription = "Conclave client timed out after \(String(describing: heartbeatInterval)) seconds (with \(heartbeatSlack)s slack)"
        
        let userInfo: [AnyHashable: Any] = [NSLocalizedDescriptionKey: localizedDescription]
        let error = NSError(domain: Swift.type(of: self).ConclaveClientErrorDomain, code: Error.timeoutFatal.rawValue, userInfo: (userInfo as? [String : Any]))
        
        DDLogError(error.localizedDescription, tag: TAG)
        
        sendTransientError(error)

        disconnect(true)
    }
    
}

// MARK: - ConclaveConnection

/**
Represents events emitted from a ConclaveConnection. Note that fatal errors are not
emitted in this format, but rather as bare `NSErrors` on appropriate signals.
*/
enum ConclaveConnectionEvent {
    case stateChange(ConnectionState)
    case transientError(NSError)
    case message(ConclaveMessage)
}

/// Type for messages sent to the Conclave server, and consumed by the connection's `writeSink`.
typealias ConclaveMessageSink = Observer<ConclaveMessage, NSError>

/// Type for events received from the Conclave server.
typealias ConclaveReadSignal = Signal<ConclaveConnectionEvent, NSError>

protocol ConclaveConnection {
    
    /// The signal from which ConclaveConnectionEvents are emitted.
    var readSignal: ConclaveReadSignal { get }
    
    /// The sink which consumes ConclaveMessages bound for the server.
    var writeSink: ConclaveMessageSink { get }
    
    /// Connect to the server. Note that the error is only an indication of whether local state
    /// is appropriate for a connection. It is possible for `connect()` to succeed, and soon after
    /// for the connection to fail with an `error` or `completed` event sent on the `readSignal`.
    func connect() throws
    
    /// Tear it down.
    func disconnect()
}

// MARK: - ConclaveStreamConnection

class ConclaveStreamConnection: ConclaveConnection, CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "<ConclaveStreamConnection> connectionState: \(connectionState)"
    }
    
    let TAG = "ConclaveStreamConnection"
    
    fileprivate static let ErrorDomain = "ConclaveStreamConnection"
    fileprivate enum ErrorCode: Int {
        case alreadyConnected = -1000
    }
    
    fileprivate var connectionState: ConnectionState = .disconnected {
        didSet {
            DDLogVerbose("Transitioned from state \(oldValue) to state \(connectionState)", tag: TAG)
            serverOutboundSink.send(value: .stateChange(connectionState))
        }
    }
    
    private var reader: LineDelimitedJSONStreamReader!
    var readerDisposable: Disposable! {
        willSet { readerDisposable?.dispose() }
    }
    
    private var writer: LineDelimitedJSONStreamWriter!
    var serverSendDisposable: Disposable! {
        willSet { serverSendDisposable?.dispose() }
    }
    
    init(encrypted: Bool = true, compressed: Bool = true, inputStream: InputStream, outputStream: OutputStream) {

        if encrypted {
            inputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
            outputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL, forKey: Stream.PropertyKey.socketSecurityLevelKey)
        }
        
        reader = LineDelimitedJSONStreamReader(stream: inputStream, compressed: compressed)
        writer = LineDelimitedJSONStreamWriter(stream: outputStream, compressed: compressed)
    }
    
    deinit {
        DDLogVerbose("Deinitializing", tag: TAG)
        teardown()
    }
    
    lazy fileprivate(set) var readQueueScheduler: QueueScheduler = {
        return QueueScheduler(qos: DispatchQoS.userInitiated, name: "io.afero.conclaveClientScheduler")
    }()

    func setupPipes() {
        
        // Handle incoming JSON events, map them to ConclaveEvents, and send them out
        // to readers.
        
        readerDisposable = reader.readSignal
            .observe(on: readQueueScheduler)
            .observe {
                [weak self] event in switch event {
                case .failed(let err):
                    self?.handleReadError(err)
                case .interrupted:
                    self?.handleReadInterrupted()
                case .value(let jsonEvent):
                    self?.handleReadNext(jsonEvent)
                case .completed:
                    self?.handleReadCompleted()
                }
            }
        
        // Handle incoming ConclaveMessages from the client, and send them to the server.
        
        serverSendDisposable = serverInboundSignal
            .observe(on: readQueueScheduler)
            .observe {
                [weak self] event in switch event {
                case .failed(let err):
                    self?.handleWriteError(err)
                case .interrupted:
                    self?.handleWriteInterrupted()
                case .value (let message):
                    self?.handleWriteNext(message)
                case .completed:
                    self?.handleWriteCompleted()
                }
            }
    }
    
    func teardown() {
        
        reader?.end()
        reader = nil
        readerDisposable = nil

        writer?.end()
        writer = nil
        serverSendDisposable = nil
    }
    
    // MARK: client ← server
    
    func handleReadNext(_ event: JSONStreamEvent) {
        
        switch(event) {
            
        case .stateChange(let cs):

            self.connectionState = cs
            break
            
        case .data(let data):

            let (obj, error): (Any?, NSError?) = data
            
            if let msg: ConclaveMessage = |<obj {
                let event = ConclaveConnectionEvent.message(msg)
                DDLogVerbose("Forwarding to readSignalSubscribers: \(event)", tag: TAG)
                serverOutboundSink.send(value: event)
                return
            }
            
            if let error = error {
                let event = ConclaveConnectionEvent.transientError(error)
                DDLogVerbose("Forwarding to readSignalSubscribers: \(event)", tag: TAG)
                serverOutboundSink.send(value: event)
                return
            }
            
            DDLogDebug("Unrecognized incoming JSONStreamEvent data; skipping: \(String(reflecting: data))", tag: TAG)
            
        }
    }
    
    func handleReadError(_ error: NSError) {
        serverOutboundSink.send(error: error)
    }
    
    func handleReadInterrupted() {
        serverOutboundSink.sendInterrupted()
    }
    
    func handleReadCompleted() {
        serverOutboundSink.sendCompleted()
    }
    
    // MARK: client → server
    
    func handleWriteNext(_ message: ConclaveMessage) {
        writer.writeSink.send(value: message.JSONDict)
    }
    
    func handleWriteError(_ error: NSError) {
        // Push the error through to the reader, and kill the connection.
        reader.writeSink.send(error: error)
        teardown()
    }
    
    func handleWriteInterrupted() {
        writer.writeSink.sendInterrupted()
    }
    
    func handleWriteCompleted() {
        writer.writeSink.sendCompleted()
    }
    
    // MARK: <ConclaveConnection>
    
    open func connect() throws {

        if (connectionState != .disconnected) {
            throw NSError(domain: type(of: self).ErrorDomain, code: ErrorCode.alreadyConnected.rawValue, userInfo: nil)
        }

        self.connectionState = .connecting

        setupPipes()
        
        self.reader.start()
        self.writer.start()
    }
    
    open func disconnect() {

        if (self.connectionState == .disconnected) {
            DDLogVerbose("Already disconnected, nothing to do.", tag: TAG)
            return
        }
        
        teardown()
    }
    
    // MARK: Server to the client
    lazy fileprivate var serverToClientPipe: (Signal<ConclaveConnectionEvent, NSError>, Observer<ConclaveConnectionEvent, NSError>) = {
        return Signal<ConclaveConnectionEvent, NSError>.pipe()
        }()
    
    /// The sink into which server messages bound for the client are inserted.
    var serverOutboundSink: Observer<ConclaveConnectionEvent, NSError> {
        return serverToClientPipe.1
    }

    /// The signal on which server messages bound for the client are emitted.
    /// Clients subscribe to this.
    
    open var readSignal: Signal<ConclaveConnectionEvent, NSError> {
        return serverToClientPipe.0
    }
    
    // MARK: Client to server
    lazy fileprivate var clientToServerPipe: (Signal<ConclaveMessage, NSError>, Observer<ConclaveMessage, NSError>) = {
        return Signal<ConclaveMessage, NSError>.pipe()
        }()
    
    /// The signal on which messages from the client are emitted to the server.
    var serverInboundSignal: Signal<ConclaveMessage, NSError> {
        return clientToServerPipe.0
    }

    /// The sink into which clients insert server-bound messages. Clients
    /// invoke `.sendNext()` on this.
    
    open var writeSink: Observer<ConclaveMessage, NSError> {
        return clientToServerPipe.1
    }
}

/**
A `ConclaveConnection` which binds to a socket.
*/

class ConclaveSocketConnection: ConclaveStreamConnection {
    
    override public var debugDescription: String {
        return "<ConclaveSocketConnection> host: \(host ?? "nil") port: \(port?.description ?? "nil") connectionState: \(connectionState)"
    }
    
    fileprivate(set) var port: ConclaveHost.Port! = nil
    fileprivate(set) var host: ConclaveHost.HostName! = nil
    
    required init(host: String, port: ConclaveHost.Port, encrypted: Bool, compressed: Bool) {

        self.host = host
        self.port = port
        
        DDLogInfo("Initializing conclave at \(host):\(port)", tag: "ConclaveSocketConnection")
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(nil, host as CFString, UInt32(port), &readStream, &writeStream)

        super.init(encrypted: encrypted, compressed: compressed, inputStream: readStream!.takeRetainedValue(), outputStream: writeStream!.takeRetainedValue())
    }
    
    deinit {
        DDLogDebug("Deinitializing", tag: "ConclaveSocketConnection")
    }
    
}


// MARK: - Stream Handlers

enum JSONStreamEvent {
    case stateChange(ConnectionState)
    case data(JSONStreamData)
}


typealias StreamProcessor = (Data) -> Data

func PureStreamProcessor(_ data: Data) -> Data {
    return data
}

// MARK: - JSON Stream Reader

typealias JSONStreamData = (Any?, NSError?)

let StreamReaderErrorDomain = "JSONStreamReader"
enum StreamReaderErrorCode: Int {
    case connectionTimeout = -2000
}

/**
Responsible for reading bytes from an NSInputStream, parsing them as `0x0a`-delimited lines,
and parsing each line as a JSON object. Parse results and state changes are emitted on `readSignal`
as `JSONStreamEvent`s.
*/

class LineDelimitedJSONStreamReader: NSObject, StreamDelegate {
    
    fileprivate lazy var TAG: String = { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }()

    var connectionTimeout: TimeInterval = 15 // seconds
    fileprivate var connectionTimer: Timer? = nil
    
    func startConnectionTimer() {
        stopConnectionTimer()
        weak var wself = self

        let TAG = self.TAG
        
        self.connectionTimer = Timer.schedule(delay: connectionTimeout) {
            timer in
            if timer == wself?.connectionTimer {
                let localizedDescription = String(format: NSLocalizedString("Connection timer expired after %.2f seconds", comment: "LineDelimitedJSONStreamReader connection timeout error template"), self.connectionTimeout)
                
                DDLogWarn(localizedDescription, tag: TAG)
                let error = NSError(domain: StreamReaderErrorDomain, code: StreamReaderErrorCode.connectionTimeout.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
                wself?.stopConnectionTimer()
                wself?.end(error)
            }
        }
    }
    
    fileprivate func stopConnectionTimer() {
        self.connectionTimer?.invalidate()
        self.connectionTimer = nil
    }
    
    fileprivate(set) open var connectionState: ConnectionState = .disconnected {
        didSet {
            
            switch(connectionState) {
            case .connecting: startConnectionTimer()
            case .connected: stopConnectionTimer()
            default: break
            }
            
            writeSink.send(value: .stateChange(connectionState))
        }
    }
    
    private let inputStream: InputStream
    var streamProcessor: StreamProcessor = PureStreamProcessor
    
    lazy fileprivate var pipe: (Signal<JSONStreamEvent, NSError>, Observer<JSONStreamEvent, NSError>) = {
        return Signal<JSONStreamEvent, NSError>.pipe()
        }()

    /**
    Signal that emits JSONStreamEvents. I/O-related errors are sent here, but any
    coding errors (which are by definition transient) are emitted in individual JSONStreamEvents.
    It's up to the subscriber to decide ehether or not a transient error represents something failable.
    */
    
    var readSignal: Signal<JSONStreamEvent, NSError> {
        return pipe.0
    }
    
    fileprivate var writeSink: Observer<JSONStreamEvent, NSError> {
        return pipe.1
    }
    
    fileprivate var q: DispatchQueue
    
    init(stream: InputStream, compressed: Bool = false) {
        q = DispatchQueue(label: "io.afero.JSONReader", qos: .userInitiated, attributes: [])
        inputStream = stream
        if (compressed) {
            let decompressor = TDTZDecompressor(compressionFormat: .deflate)
            streamProcessor = { (decompressor?.flushData($0))! }
        }
        super.init()
    }
    
    deinit {
        DDLogVerbose("Deinitializing.", tag: TAG)
    }
    
    fileprivate(set) open var finished = false
    
    /**
    Start up. This does the following;
    1. Stest the stream delegate
    2. Schedules the stream
    3. Opens the stream
    */
    
    func start() {

        let t = mach_absolute_time()

        DDLogInfo("TTT t:\(t) Starting Conclave", tag: TAG)
        
        if finished {
            fatalError("Cannot start previously finished stream.")
        }
        
        self.inputStream.delegate = self
        self.inputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.inputStream.open()
    }
    
    /**
    Tears down the world. Specifically:
    1. Sets connection state to `.Disconnected`
    2. Sends a completed to the sink, or an error if `error` is non-nil
    3. Closes the stream, unschedules it, and nils its delegate.
    */
    
    fileprivate func end(_ error: NSError? = nil) {

        finished = true
        self.inputStream.delegate = nil
        self.connectionState = .disconnected
        if let error = error {
            writeSink.send(error: error)
        } else {
            writeSink.sendCompleted()
        }

        self.inputStream.close()
        self.inputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        DDLogDebug("Conclave reader inputSteam closed.", tag: TAG)
        
    }
    
    // MARK: <NSStreamDelegate>
    
    public func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        
        if finished { return }
        
        switch(eventCode) {
            
        case Stream.Event.openCompleted:
            let t = mach_absolute_time()
            DDLogDebug("TTT t:\(t) Conclave inputStream openCompleted", tag: TAG)
            self.connectionState = .connected
            
        case Stream.Event.hasBytesAvailable:
            let t = mach_absolute_time()
            DDLogDebug("TTT t:\(t) Conclave inputStream hasBytesAvailable", tag: TAG)
            q.async {
                self.handleHasBytesAvailable(stream as! InputStream)
            }
            
        case Stream.Event.endEncountered:
            let t = mach_absolute_time()
            DDLogDebug("TTT t:\(t) Conclave inputStream endEncountered", tag: TAG)
            end()
            
        case Stream.Event.errorOccurred:
            let t = mach_absolute_time()
            DDLogDebug("TTT t:\(t) Conclave inputStream eventErrorOccurred: \(String(describing: stream.streamError))", tag: TAG)
            writeSink.send(error: stream.streamError! as NSError)
            end()
            
        case Stream.Event.hasSpaceAvailable:
            let t = mach_absolute_time()
            DDLogDebug("TTT t:\(t) Conclave inputStream hasSpaceAvailable (ignoring)", tag: TAG)
            
        default:
            break
        }
    }

    private var parseBuffer: Data? = nil
    private var readBuffer: [UInt8] = [UInt8](repeating: 0, count: 1024)

    private let DELIM: UInt8 = 0x0a
    
    private func handleHasBytesAvailable(_ stream: InputStream) {

        let TAG = self.TAG

        let t = mach_absolute_time()
        DDLogDebug("TTT t:\(t) handleHasBytesAvailable", tag: TAG)

        // First exhaust available bytes so that we get a full compression frame
        
        var processBuffer = Data()
        
        while(stream.hasBytesAvailable) {
            
            let len = stream.read(&readBuffer, maxLength: readBuffer.count)
            DDLogDebug("\(len) bytes read.", tag: TAG)
            DDLogVerbose("bytes: \(readBuffer.toHexString())", tag: TAG)
            
            if (len > 0) {
                processBuffer.append(&readBuffer, count: len)
            } else if len == 0 {
                DDLogDebug("empty read.", tag: TAG)
            } else {
                let error = stream.streamError
                let status = stream.streamStatus
                DDLogError("Read failure (err: \(String(describing: error)) status: \(status)). Bailing.", tag: TAG)
            }
        }
        
        DDLogVerbose("process buffer now \(String(reflecting: processBuffer))", tag: TAG)
        
        if processBuffer.count == 0 {
            DDLogDebug("No parse work to do; bailing.", tag: TAG)
            return
        }
        
        // Now decompress, append if necessary, and parse the bytes we got.

        if parseBuffer == nil {
            parseBuffer = Data()
        }
        
        let decompressed = streamProcessor(processBuffer)
        
        DDLogVerbose("Decompressed processBuffer to \(String(reflecting: decompressed))", tag: TAG)
        parseBuffer!.append(decompressed)

        let bytesToParse = parseBuffer!.byteArray
        
        if bytesToParse.count == 0 {
            DDLogWarn("No bytes decompressed parsed from parseBuffer: \(String(describing: parseBuffer))", tag: TAG)
            return
        }
        
        // If the last byte isn't a newline, then the last line we pull out
        // will be partial. Detect that now.
        
        let haveResidue: Bool = bytesToParse.last == DELIM ? false : true
        
        // Split the bytes into lines
        
        var lines: [ArraySlice<UInt8>] = []
        
        var startIndex: Int = 0
        var currIndex = 0
        var done = false
        
        while !done {
            if bytesToParse[currIndex] == DELIM {
                lines.append(bytesToParse[startIndex..<currIndex])
                startIndex = currIndex + 1
            }
            currIndex += 1
            done = currIndex == bytesToParse.count
        }
        
        if lines.count == 0 {
            DDLogDebug("No lines parsed; bailing.", tag: TAG)
            return
        }
        
        let sliceMaxIndex = haveResidue ? lines.count - 1 : lines.count
        
        // Iterate over the lines, and for each line, emit a JSONStreamEvent
        
        for bytes in lines[0..<sliceMaxIndex] {
            
            if (bytes.count == 0) {
                DDLogDebug("HEARTBEAT", tag: TAG)
                writeSink.send(value: .data((nil, nil)))
                continue
            }
            
            let data = Data(bytes: bytes)

            DDLogVerbose("line: \(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "<nil>")", tag: TAG)
            
            let obj: Any?
            
            do {
                
                obj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                let event: JSONStreamEvent = .data((obj, nil))
                writeSink.send(value: event)
                
            } catch let error as NSError {
                
                let event: JSONStreamEvent = .data((nil, error))
                writeSink.send(value: event)
                
            }
        }
        
        if (haveResidue) {
            let residueBytes = Array(lines.last!)
            parseBuffer = Data(bytes: residueBytes)
        } else {
            parseBuffer = nil
        }

    }
    
}

// MARK: JSONStreamWriter

typealias JSONStreamWriterSignal = Signal<Any?, NSError>
typealias JSONStreamWriterSink = Observer<Any?, NSError>
typealias JSONStreamWriterPipe = (JSONStreamWriterSignal, JSONStreamWriterSink)

/**
NSStreamDelegate specific to NSOutputStreams. Its job is to listen for `AnyObject` instances
sent to its `writeSink`, encoding them to JSON, and writing them to the output stream, with newline (`0x0a`)
delimters.
*/

class LineDelimitedJSONStreamWriter: NSObject, StreamDelegate {
    
    lazy var TAG: String = { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }()

    private let outputStream: OutputStream
    
    lazy fileprivate var pipe: JSONStreamWriterPipe = {
        return Signal.pipe()
        }()
    
    private var readSignal: JSONStreamWriterSignal {
        return pipe.0
    }
    
    /**
    Sink on which to send objects which will be written to the outputStream
    */
    var writeSink: JSONStreamWriterSink {
        return pipe.1
    }
    
    var streamProcessor: StreamProcessor = PureStreamProcessor
    
    /**
    Initialize with a configured (but unopened) NSOutputStream. Will set the stream delegate
    and open the stream upon `start()`.
    */
    
    init(stream: OutputStream, compressed: Bool = false) {
        q = DispatchQueue(label: "io.afero.JSONWriter", qos: .userInitiated, attributes: [])
        outputStream = stream
        if compressed {
            let compressor = TDTZCompressor(compressionFormat: .deflate)
            streamProcessor = { (compressor?.flushData($0))! }
        }
        super.init()
    }
    
    deinit {
        DDLogDebug("Deinitializing.", tag: TAG)
        end()
    }
    
    private var q: DispatchQueue
    
    var finished = false
    private var readSignalDisposable: Disposable? = nil
    
    lazy fileprivate(set) var readQueueScheduler: QueueScheduler = {
        return QueueScheduler(qos: .default, name: "io.afero.readQScheduler", targeting: self.q)
    }()
    
    /**
    Start the stream. This does the following:
    
    1. Sets the delegate on the stream.
    2. Subscribes to the `signal` to which events from `writeSink` are forwarded.
    3. Schedules the stream in the runloop.
    4. Opens the stream.
    
    */
    
    func start() {

        let TAG = self.TAG
    
        DDLogVerbose("start() invoked.", tag: TAG)

        if finished {
            fatalError("StreamWriter finished; can't reopen.")
        }

        readSignalDisposable = self.readSignal
            .observe(on: readQueueScheduler)
            .observe {
                [weak self] event in switch event {

                case .failed(let err):
                    DDLogError("Error sent to streamWriter: \(err). Terminating", tag: TAG)
                    self?.end()

                case .interrupted:
                    DDLogWarn("Received interrupted on JSON writer; ignoring.", tag: TAG)
                    
                case .value(let value):
                    self?.handleNext(value)
                    
                case .completed:
                    DDLogInfo("Received complete on JSON writer; ending.", tag: TAG)
                    self?.end()

                }
        }
        
        outputStream.delegate = self
        
        self.outputStream.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        self.outputStream.open()
    }
    
    /**
    Tear down the world. This closes and unschedules the stream, and disposes the signal. No further events will be processed.
    */
    
    fileprivate func end() {
        DDLogVerbose("end() invoked.", tag: TAG)
        finished = true
        readSignalDisposable?.dispose()
        readSignalDisposable = nil
        outputStream.delegate = nil
        self.outputStream.close()
        self.outputStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
    }
    
    // Object consumption

    fileprivate let DELIM: [UInt8] = [0x0a]

    fileprivate func handleNext(_ obj: Any?) {
        
        var messageData = Data()
        var processedData = Data()
        
        do {
            if let obj = obj {
                try messageData.append(
                    JSONSerialization.data(
                        withJSONObject: obj,
                        options: JSONSerialization.WritingOptions()
                    )
                )
            }
            messageData.append(DELIM, count: 1)
            processedData.append(streamProcessor(messageData))
        } catch let error as NSError {
            DDLogInfo("Error serializing object: \(error.localizedDescription)", tag: TAG)
            return
        }
        
        if outBuffer == nil {
            outBuffer = processedData
        } else {
            outBuffer!.append(processedData)
        }
        
        DDLogVerbose("Enqueing \(processedData.count) bytes: \(processedData) representing \(String(describing: messageData.prettyJSONValue))", tag: TAG)
        
        flush()
    }
    
    // MARK: <NSStreamDelegate>
    
    fileprivate var outBuffer: Data? = nil
    fileprivate var spaceAvailable: Bool = false
    
    fileprivate func flush() {
        
        if !spaceAvailable {
            DDLogInfo("No space available.", tag: TAG)
            return
        }
        
        if let outBuffer = outBuffer {
            let bytes = outBuffer.byteArray

            if bytes.count == 0 {
                return
            }
            
            let len = outputStream.write(bytes, maxLength: bytes.count)

            if len > 0 {

                spaceAvailable = false
   
                // Advance the buffer
                
                let wroteBuffer = outBuffer.subdata(in: 0..<len)
                
                let wroteString: String
                
                if let utf8String = NSString(data: wroteBuffer, encoding: String.Encoding.utf8.rawValue) {
                    wroteString = utf8String as String
                } else {
                    wroteString = wroteBuffer.debugDescription
                }

                DDLogVerbose("wrote: \(wroteString)", tag: TAG)
                
                self.outBuffer = Data(outBuffer.subdata(in: 0..<(outBuffer.count - len)))
                
                DDLogVerbose("outBuffer now \(String(describing: self.outBuffer))", tag: TAG)
            }
        }
    }
    
    public func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        
        switch(eventCode) {
            
        case Stream.Event.openCompleted:
            DDLogDebug("Got EventOpenCompleted.", tag: TAG)
            
        case Stream.Event.hasBytesAvailable:
            DDLogDebug("Got EventBytesAvailable (ignored).", tag: TAG)
            
        case Stream.Event.endEncountered:
            DDLogInfo("Got EventEndEncountered.", tag: TAG)
            
        case Stream.Event.errorOccurred:
            DDLogError("Got EventErrorOccurred: \(String(describing: stream.streamError)).", tag: TAG)
            writeSink.send(error: stream.streamError! as NSError)
            
        case Stream.Event.hasSpaceAvailable:
            DDLogDebug("Got EventHasSpaceAvailable (flushing)", tag: TAG)
            q.async {
                self.spaceAvailable = true
                self.flush()
            }
            
        default:
            break
        }
    }
    
}
