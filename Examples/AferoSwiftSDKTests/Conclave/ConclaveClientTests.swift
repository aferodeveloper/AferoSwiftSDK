//
//  ConclaveTests.swift
//  iTokui
//
//  Created by Justin Middleton on 6/16/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import UIKit

import Quick
import Nimble
import Afero
import ReactiveSwift
import CocoaLumberjack
import AferoSwiftLogging

///  A bound pair of NSStreams; data written to `output` will be transferred to `input`.
typealias Pipe = (input: InputStream, output: OutputStream)

/// Make a `Pipe` optionally with the given tranfer buffer size.
func MakePipe(_ buffsz: Int = 512) -> Pipe {
    var writeStream: Unmanaged<CFWriteStream>?
    var readStream: Unmanaged<CFReadStream>?
    CFStreamCreateBoundPair(nil, &readStream, &writeStream, buffsz)
    return (readStream!.takeRetainedValue(), writeStream!.takeRetainedValue())
}

typealias JSONStreamLine = (reader: LineDelimitedJSONStreamReader, writer: LineDelimitedJSONStreamWriter)

class JSONStreamSpec: QuickSpec {

    override func spec() {
        
        defaultDebugLevel = DDLogLevel.debug
        
        DDTTYLogger.sharedInstance.logFormatter = AferoTTYADBLogFormatter()
        DDLog.add(DDTTYLogger.sharedInstance)
        

        var pipe: Pipe! = nil
        var reader: LineDelimitedJSONStreamReader! = nil
        var writer: LineDelimitedJSONStreamWriter! = nil
        
        describe("When writing JSON objects") {
            
            var errors: [NSError] = []
            var completedReceived: Bool = false
            var eventsReceived: [JSONStreamEvent] = []
            var readSignalDisposable: Disposable? = nil
            var interruptedReceived: Bool = false
            
            beforeEach {

                errors = []
                completedReceived = false
                interruptedReceived = false
                eventsReceived =  []
                
                pipe = MakePipe(512)
                reader = LineDelimitedJSONStreamReader(stream: pipe.input)
                writer = LineDelimitedJSONStreamWriter(stream: pipe.output)
                
                readSignalDisposable = reader.readSignal
                    .observe(on: QueueScheduler.main)
                    .observe {
                        event in
                        switch event {
                        case .value(let streamEvent):
                            eventsReceived.append(streamEvent)
                        case .failed(let err):
                            errors.append(err)
                        case .completed:
                            completedReceived = true
                        case .interrupted:
                            interruptedReceived = true
                        }
                }
            }
            
            afterEach {
                readSignalDisposable?.dispose()
            }
            
            it("Should produce the objects on the other end") {
                
                let obj = [
                    "foo": "bar",
                    "foo2": [1, 2, 3],
                    "foo3": [
                        "boo1": "rar1"
                    ]
                ] as [String : Any]
                
                let obj2 = [1, 2, 3]
                
                reader.start()
                writer.start()
                
                writer.writeSink.send(value: obj)
                writer.writeSink.send(value: obj2)
                expect(eventsReceived.count).toEventually(equal(3), timeout: 5, pollInterval: 0.5)
                
                writer.writeSink.sendCompleted()
                expect(writer.finished).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
                expect(completedReceived).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
                expect(reader.finished).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
            }
            
            it("Should be able to pump Conclave messages") {
                
                let messagesToSend: [ConclaveMessage] = [
                    ConclaveMessage.login(
                        channelId: "acct",
                        accessToken: "tok",
                        type: "ios",
                        deviceId: "device",
                        mobileDeviceId: "mobileDevice",
                        version: "vers", trace: true, protocol: 66
                    ),
                    ConclaveMessage.public(
                        seq: 3,
                        sessionId: 99,
                        event: "device:read",
                        data: ["foo": "bar"]
                    ),
                ]
                
                var messagesReceived: [ConclaveMessage] = []
                
                let _ = reader.readSignal
                    .observe(on: QueueScheduler.main)
                    .observe {
                        event in switch event {
                        case .value(let streamEvent):
                            switch(streamEvent) {
                            case .data(let data):
                                if let msg: ConclaveMessage = |<data.0 {
                                    messagesReceived.append(msg)
                                }
                            case .stateChange:
                                break
                            }
                        default:
                            break
                            
                        }
                }

                reader.start()
                writer.start()
                
                _ = messagesToSend.map {
                    (msg: ConclaveMessage) -> () in writer.writeSink.send(value: msg.JSONDict)
                }
                
                expect(eventsReceived.count).toEventually(equal(3), timeout: 5, pollInterval: 0.5)
                
                expect(messagesReceived).toEventually(equal(messagesToSend), timeout: 5, pollInterval: 0.5)
                
                writer.writeSink.sendCompleted()
                expect(writer.finished).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
                expect(completedReceived).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
                expect(reader.finished).toEventually(equal(true), timeout: 5, pollInterval: 0.5)
            }
        }
    }
}


/// Fixture to mock the remote end of Conclave.

class Mocklave: ConclaveConnection {
    
    // Server to the client
    lazy fileprivate var serverToClientPipe: (Signal<ConclaveConnectionEvent, NSError>, Observer<ConclaveConnectionEvent, NSError>)! = {
        return Signal<ConclaveConnectionEvent, NSError>.pipe()
        }()
    
    var serverOutboundSink: Observer<ConclaveConnectionEvent, NSError> {
        return serverToClientPipe.1
    }
    
    // Client to server
    lazy fileprivate var clientToServerPipe: (Signal<ConclaveMessage, NSError>, Observer<ConclaveMessage, NSError>)! = {
        return Signal<ConclaveMessage, NSError>.pipe()
        }()
    
    var serverInboundSignal: Signal<ConclaveMessage, NSError> {
        return clientToServerPipe.0
    }
    
    enum ClientResponse {
        case none
        case message(ConclaveMessage)
        case error(NSError)
    }
    
    init() {
        self.serverInboundSignal
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] event in switch event {
                case .value(let value):
                    self?.handleNext(value)
                case .completed:
                    self?.handleCompleted()
                case .failed(let err):
                    self?.handleError(err)
                case .interrupted:
                    self?.handleInterrupted()
                }
        }
    }
    
    deinit {
        testReset()
    }
    
    // MARK: <ConclaveConnection>
    
    var readSignal: ConclaveReadSignal {
        return serverToClientPipe.0
    }
    
    var writeSink: ConclaveMessageSink {
        return clientToServerPipe.1
    }
    
    var connectCalled: Bool = false
    var connectionResponse: ClientResponse = .none
    
    func connect() throws {
        
        connectCalled = true
        
        switch(connectionResponse) {
            
        case .none: break
            
        case .error(let connectionError):
            throw connectionError
            
        case .message(let msg):
            self.serverOutboundSink.send(value: .message(msg))
        }
    }
    
    var receivedError: NSError? = nil
    func handleError(_ error: NSError) {
        receivedError = error
    }
    
    var receivedCompleted = false
    func handleCompleted() {
        receivedCompleted = true
    }
    
    var receivedInterrupted = false
    func handleInterrupted() {
        receivedInterrupted = true
    }
    
    var receivedMessages: [ConclaveMessage] = []
    
    var loginResponse: ClientResponse = .none
    
    func handleNext(_ message: ConclaveMessage) {
        receivedMessages.append(message)
        switch(message) {
            
        case .login:
            switch(loginResponse) {
            case .message(let msg):
                self.serverOutboundSink.send(value: .message(msg))
            case .error(let error):
                self.serverOutboundSink.send(error: error)
            case .none: break
            }
            
        case .bye:
            self.serverOutboundSink.sendCompleted()
            break
            
        default:
            break
        }
    }
    
    var disconnectCalled: Bool = false
    func disconnect() {
        disconnectCalled = true
    }
    
    // MARK: Test Controls
    
    func testReset() {
        serverToClientPipe = nil
        clientToServerPipe = nil
        receivedError = nil
        receivedCompleted = false
        receivedInterrupted = false
        receivedMessages.removeAll(keepingCapacity: true)
        connectCalled = false
        connectionResponse = .none
        disconnectCalled = false
    }
    
    func testDisconnect() {
        self.serverOutboundSink.sendCompleted()
    }
    
    func testSendHeartbeat() {
        testSend(.heartbeat)
    }
    
    func testSend(_ message: ConclaveMessage) {
        serverOutboundSink.send(value: .message(message))
    }
    
}

public func ==(lhs: NSError, rhs: NSError) -> Bool {
    return lhs.localizedDescription == rhs.localizedDescription
        && lhs.domain == rhs.domain
        && lhs.code == rhs.code
        && (lhs.userInfo[NSUnderlyingErrorKey] as? NSError) == (rhs.userInfo[NSUnderlyingErrorKey] as? NSError)
}

// MARK: - ConclaveClientSpec

class ConclaveClientSpec: QuickSpec {
    
    override func spec() {
        
        describe("When instantiating") {
            
            it("Should instantiate correctly") {
                
                let token = ConclaveAccess.Token(
                    token: "nubar",
                    channelId: "coobar",
                    expires: Date(),
                    client: ConclaveAccess.Token.Client.mobile(type: "ios", mobileDeviceId: "foo")
                )
                
                let client = ConclaveClient(
                    token:token,
                    type:"poobar",
                    deviceId: "floobar",
                    mobileDeviceId: "clientfu",
                    version: "voobar"
                )
                
                expect(client.token) == token
                expect(client.type) == "poobar"
                expect(client.deviceId) == "floobar"
                expect(client.version) == "voobar"
            }
        }
        
        describe("Over streams") {
            
            // This test round-tripping of conclave messages over streams. It excercises
            // the entire code path, outside of the socket bits. This is not intended to be
            // a full behavioral test.
            
            var clientToServer: Pipe! = nil
            var serverToClient: Pipe! = nil
            
            // client.out -> server.in
            // client.in <- server.out
//            let (clientPipe, serverPipe) = Wire(clientToServer, serverToClient)
            
            var serverErrors: [NSError] = []
            var serverInterruptedCount: Int = 0
            var serverNexts: [ConclaveConnectionEvent] = []
            var serverConnection: ConclaveConnection? = nil
            var serverDisposables: [Disposable?] = []
            var serverComplete: Bool = false
            
            var clientConnection: ConclaveConnection? = nil

            var client: ConclaveClient! = nil
            
            beforeEach {
                serverErrors = []
                serverComplete = false
                serverInterruptedCount = 0
                serverNexts = []
                
                serverToClient = MakePipe(512)
                clientToServer = MakePipe(512)
                
                serverConnection = ConclaveStreamConnection(inputStream: clientToServer.input, outputStream: serverToClient.output)
                serverDisposables.append(
                    serverConnection!.readSignal
                        .observe(on: QueueScheduler.main)
                        .observe {
                            event in switch event {
                            case .value(let streamEvent):
                                serverNexts.append(streamEvent)
                            case .failed(let err):
                                serverErrors.append(err)
                            case .completed:
                                serverComplete = true
                            case .interrupted:
                                serverInterruptedCount += 1
                            }
                        }
                )
                
                clientConnection = ConclaveStreamConnection(inputStream: serverToClient.input, outputStream: clientToServer.output)
                
                let token = ConclaveAccess.Token(token: "nubar", channelId: "coobar", expires: Date(), client: ConclaveAccess.Token.Client.mobile(type: "ios", mobileDeviceId: "foo"))
                
                client = ConclaveClient(token:token, type:"poobar", deviceId: "floobar", mobileDeviceId: "clientfu", version: "voobar")
                client.heartbeatSlack = 1

            }
            
            it("should handle login") {
                serverDisposables.append(serverConnection!.readSignal
                    .observe(on: QueueScheduler.main)
                    .observe {
                        event in switch event {
                        case .value(let connectionEvent):
                            switch(connectionEvent) {
                                
                            case .message(let msg):
                                
                                switch(msg) {
                                    
                                case let .login(channelId, _, _, _, _, _, _, _):
                                    let message: ConclaveMessage = ConclaveMessage.welcome(
                                        sessionId: 666,
                                        seq: 10,
                                        channelId: channelId,
                                        generation: 12345
                                    )
                                    serverConnection!.writeSink.send(value: message)
                                    
                                default: break
                                    
                                }
                                
                            default: break
                            }
                            
                        default: break
                        }
                })
                
                do {
                    try client.connect(clientConnection!)
                } catch let error as NSError {
                    fail("Client connection failed: \(error)")
                }
                
                
                do {
                    try serverConnection!.connect()
                } catch let error as NSError {
                    fail("Server connection failed: \(error)")
                }
                
                serverConnection!.writeSink.send(value: .hello(version: "version 6666", bufferSize: 512, heartbeat: 270))
                
                expect(client.heartbeatInterval).toEventually(equal(270), timeout: 5, pollInterval: 0.5)
                expect(client.bufferSize).toEventually(equal(512), timeout: 5, pollInterval: 0.5)
                expect(client.sessionId).toEventually(equal(666), timeout: 5, pollInterval: 0.5)
                expect(client.seqNum).toEventually(equal(10), timeout: 5, pollInterval: 0.5)
            }
            
            it("should handle heartbeats") {
                
                var heartbeatReceived = false
                
                serverDisposables.append(serverConnection!.readSignal
                    .observe(on: QueueScheduler.main)
                    .observe {
                        event in switch event {
                        case .value(let connectionEvent):
                            switch(connectionEvent) {
                                
                            case .message(let msg):
                                
                                switch(msg) {
                                case .heartbeat: heartbeatReceived = true
                                default: break
                                }
                                
                            default: break
                            }
                        default: break
                        }
                    })
                
                do {
                    try client.connect(clientConnection!)
                } catch let error as NSError {
                    fail("Client connection failed: \(error.localizedDescription)")
                }
                
                do {
                    try serverConnection!.connect()
                } catch let error as NSError {
                    fail("Server connection failed: \(error.localizedDescription)")
                }
                
                serverConnection!.writeSink.send(value: .hello(version: "version 6666", bufferSize: 512, heartbeat: 270))
                serverConnection!.writeSink.send(value: .heartbeat)
                expect(heartbeatReceived).toEventually(beTrue(), timeout: 5, pollInterval: 0.5)
            }

            
            afterEach {
                serverConnection?.disconnect()
                _ = serverDisposables.map { $0?.dispose() }
                serverDisposables.removeAll(keepingCapacity: false)
                
                client.disconnect(false)
                clientConnection?.disconnect()
            }
            
        }
        
        describe("When connecting") {
            
            var client: ConclaveClient! = nil
            var connection: Mocklave! = nil
            
            beforeEach {
                let token = ConclaveAccess.Token(token: "nubar", channelId: "coobar", expires: Date(), client: ConclaveAccess.Token.Client.mobile(type: "ios", mobileDeviceId: "foo"))

                client = ConclaveClient(token:token, type:"poobar", deviceId: "floobar", mobileDeviceId: "clientfu", version: "voobar")
                connection = Mocklave()
            }
            
            it("Should call connect when given a server and asked to connect") {
                do {
                    try client.connect(connection)
                } catch let error as NSError {
                    fail("Client connection failed: \(error.localizedDescription)")
                }
                expect(connection.connectCalled).to(beTrue())
            }
            
            it("Should respond with the expected error if the server connection fails") {

                var error: NSError? = nil

                connection.connectionResponse = .error(NSError(domain: "Mocklave test error", code: 666, userInfo: ["errFoo": "errBar"]))
                
                do {
                    try client.connect(connection)
                } catch let connectError as NSError {
                    error = connectError
                }
                
                expect(error).toNot(beNil())
                expect(error?.code) == ConclaveClient.Error.connectionErrorRemoteConnectionFailed.rawValue
                expect(error?.domain) == ConclaveClient.ConclaveClientErrorDomain
                
                let underlyingError = error?.userInfo[NSUnderlyingErrorKey] as? NSError
                expect(underlyingError).toNot(beNil())
                expect(underlyingError?.domain) == "Mocklave test error"
                expect(underlyingError?.code) == 666
                expect(underlyingError?.userInfo["errFoo"] as? String) == "errBar"
                expect(underlyingError?.userInfo.count) == 1
                
                expect(connection.connectCalled).to(beTrue())
            }
            
            describe("After connecting") {
                
                var clientEventDisposable: Disposable? = nil
                var clientEventsReceived: [ConclaveClient.ClientEvent] = []
                var clientErrorsReceived: [NSError] = []
                var clientCompletedReceivedCount = 0
                var clientInterruptedReceivedCount = 0

                beforeEach {

                    clientEventDisposable = client.eventSignal
                        .observe(on: QueueScheduler.main)
                        .observe {
                            event in switch event {
                            case .value(let clientEvent):
                                clientEventsReceived.append(clientEvent)
                                print("Client event: \(clientEvent)")
                                print("Client EventsReceived now: \(clientEventsReceived)")
                            case .failed(let err):
                                clientErrorsReceived.append(err)
                            case .completed:
                                clientCompletedReceivedCount += 1
                            case .interrupted:
                                clientInterruptedReceivedCount += 1
                                
                            }
                    }

                    connection.connectionResponse = .message(ConclaveMessage.hello(version: "blue", bufferSize: 512, heartbeat: 2))
                    connection.loginResponse = .message(ConclaveMessage.welcome(sessionId: 99, seq: 44, channelId: "acctfu", generation: 12345))
                }
                
                afterEach {
                    client = nil
                    connection = nil
                    clientEventDisposable?.dispose()
                    clientEventsReceived.removeAll(keepingCapacity: false)
                    clientErrorsReceived.removeAll(keepingCapacity: false)
                    clientCompletedReceivedCount = 0
                    clientInterruptedReceivedCount = 0
                }
                
                it("Should respond with a Login when presented a Hello, handle the resulting Welcome, and set comms params") {
                    expect(client.connectionState) == ConnectionState.disconnected
                    client.heartbeatSlack = 1
                    
                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }

                    expect(client.connectionState) == ConnectionState.connecting
                    let expectedResponses = [ConclaveMessage.login(channelId: "coobar", accessToken: "nubar", type:"poobar", deviceId: "floobar", mobileDeviceId: "clientfu", version: "voobar", trace: false, protocol: 2)]
                    expect(connection.receivedMessages).toEventually(equal(expectedResponses), timeout: 2, pollInterval: 0.1)
                    expect(client.sessionId).toEventually(equal(99), timeout: 2, pollInterval: 0.1)
                    expect(client.channelId).toEventually(equal("coobar"), timeout: 2, pollInterval: 0.1)
                    expect(client.heartbeatInterval).toEventually(equal(2), timeout: 2, pollInterval: 0.1)
                    expect(client.seqNum).toEventually(equal(44), timeout: 2, pollInterval: 0.1)
                    expect(client.bufferSize).toEventually(equal(512), timeout: 2, pollInterval: 0.1)
                    expect(client.connectionState) == ConnectionState.connected
                }
                
                it("Should forward completed message if the server disconnects after previously being connected") {
                    
                    expect(clientEventsReceived.count) == 0
                    expect(clientErrorsReceived.count) == 0
                    expect(clientCompletedReceivedCount) == 0
                    expect(clientInterruptedReceivedCount) == 0
                    
                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    _ = Timer.schedule(0.5) {
                        timer in
                        connection.testDisconnect()
                    }
                    
                    let expectedEventsReceived: [ConclaveClient.ClientEvent] = [
                        .stateChange(.connecting),
                        .stateChange(.connected),
                        .stateChange(.disconnected),
                    ]
                    
                    let runUntil = NSDate(timeIntervalSinceNow: 5.0)
                    RunLoop.current.run(until: runUntil as Date)
                    expect(clientEventsReceived).toEventually(equal(expectedEventsReceived))
                    expect(clientCompletedReceivedCount).toEventually(equal(1))
                    expect(client.connectionState).toEventually(equal(ConnectionState.disconnected))
                }
                
                it("Should send the server a 'bye' when disconnecting.") {

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    DispatchQueue.main.async {
                        client.disconnect()
                    }
                    
                    expect(connection.receivedMessages.last).toEventually(equal(ConclaveMessage.bye), timeout: 5, pollInterval: 0.5)
                    expect(client.connectionState).toEventually(equal(ConnectionState.disconnected), timeout: 5, pollInterval: 0.1)
                }
                
                it("Should respond with a heartbeat if it receives a heartbeat") {

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    connection.testSendHeartbeat()
                    expect(connection.receivedMessages.last).toEventually(equal(ConclaveMessage.heartbeat), timeout: 5, pollInterval: 0.5)
                }
                
                it("Should set a hearbeat interval and watchdog timer once receiving a heartbeat interval from the server") {
                    client.heartbeatSlack = 1

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    expect(client.heartbeatInterval).toEventually(equal(2), timeout: 2, pollInterval: 0.5) // set in the beforeEach
                }
                
                it("Should send a completed if a heartbeat isn't sent by the time the watchdog expires") {
                    client.heartbeatSlack = 1

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    expect(client.heartbeatInterval).toEventually(equal(2), timeout: 2, pollInterval: 0.5) // set in the beforeEach
                    
                    let heartbeatInterval: TimeInterval? = 2.0
                    let localizedDescription = "Conclave client timed out after \(String(describing: heartbeatInterval)) seconds (with \(client.heartbeatSlack)s slack)"
                    let userInfo: [AnyHashable: Any] = [NSLocalizedDescriptionKey: localizedDescription]
                    let expectedError = NSError(domain: ConclaveClient.ConclaveClientErrorDomain, code: ConclaveClient.Error.timeoutFatal.rawValue, userInfo: userInfo)

                    
                    let expectedEventsReceived: [ConclaveClient.ClientEvent] = [
                        .stateChange(.connecting),
                        .stateChange(.connected),
                        .transientError(expectedError),
                        .stateChange(.disconnected),
                    ]
                    
                    expect(clientEventsReceived).toEventually(equal(expectedEventsReceived), timeout: 5, pollInterval: 0.5)
                }
                
                it("Should emit a Data event when receiving public messages") {

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    let msg = ConclaveMessage.public(seq: 999, sessionId: 222, event: "device:test", data: ["foo": "bar"])
                    
                    _ = Timer.schedule(0.5) {
                        timer in
                        connection.testSend(msg)
                    }

                    _ = Timer.schedule(1.0) {
                        timer in
                        connection.testDisconnect()
                    }

                    expect(client.connectionState).toEventually(equal(ConnectionState.disconnected), timeout: 5, pollInterval: 0.5)
                    expect(clientEventsReceived.count).toEventually(equal(4), timeout: 5, pollInterval: 0.5)
                    expect(clientEventsReceived.contains(
                        ConclaveClient.ClientEvent.data(
                            event: "device:test",
                            data: [:],
                            seq: 999,
                            target: nil
                        ))).toEventually(beTrue(), timeout: 5, pollInterval: 0.5)
                    expect(client.seqNum).toEventually(equal(999), timeout:5, pollInterval: 0.5)
                }
                
                it("Should emit Data events when receiving private messages") {

                    do {
                        try client.connect(connection)
                    } catch let error as NSError {
                        fail("Client connection failed: \(error.localizedDescription)")
                    }
                    
                    let msg = ConclaveMessage.private(seq: 77, sessionId: 222, target: nil, event: "device:test", data: ["foo": "bar"])
                    
                    _ = Timer.schedule(0.5) {
                        timer in
                        connection.testSend(msg)
                    }
                    
                    _ = Timer.schedule(1.0) {
                        timer in
                        connection.testDisconnect()
                    }
                    
                    expect(client.connectionState).toEventually(equal(ConnectionState.disconnected), timeout: 5, pollInterval: 0.5)
                    expect(clientEventsReceived.count).toEventually(equal(4), timeout: 5, pollInterval: 0.5)
                    expect(clientEventsReceived.contains(
                            ConclaveClient.ClientEvent.data(
                                event: "device:test",
                                data: [:],
                                seq: 77,
                                target: nil
                            )
                        )
                        ).toEventually(beTrue(), timeout: 5, pollInterval: 0.5)
                    expect(client.seqNum).toEventually(equal(77), timeout:5, pollInterval: 0.5)
                }
            }
        }
    }
}
