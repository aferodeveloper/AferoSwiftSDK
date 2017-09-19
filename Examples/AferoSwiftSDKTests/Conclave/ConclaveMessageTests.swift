//
//  ConclaveMessageTests.swift
//  AferoSwiftConclave
//
//  Created by Justin Middleton on 7/29/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Afero
import CocoaLumberjack
import AferoSwiftLogging

class ConclaveConnectionInfoSpec: QuickSpec {

    override func spec() {
        
        describe("When decoding connection info") {
            [weak self] in
            let fileName = "conclaveConnectionInfo"

            guard let json: [String: Any] = try! self?.fixture(named: fileName) else {
                fatalError("No JSON file named \(fileName)")
            }
            
            it("Should decode connectionInfo") {
                
                guard let connectionInfo: ConclaveAccess = |<json else {
                    fail("Couldn't instantiate connectionInfo with json: \(String(describing: json))")
                    return
                }
                
                expect(connectionInfo.tokens.count) == 1

                let client0 = ConclaveAccess.Token.Client.user(userId: "foouser")
                let token0 = ConclaveAccess.Token(
                    token: "mytoken",
                    channelId: "mychannelid",
                    expires: Date(timeIntervalSince1970: 0),
                    client: client0
                )
                expect(connectionInfo.token) == token0
                
                let httpHosts = connectionInfo.conclaveHosts.hostsForType("http")
                expect(httpHosts.count) == 1
                
                expect(httpHosts[0]) == ConclaveHost(type: "http", host: "conclave-http-host", port: 187)
                
                let socketHosts = connectionInfo.conclaveHosts.hostsForType("socket")
                expect(socketHosts.count) == 2
                expect(socketHosts[0]) == ConclaveHost(type: "socket", host: "conclave-socket-host", port: 1337)
                expect(socketHosts[1]) == ConclaveHost(type: "socket", host: "conclave-socket-host-2", port: 31337)
                
            }

            it("Should roundtrip") {
                
                guard let connectionInfo: ConclaveAccess = |<json else {
                    fail("Couldn't instantiate connectionInfo with json: \(String(describing: json))")
                    return
                }
                
                guard
                    let nuJSON = connectionInfo.JSONDict,
                    let nuConnectionInfo: ConclaveAccess = |<nuJSON else {
                        fail("Couldn't instantiate nuConnectionInfo with json: \(String(describing: json))")
                        return
                }
                
                expect(nuConnectionInfo.tokens.count) == 1
                
                let client0 = ConclaveAccess.Token.Client.user(userId: "foouser")
                let token0 = ConclaveAccess.Token(
                    token: "mytoken",
                    channelId: "mychannelid",
                    expires: Date(timeIntervalSince1970: 0),
                    client: client0
                )
                expect(nuConnectionInfo.tokens[0]) == token0
                
                let httpHosts = nuConnectionInfo.conclaveHosts.hostsForType("http")
                expect(httpHosts.count) == 1
                
                expect(httpHosts[0]) == ConclaveHost(type: "http", host: "conclave-http-host", port: 187)
                
                let socketHosts = nuConnectionInfo.conclaveHosts.hostsForType("socket")
                expect(socketHosts.count) == 2
                expect(socketHosts[0]) == ConclaveHost(type: "socket", host: "conclave-socket-host", port: 1337)
                expect(socketHosts[1]) == ConclaveHost(type: "socket", host: "conclave-socket-host-2", port: 31337)
                
            }

        }
    }
}

class ConclaveMessageSpec: QuickSpec {
    
    override func spec() {
        
        defaultDebugLevel = DDLogLevel.debug
        
        DDTTYLogger.sharedInstance.logFormatter = AferoTTYADBLogFormatter()
        DDLog.add(DDTTYLogger.sharedInstance)
        
        describe("When decoding messages") {
            
            it("Should be able to decode a Hello") {
                let hello: ConclaveMessage? = try! self.fixture(named: "conclave_hello")
                expect(hello).toNot(beNil())
                expect(hello) == ConclaveMessage.hello(version: "conclave 1.0.5", bufferSize: 1024, heartbeat: 270)
            }
            
            it("Should be able to decode a Welcome") {
                let welcome: ConclaveMessage? = try! self.fixture(named: "conclave_welcome")
                expect(welcome).toNot(beNil())
                expect(welcome) == ConclaveMessage.welcome(sessionId: 91, seq: 847553, channelId: "lockbox", generation: 12345)
            }
            
            it("Should be able to decode a Public") {
                let ppublic: ConclaveMessage? = try! self.fixture(named: "conclave_public")
                expect(ppublic).toNot(beNil())
                switch(ppublic!) {
                case let .public(seq, sessionId, event, data):
                    expect(seq) == 6666
                    expect(sessionId) == 99999
                    expect(event) == "fake event man"
                    expect(data["key1"] as? String) == "val1"
                    expect(data["key2"] as? Int) == 2
                default:
                    fail("Expected .Public, got \(String(describing: ppublic))")
                }
            }
            
            it("Should be able to encode a Say") {
                let say = ConclaveMessage.say(event: "bar", data: ["me": "mo"])
                let say2: ConclaveMessage? = |<say.JSONDict
                expect(say2).toNot(beNil())
                switch(say2!) {
                case let .say(evt, data):
                    expect(evt) == "bar"
                    expect((data as? [String: String])?["me"]) == "mo"
                default:
                    fail("Expected .Say(...), got \(String(describing: say2))")
                }
            }
            
            it("Should be able to encode a Whisper") {
                let whisper = ConclaveMessage.whisper(sessionId: 666, type: "shh", event: "bar", data: ["me": "mo"])
                let whisper2: ConclaveMessage? = |<whisper.JSONDict
                expect(whisper2).toNot(beNil())
                switch(whisper2!) {
                case let .whisper(sid, type, evt, data):
                    expect(sid) == 666
                    expect(type) == "shh"
                    expect(evt) == "bar"
                    expect((data as? [String: String])?["me"]) == "mo"
                default:
                    fail("Expected .Whisper(...), got \(String(describing: whisper2))")
                }
            }
            
            it("Should be able to encode a Whispered") {
                let whispered = ConclaveMessage.whispered(sessionIds: [666])
                let whispered2: ConclaveMessage? = |<whispered.JSONDict
                expect(whispered2).toNot(beNil())
                switch(whispered2!) {
                case let .whispered(sids):
                    expect(sids) == [666]
                default:
                    fail("Expected .Whispered(...), got \(String(describing: whispered2))")
                }
            }
            
            it("Should be able to encode an Echo") {
                let echo = ConclaveMessage.echo(data: [1, 2, 3])
                let echo2: ConclaveMessage? = |<echo.JSONDict
                expect(echo2).toNot(beNil())
                switch(echo2!) {
                case let .echo(data):
                    expect(data).toNot(beNil())
                    expect(data as? [Int]) == [1, 2, 3]
                default:
                    fail("Expected .Echo(...), got \(String(describing: echo2))")
                }
            }
            
            it("Should be able to encode an Ping") {
                let ping = ConclaveMessage.ping(data: [1, 2, 3])
                let ping2: ConclaveMessage? = |<ping.JSONDict
                expect(ping2).toNot(beNil())
                switch(ping2!) {
                case let .ping(data):
                    expect(data).toNot(beNil())
                    expect(data as? [Int]) == [1, 2, 3]
                default:
                    fail("Expected .Ping(...), got \(String(describing: ping2))")
                }
            }
            
            it("Should be able to encode an Error") {
                let error = ConclaveMessage.error(code: 23, message: "boo!")
                let error2: ConclaveMessage? = |<error.JSONDict
                expect(error2).toNot(beNil())
                switch(error2!) {
                case let .error(code, msg):
                    expect(code) == 23
                    expect(msg) == "boo!"
                default:
                    fail("Expected .Error(...), got \(String(describing: error2))")
                }
            }
            
            it("Should be able to decode a Private") {
                let pprivate: ConclaveMessage? = try! self.fixture(named: "conclave_private")
                expect(pprivate).toNot(beNil())
                switch(pprivate!) {
                case let .private(seq, sessionId, target, event, data):
                    expect(seq) == 777
                    expect(sessionId) == 88888
                    expect(target) == "fake private target man"
                    expect(event) == "fake private event man"
                    expect(data["key1"] as? String) == "priv val1"
                    expect(data["key2"] as? Int) == 23
                default:
                    fail("Expected .Public, got \(String(describing: pprivate))")
                }
            }
            
        }
        
        describe("When encoding messages") {
            
            it("Should be able to encode a Login") {
                let login = ConclaveMessage.login(channelId: "acctfoo", accessToken: "tokenbar", type: "typemoo", deviceId: "devieiddoo", mobileDeviceId: "movileDevicedoo", version: "version flek", trace: true, protocol: 99)
                let json: AferoJSONCodedType? = login.JSONDict
                
                let login2: ConclaveMessage? = |<json
                expect(login2).toNot(beNil())
                expect(login2) == login
            }
            
            it("Should be able to encode a Bye") {
                let bye = ConclaveMessage.bye
                let json: AferoJSONCodedType? = bye.JSONDict
                let bye2: ConclaveMessage? = |<json
                expect(bye2).toNot(beNil())
                expect(bye2) == bye
            }
            
            it("Should be able to encode a Who") {
                let who = ConclaveMessage.who
                let json: AferoJSONCodedType? = who.JSONDict
                let bye2: ConclaveMessage? = |<json
                expect(bye2).toNot(beNil())
                expect(bye2) == who
            }
            
            it("Should be able to encode a Join") {
                let ts = Int(NSDate().timeIntervalSince1970)
                let join = ConclaveMessage.join(sessionId: 666, timestamp: ts, type: "ios", deviceId: nil, mobileDeviceId: "clientidfoo", version: "versionfoo")
                
                let join2: ConclaveMessage? = |<join.JSONDict
                expect(join2).toNot(beNil())
                expect(join2) == ConclaveMessage.join(sessionId: 666, timestamp: ts, type: "ios", deviceId: nil, mobileDeviceId: "clientidfoo", version: "versionfoo")
            }
            
            it("Should be able to encode a Leave") {
                let ts = Int(NSDate().timeIntervalSince1970)
                let leave = ConclaveMessage.leave(sessionId: 777, timestamp: ts, type: "iosfoo", deviceId: "deviceidfoo", mobileDeviceId: nil)
                
                let leave2: ConclaveMessage? = |<leave.JSONDict
                expect(leave2).toNot(beNil())
                expect(leave2) == ConclaveMessage.leave(sessionId: 777, timestamp: ts, type: "iosfoo", deviceId: "deviceidfoo", mobileDeviceId: nil)
                
            }
        }
        
    }
}



