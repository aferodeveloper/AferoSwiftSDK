//
//  Conclave.swift
//  iTokui
//
//  Created by Justin Middleton on 6/16/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation


import CocoaLumberjack

// MARK: ConclaveAccess

public typealias AuthConclaveOnDone = (ConclaveAccess?, Error?) -> Void

public protocol ConclaveAuthable: class {
    var conclaveClientVersion: String { get }
    var conclaveClientType: String { get }
    func authConclave(accountId: String, onDone: @escaping AuthConclaveOnDone)
}

public extension ConclaveAuthable {
    
    public var conclaveClientVersion: String {
        return AferoAppEnvironment.appBundleName + "/" + (AferoAppEnvironment.appVersion ?? "<unknown>")
    }
    
    public var conclaveClientType: String { return "ios" }
    
}

public struct ConclaveHost: CustomDebugStringConvertible {
    
    let TAG = "ConclaveHost"
    
    public typealias HostType = String
    public typealias HostName = String
    public typealias Port = Int
    
    public var debugDescription: String {
        return "<ConclaveHost> type: \(type) host: \(host) port: \(port)"
    }
    
    public var type: HostType
    public var host: HostName
    public var port: Port
    public var encrypted: Bool = true
    public var compressed: Bool = true
    
    public init(type: HostType, host: HostName, port: Port, encrypted: Bool = true, compressed: Bool = true) {
        self.type = type
        self.host = host
        self.port = port
        self.encrypted = encrypted
        self.compressed = compressed
    }
    
}

extension ConclaveHost: AferoJSONCoding {
    
    static let CoderKeyType = "type"
    static let CoderKeyHost = "host"
    static let CoderKeyPort = "port"
    
    public var JSONDict: AferoJSONCodedType? {
        
        return [
            type(of: self).CoderKeyType: type,
            type(of: self).CoderKeyHost: host,
            type(of: self).CoderKeyPort: port,
        ]
        
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogError("Unable to decode ConclaveHosts.Record, not a dict: \(String(describing: json))", tag: "ConclaveHosts.Record.JSONCoding")
            return nil
        }
        
        guard let
            
            type = jsonDict[type(of: self).CoderKeyType] as? HostType,
            let host = jsonDict[type(of: self).CoderKeyHost] as? HostName,
            let port = jsonDict[type(of: self).CoderKeyPort] as? Port
            
            else {
                
                DDLogError("Unable to decode ConclaveHosts.Record, not a dict: \(String(describing: json))", tag: "ConclaveHosts.Record.JSONCoding")
                return nil
        }
        
        self.init(type: type, host: host, port: port)
    }
}

extension ConclaveHost: Equatable { }

public func ==(lhs: ConclaveHost, rhs: ConclaveHost) -> Bool {
    
    return lhs.compressed == rhs.compressed
        && lhs.encrypted == rhs.encrypted
        && lhs.host == rhs.host
        && lhs.port == rhs.port
        && lhs.type == rhs.type
}

public struct ConclaveHosts: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "<ConcalveHosts> " +
                registry.values
                    .flatMap { $0 }
                    .flatMap { $0.debugDescription }
                    .joined(separator: ", ")
    }
    
    fileprivate var registry: [ConclaveHost.HostType: [ConclaveHost]] = [:]
    
    public init(hosts: [ConclaveHost]) {
        
        for host in hosts {
            if var rarr = registry[host.type] {
                rarr.append(host)
                registry[host.type] = rarr
            } else {
                registry[host.type] = [host]
            }
        }
    }
    
    public func hostsForType(_ type: ConclaveHost.HostType) -> [ConclaveHost] {
        return registry[type] ?? []
    }
    
}

extension ConclaveHosts: AferoJSONCoding {
    
    public var JSONDict: AferoJSONCodedType? {
        return Array(registry.values.flatMap { $0 }.flatMap { $0.JSONDict! })
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard let jsonArr = json as? [[String: Any]] else {
            DDLogError("Unable to decode ConclaveHosts, not an array of objects: \(String(describing: json))", tag: "ConclaveHosts.JSONCoding")
            return nil
        }
        
        guard let hosts: [ConclaveHost] = |<jsonArr else {
            DDLogError("Unable to decode ConclaveHosts (record decoding failed): \(String(describing: json))", tag: "ConclaveHosts.JSONCoding")
            return nil
        }
        
        self.init(hosts: hosts)
        
    }
}

public struct ConclaveAccess: CustomDebugStringConvertible {

    public var TAG: String { return "\(type(of: self))" }
    
    public var conclaveHosts: ConclaveHosts
    public var tokens: [Token]
    
    public var debugDescription: String {
        return "<ConclaveAccess> conclaveHosts: \(conclaveHosts) tokens: \(tokens)"
    }
    
    public struct Token: Hashable, CustomDebugStringConvertible {
        
        public var TAG: String { return "\(type(of: self))" }

        public enum Client: Hashable, CustomDebugStringConvertible {
            
            public var TAG: String { return "\(type(of: self))" }

            case user(userId: String)
            
            public var debugDescription: String {
                
                switch self {
                case let .user(userId):
                    return "Client.User userId: \(userId)"
                }
            }
            
            // MARK: Hashable
            
            public static func ==(lhs: ConclaveAccess.Token.Client, rhs: ConclaveAccess.Token.Client) -> Bool {
                switch (lhs, rhs) {
                case let (.user(luid), .user(ruid)): return luid == ruid
                default:
                    return false
                }
            }
            
            public var hashValue: Int {
                switch self {
                case let .user(userId):
                    return "User".hashValue ^ userId.hashValue
                }
            }
            
        }

        public var token: String
        public var channelId: String
        public var expires: Date
        public var client: Client
        
        public init(token: String, channelId: String, expires: Date, client: Client) {
            self.token = token
            self.channelId = channelId
            self.expires = expires
            self.client = client
        }
        
        public var userId: String? {
            switch client {
            case let .user(userId): return userId
            default: return nil
            }
        }
        
        public var debugDescription: String {
            return "<Token> token: \(token) channelId: \(channelId) expires: \(expires) client: \(client)"
        }
        
        public var hashValue: Int {
            return token.hashValue ^ channelId.hashValue ^ expires.hashValue ^ client.hashValue
        }
        
        public static func ==(lhs: ConclaveAccess.Token, rhs: ConclaveAccess.Token) -> Bool {
            return lhs.client == rhs.client
                && lhs.channelId == rhs.channelId
                && lhs.token == rhs.token
                && lhs.expires == rhs.expires
        }
        
    }

    public var token: Token? { return tokens.first }
}

extension ConclaveAccess.Token: AferoJSONCoding {
    
    static let CoderKeyToken = "token"
    static let CoderKeyChannelId = "channelId"
    static let CoderKeyExpires = "expiresTimestamp"
    static let CoderKeyClient = "client"
    
    public var JSONDict: AferoJSONCodedType? {
        
        return [
            type(of: self).CoderKeyToken: token,
            type(of: self).CoderKeyChannelId: channelId,
            type(of: self).CoderKeyExpires: expires.millisSince1970,
            type(of: self).CoderKeyClient: client.JSONDict!
        ]

    }
    
    public init?(json: AferoJSONCodedType?) {

        guard let
            jsonDict = json as? [String: Any],
            let token = jsonDict[type(of: self).CoderKeyToken] as? String,
            let channelId = jsonDict[type(of: self).CoderKeyChannelId] as? String,
            let expiresTimestamp = jsonDict[type(of: self).CoderKeyExpires] as? NSNumber,
            let client: ConclaveAccess.Token.Client = |<jsonDict[type(of: self).CoderKeyClient]
            else {
                DDLogError("Unable to decode ConclaveAccess.Token: \(String(describing: json))", tag: "ConclaveAccess.Token")
                return nil
        }
        
        
        self.init(token: token, channelId: channelId, expires: Date.dateWithMillisSince1970(expiresTimestamp), client: client)

    }
}

extension ConclaveAccess.Token.Client: AferoJSONCoding {
    
    static let CoderKeyType = "type"
    static let CoderKeyUserId = "userId"
    
    public var JSONDict: AferoJSONCodedType? {
        
        switch self {

        case let .user(userId):
            return [
                type(of: self).CoderKeyType: "user",
                type(of: self).CoderKeyUserId: userId,
            ]

        }
    }

    public init?(json: AferoJSONCodedType?) {

        let TAG = "\(type(of: self))"
        
        guard let
            jsonDict = json as? [String: Any] else {
                DDLogError("Unable to decode ConclaveAccess.Token.Client: \(String(describing: json))", tag: TAG)
                return nil
        }
        
        if let userId = jsonDict[type(of: self).CoderKeyUserId] as? String {
            self = .user(userId: userId)
        } else {
            DDLogError("Unable to decode ConclaveAccess.Token.Client (no deviceId or mobileDeviceId): \(String(describing: json))", tag: TAG)
            return nil
        }
        
    }
}

extension ConclaveAccess: AferoJSONCoding {
    
    static let CoderKeyConclaveHosts = "conclaveHosts"
    static let CoderKeyTokens = "tokens"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyConclaveHosts: conclaveHosts.JSONDict!,
            type(of: self).CoderKeyTokens: tokens.map { return $0.JSONDict! }
        ]
    }

    public init?(json: AferoJSONCodedType?) {
        
        guard let
            jsonDict = json as? [String: Any],
            let hostsJSON = jsonDict[type(of: self).CoderKeyConclaveHosts],
            let conclaveHosts: ConclaveHosts = |<hostsJSON,
            let tokensJson = jsonDict[type(of: self).CoderKeyTokens] as? [AferoJSONCodedType],
            let tokens: [ConclaveAccess.Token] = |<tokensJson else {
                DDLogError("Unable to decode ConclaveAccess: \(String(describing: json))", tag: "ConclaveAccess")
                return nil
        }

        self.init(conclaveHosts: conclaveHosts, tokens: tokens)
    }
    
}

// MARK: - ConclaveMessage

public enum ConclaveMessage: Equatable, CustomDebugStringConvertible {

    
    /// **Send, Receive**. *"Are you there?" "Yes, I am here."*
    ///
    /// At an interval indicated by the heartbeat field in the hello message, the conclave server will send a “heartbeat”. The heartbeat is just a linefeed with no message: the single byte 0x0a.
    ///
    /// You can use the heartbeat to assure yourself that the connection to conclave is still live. If a heartbeat doesn’t appear within a few seconds of the designated time, the TCP connection is probably dead.
    ///
    /// The conclave server expects to receive a heartbeat back in response to each heartbeat it sends. If it doesn’t receive one in within a relatively small time window (usually 30 seconds), it will assume the TCP connection is dead, and disconnect.
    
    case heartbeat
    
    /// **Receive** Server, announce thyself.
    ///
    /// * `version`: the current server version, for debugging information only
    /// * `heartbeat`: number of seconds between heartbeats sent by the server (see below)
    /// * `bufferSize`: maximum bytes this client will accept in a single message
    ///                 (used to limit the linefeed-seeking buffer)
    
    case hello(
        version: String,
        bufferSize: Int,
        heartbeat: Int
    )
    
    /// **Send**. Client, declare thine identity and preferred form of parlee.
    ///
    /// The channel id, device id (or mobile device id), and token are used to
    /// authenticate. A client may only join a channel for an account if they
    /// have a valid token for it, which can be fetched from the service via RPC
    /// or through “link” commands.
    ///
    /// The type is opaque to conclave, except for special type "hub". Hubs must
    /// authenticate using a deviceId. In addition, the postmaster will treat them
    /// differently:
    /// * Hubs not receive certain messages (like decrypted attributes), because
    ///   postmaster assumes they’re uninterested.
    /// * Hubs may broadcast the visibility and connectivity of peripherals, for
    ///   postmaster to track.
    ///
    /// The version is also opaque to conclave, and is stored only for the benefit
    /// of other agents, and debugging. It is not part of OTA.
    ///
    /// Hubs will often not know their own account id when they first connect.
    /// They should use the linking protocol described in “Conclave authentication”
    /// first, before attempting to authenticate to conclave.
    ///
    /// * `channelId`: the id of the channel to join (usually the account id)
    /// * `deviceId`: the hub’s (possibly software) device id
    /// * `mobileDeviceId`: a mobile client’s application id, used for token authentication, but reported to other clients (previously “clientId”)
    /// * `accessToken`: auth token, as fetched from the service
    /// * `type`: agent type (“hub”, “android”, “satellite”, …)
    /// * `version`: for debugging information only
    /// * `trace`: if true, the conclave node will log extra debugging information about this session
    /// * `protocol`: specify a version of the object sync messages; default is 1 for "legacy"
    ///
    /// - note: If the login fails, or the client sends anything but a
    /// correctly-formatted login message, the server will disconnect without
    /// ceremony or error. This is to prevent unsavory characters from poking around.
    
    
    case login(
        channelId: String,
        accessToken: String,
        type: String,
        deviceId: String?,
        mobileDeviceId: String?,
        version: String?,
        trace: Bool?,
        `protocol`: Int?
    )
    
    /// **Receive**. The server has accepted this client.
    ///
    /// The `generation` number is changed each time the conclave node restarts
    /// and resets its sequence number back to zero. Usually this is just the
    /// epoch time (in milliseconds) that the channel was created.
    ///
    /// The current `sequence` number is included to allow an agent to optimize
    /// rapid reconnects. If the agent saw the same sequence number before being
    /// disconnected, and the generation number is the same, it’s “caught up”
    /// and can skip re-synchronizing.
    ///
    /// * `sessionId`: your session ID (see below)
    /// * `generation`: current generation of this conclave node (see below)
    /// * `seq`: sequence # of the last broadcast message
    /// * `channelId`: ID of this channel (for hubs)
    ///
    /// The generation number is changed each time the conclave node restarts
    /// and resets its sequence number back to zero. Usually this is just the
    /// epoch time (in milliseconds) that the channel was created.
    ///
    /// The current sequence number is included to allow an agent to optimize
    /// rapid reconnects. If the agent saw the same sequence number before being
    ///disconnected, and the generation number is the same, it’s “caught up” and
    /// can skip re-synchronizing.
    
    case welcome(
        sessionId: Int,
        seq: Int,
        channelId: String,
        generation: Int64
    )
    
    /// **Receive**. Another agent joined this channel.
    ///
    /// Immediately after sending a welcome message, the server will send a `join` message for each agent that’s already on the channel, including yourself. The `join` fields are identical to the fields in a `login` message.
    ///
    /// Whenever a new agent joins (after authenticating), a new `join` message will be broadcast to the channel.
    ///
    /// * `sessionId`
    /// * `timestamp`: when the session connected
    /// * `type`: agent type (“hub”, “android”, “postmaster”, ...)
    /// * `deviceId`
    /// * `mobileDeviceId`
    /// * `version`
    
    case join(
        sessionId: Int,
        timestamp: Int,
        type: String,
        deviceId: String?,
        mobileDeviceId: String?,
        version: String?
    )
    
    /// **Receive**. Another agent left this channel.
    ///
    /// The type, deviceId, and mobileDeviceId fields are superfluous but may be useful for debugging.
    ///
    /// An agent may “leave” implicitly at any time by disconnecting. It may also leave explicitly by saying goodbye. The bye message has no fields. Conclave responds by disconnecting.
    ///
    /// * `sessionId`
    /// * `timestamp`: unix epoch, seconds; representing *now*.
    /// * `type`
    /// * `deviceId`
    /// * `mobileDeviceId`
    
    case leave(
        sessionId: Int,
        timestamp: Int,
        type: String,
        deviceId: String?,
        mobileDeviceId: String?
    )
    
    /// **Send**. Gracefully leave the channel.
    /// An agent may “leave” implicitly at any time by disconnecting.
    /// It may also leave explicitly by saying `bye`. The bye message has
    /// no fields. Conclave responds by disconnecting.
    
    case bye
    
    /// **Send**. For debugging or resynchronizing, an agent may ask for the list of
    /// connected agents to be re-sent. Like bye, the who message has no fields.
    /// The server will immediately respond with a join for each connected agent.

    case who
    
    /// **Send**. Post a messge to the channel.
    ///
    /// To post a message to the broadcast channel, an agent sends a say
    /// message to the server. The server sends all broadcast messages to all
    /// agents using a public message.
    ///
    /// * `event`: name of the event, defined by the higher-level protocol
    /// * `data`: - any associated data for the event
    
    case say(
        event: String,
        data: Any?
    )
    
    /// **Receive**. A public message broadcast to all agents on the channel.
    ///
    /// * `seq`: number that increments by at least 1 for each post
    /// * `sessionId`: the session ID of the agent that posted this message
    /// * `event`: copied directly from the say message
    /// * `data`: copied directly from the say message
    ///
    /// Sequence numbers:
    /// * are assigned and sent only by the conclave server
    /// * apply to `public` and (some) `private` messages
    /// * may "skip" numbers for `private` messages that weren't targeted at you
    /// * are in the range [0, 231 - 1]
    /// * roll over at 231 - 1 as if they were stored in an unsigned 31-bit register
    /// * are per-channel (that is, per-account)
    ///
    /// - note: If the sequence number in the welcome message is *N*, the next
    ///         public or private message will be sequence number *N+1* (or greater).
    
    case `public`(
        seq: Int,
        sessionId: Int,
        event: String,
        data: [String: Any]
    )
    
    /// **Send**. Publish a message to another session
    /// * `sessionId`: target of the private message
    /// * `type`: target, if the target is a group of related sessions
    /// * `event`
    /// * `data`
    
    case whisper(
        sessionId: Int?,
        type: String?,
        event: String,
        data: Any
    )
    
    /// **Receive**. Receive a private message sent by the service or `whisper`ed by
    /// another agent.
    ///
    /// * `seq`: same as in public, but only applied to messages with more than one recipient
    /// * `sessionId`: source of the private message
    /// * `target`: group this message was sent to, if it was sent to a group
    /// * `event`
    /// * `data`
    
    case `private`(
        seq: Int?,
        sessionId: Int,
        target: String?,
        event: String,
        data: [String: Any]
    )
    
    /// **Receive**. Confirmation that the server has received a `whisper`.
    ///
    /// When a private message has been written to each session, a `whisper`ed
    /// message is delivered to the sender. It doesn’t guarantee that any session
    /// has read the message, just that conclave received and handled it.
    ///
    /// * `sessionIds`: An array of `sessionId`s identifying the targets of the
    ///                 associated `whisper`.
    
    case whispered(
        sessionIds: [Int]
    )
    
    /// **Send**. Ping the server to confirm it's still there.
    /// * `data`: Any data; will be `echo`ed back to the agent.
    
    case ping(data: Any?)
    
    /// **Receive**. Response to a `ping`.
    /// * `data`: The `data` from the associated `ping`, echoed back.
    case echo(data: Any?)
    
    /// ** Receive**. An error message may be sent by the server if the
    /// client sends something confusing or bad after successfully authenticating.
    ///
    /// * `code`: The error code
    /// * `message`: For debugging, not for user display
    /// * `deviceId`: the responsible device id for code `912`
    /// * `requestId`: the associated request id if there was one
    
    case error(
        code: Int,
        message: String
    )
    
    public init() {
        self = .heartbeat
    }
    
    public var debugDescription: String {
        switch(self) {

        case let .hello(version, bufferSize, heartbeat):
            return "<ConclaveMessage.Hello> version: \(version) bufferSize: \(bufferSize), hearbeat: \(heartbeat)"

        case let .login(channelId, accessToken, type, deviceId, mobileDeviceId, version, trace, `protocol`):
        return "<ConclaveMessage.Login> channelId:\(channelId) accessToken:\(accessToken) type:\(type) deviceId:\(String(describing: deviceId)) mobileDeviceId:\(String(describing: mobileDeviceId)) version:\(String(describing: version)) trace:\(String(describing: trace)) protocol:\(String(describing: `protocol`))"
            
        case let .welcome(sessionId, seq, channelId, generation):
            return "<ConclaveMessage.Welcome> sessionId: \(sessionId) seq: \(seq) accountId: \(channelId) generation: \(generation)"
        
        case let .join(sessionId, timestamp, type, deviceId, mobileDeviceId, version):
            return "<ConclaveMessage.Join> sessionId: \(sessionId) timestamp: \(timestamp) type: \(type) deviceId: \(String(describing: deviceId)) clientId: \(String(describing: mobileDeviceId)) version: \(String(describing: version))"
            
        case let .leave(sessionId, timestamp, type, deviceId, mobileDeviceId):
            return "<ConclaveMessage.Leave> sessionId: \(sessionId) timestamp: \(timestamp) type: \(type) deviceId: \(String(describing: deviceId)) clientId: \(String(describing: mobileDeviceId))"
            
        case .bye: return "<ConclaveMessage.Bye>"
            
        case .who: return "<ConclaveMessage.Who>"
            
        case .heartbeat: return "<ConclaveMessage.Heartbeat>"
            
        case let .say(event, data):
            return "<ConclaveMessage.Say> event: \(event) data: \(String(describing: data))"
            
        case let .public(seq, sessionId, event, data):
            return "<ConclaveMessage.Public> seq: \(seq) sessionId: \(sessionId) event: \(event) data: \(data)"

        case let .whisper(sessionId, type, event, data):
            return "<ConclaveMessage.Whisper> sessionId: \(String(describing: sessionId)) type: \(String(describing: type)) sender: event: \(event) data: \(data)"
            
        case let .private(seq, sessionId, target, event, data):
            return "<ConclaveMessage.Private> seq: \(String(describing: seq)) sessionId: \(sessionId) target: \(String(describing: target)) event: \(event) data: \(data)"
            
        case let .whispered(sessionIds):
            return "<ConclaveMessage.Whispered> sessionId: \(String(describing: sessionIds))"
            
        case let .ping(data):
            return "<ConclaveMessage.Ping> data: \(String(describing: data))"
            
        case let .echo(data):
            return "<ConclaveMessage.Echo> data: \(String(describing: data))"
            
        case let .error(code, message):
            return "<ConclaveMessage.Error> code: \(code) message: \(message)"
            
        }
    }
}

// TODO: Nuke lying equality (see .Public and .Private, below)

public func ==(lhs: ConclaveMessage, rhs: ConclaveMessage) -> Bool {
    switch (lhs, rhs) {

    case let (.hello(lversion, lbufsz, lhb), .hello(rversion, rbufsz, rhb)):
        return lversion == rversion && lhb == rhb && lbufsz == rbufsz
        
    case let (.login(lcid, lat, ltype, ldid, lmdid, lvers, ltrace, lproto), .login(rcid, rat, rtype, rdid, rmdid, rvers, rtrace, rproto)):
        return lcid == rcid && lat == rat && ltype == rtype && ldid == rdid && lmdid == rmdid && lvers == rvers && ltrace == rtrace && lproto == rproto

    case let (.welcome(lsid, lseq, lcid, lgen), .welcome(rsid, rseq, rcid, rgen)):
        return lsid == rsid && lseq == rseq && lcid == rcid && lgen == rgen
        
    case let (.join(lsid, lts, lt, ldid, lmid, lv), .join(rsid, rts, rt, rdid, rmid, rv)):
        return lsid == rsid && lts == rts && lt == rt && ldid == rdid && lmid == rmid && lv == rv
        
    case let (.leave(lsid, lts, lt, ldid, lcid), .leave(rsid, rts, rt, rdid, rcid)):
        return lsid == rsid && lts == rts && lt == rt && ldid == rdid && lcid == rcid
        
    case (.bye, .bye): fallthrough
    case (.who, .who): fallthrough
    case (.heartbeat, .heartbeat):
        return true
        
    case (.ping, .ping): fallthrough
    case (.echo, .echo):
        // This is a lie, since the data field is a [String:Any and cannot be compared at the moment.
        return true

    case let (.say(levt, _), .say(revt, _)):
        return levt == revt
        
    case let (.public(_, lsnd, levt, _), .public(_, rsnd, revt, _)):
        // This is a lie, since the data field is a [String:Any and cannot be compared at the moment.
        return lsnd == rsnd && levt == revt

    case let (.whisper(lsid, ltype,levt, _), .whisper(rsid, rtype, revt, _)):
        // This is a lie, since the data field is a [String:Any and cannot be compared at the moment.
        return lsid == rsid && ltype == rtype && levt == revt

    case let (.whispered(lsids), .whispered(rsids)):
        return lsids == rsids

    case let (.private(lseq, lsid, ltrg, levt, _), .private(rseq, rsid, rtrg, revt, _)):
        // This is a lie, since the data field is a [String:Any and cannot be compared at the moment.
        return  lseq == rseq && lsid == rsid && ltrg == rtrg && levt == revt
        
    case let (.error(lc, lmsg), .error(rc, rmsg)):
        return lc == rc && lmsg == rmsg
        
    default:
        return false

    }
}

extension ConclaveMessage: AferoJSONCoding {
    
    static let TAG = "ConclaveMessage"
    
    static let CoderMessageNameHello = "hello"
    static let CoderKeyVersion = "version"
    static let CoderKeyTrace = "trace"
    static let CoderKeyBufferSize = "bufferSize"
    static let CoderKeyHeartbeat = "heartbeat"
    
    static let CoderMessageNameWelcome = "welcome"
    static let CoderKeySessionId = "sessionId"
    static let CoderKeySeq = "seq"
    static let CoderKeyAccountId = "accountId"
    static let CoderKeyChannelId = "channelId"
    static let CoderKeyGeneration = "generation"
    
    static let CoderMessageNameLogin = "login"
    static let CoderKeyToken = "token"
    static let CoderKeyAccessToken = "accessToken"
    static let CoderKeyType = "type"
    static let CoderKeyDeviceId = "deviceId"
    static let CoderKeyMobileDeviceId = "mobileDeviceId"
    static let CoderKeyProtocol = "protocol"
    
    static let CoderMessageNameJoin = "join"
    static let CoderKeyTimestamp = "timestamp"
    
    static let CoderMessageNameLeave = "leave"
    
    static let CoderMessageNameBye = "bye"
    
    static let CoderMessageNameWho = "who"
    
    static let CoderMessageNamePublic = "public"
    static let CoderKeyTarget = "target"
    static let CoderKeyEvent = "event"
    static let CoderKeyData = "data"

    static let CoderMessageNamePrivate = "private"
    
    static let CoderMessageNameSay = "say"
    static let CoderMessageNameWhisper = "whisper"
    static let CoderMessageNameWhispered = "whispered"
    static let CoderMessageNamePing = "ping"
    static let CoderMessageNameEcho = "echo"
    static let CoderMessageNameError = "error"
    
    static let CoderKeyCode = "code"
    static let CoderKeyMessage = "message"

    public var JSONDict: AferoJSONCodedType? {

        switch(self) {

        case let .hello(version, bufferSize, heartbeat):
            let body: AferoJSONCodedType = [
                type(of: self).CoderKeyVersion: version,
                type(of: self).CoderKeyBufferSize: bufferSize,
                type(of: self).CoderKeyHeartbeat: heartbeat,
            ]
            return [type(of: self).CoderMessageNameHello: body]
            
        case let .login(channelId, accessToken, type, deviceId, mobileDeviceId, version, trace, proto):
            
            var body: AferoJSONObject = [
                type(of: self).CoderKeyChannelId: channelId,
                type(of: self).CoderKeyAccessToken: accessToken,
                type(of: self).CoderKeyType: type,
            ]
            
            if let deviceId = deviceId {
                body[type(of: self).CoderKeyDeviceId] = deviceId
            }
            
            if let mobileDeviceId = mobileDeviceId {
                body[type(of: self).CoderKeyMobileDeviceId] = mobileDeviceId
            }
            
            if let version = version {
                body[type(of: self).CoderKeyVersion] = version
            }
            
            if let trace = trace {
                body[type(of: self).CoderKeyTrace] = trace
            }
            
            if let proto = proto {
                body[type(of: self).CoderKeyProtocol] = proto
            }

            return [type(of: self).CoderMessageNameLogin: body]
        
        case let .welcome(sessionId, seq, channelId, generation):
            let body: AferoJSONCodedType = [
                type(of: self).CoderKeySessionId: sessionId,
                type(of: self).CoderKeySeq: seq,
                type(of: self).CoderKeyChannelId: channelId,
                type(of: self).CoderKeyGeneration: NSNumber(value: generation),
            ]
            return [type(of: self).CoderMessageNameWelcome: body]
            
        case let .join(sessionId, timestamp, type, deviceId, mobileDeviceId, version):
            
            var body: AferoJSONObject = [
                type(of: self).CoderKeySessionId: sessionId,
                type(of: self).CoderKeyTimestamp: timestamp,
                type(of: self).CoderKeyType: type,
            ]
            
            if let deviceId = deviceId {
                body[type(of: self).CoderKeyDeviceId] = deviceId
            }

            if let mobileDeviceId = mobileDeviceId {
                body[type(of: self).CoderKeyMobileDeviceId] = mobileDeviceId
            }

            if let version = version {
                body[type(of: self).CoderKeyVersion] = version
            }
            
            return [type(of: self).CoderMessageNameJoin: body]
            
        case let .leave(sessionId, timestamp, type, deviceId, mobileDeviceId):
            
            var body: AferoJSONObject = [
                type(of: self).CoderKeySessionId: sessionId,
                type(of: self).CoderKeyTimestamp: timestamp,
                type(of: self).CoderKeyType: type,
            ]
            
            if let deviceId = deviceId {
                body[type(of: self).CoderKeyDeviceId] = deviceId
            }
            
            if let mobileDeviceId = mobileDeviceId {
                body[type(of: self).CoderKeyMobileDeviceId] = mobileDeviceId
            }
            
            return [type(of: self).CoderMessageNameLeave: body]
            
        case .bye:
            return [type(of: self).CoderMessageNameBye: [:]]
            
        case .who:
            return [type(of: self).CoderMessageNameWho: [:]]
            
        case let .say(event, data):

            var body: AferoJSONObject = [
                type(of: self).CoderKeyEvent: event,
                type(of: self).CoderKeyData: data ?? [:]
            ]
            
            if let data: Any = data {
                body[type(of: self).CoderKeyData] = data
            }
            
            return [type(of: self).CoderMessageNameSay: body]
            
        case let .public(seq, sessionId, event, data):

            let body: AferoJSONObject = [
                type(of: self).CoderKeySessionId: sessionId,
                type(of: self).CoderKeyEvent: event,
                type(of: self).CoderKeyData: data,
                type(of: self).CoderKeySeq: seq,
            ]
            
            return [type(of: self).CoderMessageNamePublic: body]
            
        case let .whisper(sessionId, type, event, data):

            var body: AferoJSONObject = [
                type(of: self).CoderKeyEvent: event,
                type(of: self).CoderKeyData: data,
            ]
            
            if let sessionId = sessionId {
                body[type(of: self).CoderKeySessionId] = sessionId
            }

            if let type = type {
                body[type(of: self).CoderKeyType] = type
            }
            
            return [type(of: self).CoderMessageNameWhisper: body]
            
        case let .private(seq, sessionId, target, event, data):

            var body: [String: Any] = [
                type(of: self).CoderKeySessionId: sessionId,
                type(of: self).CoderKeyEvent: event,
                type(of: self).CoderKeyData: data,
            ]
            
            if let seq = seq {
                body[type(of: self).CoderKeySeq] = seq
            }
            
            if let target = target {
                body[type(of: self).CoderKeyTarget] = target
            }
            
            return [type(of: self).CoderMessageNamePrivate: body]

        case let .whispered(sessionIds):

            let body: [String: Any] = [
                type(of: self).CoderKeySessionId: sessionIds
            ]
            
            return [type(of: self).CoderMessageNameWhispered: body]

        case let .ping(obj):
            
            var body: AferoJSONObject = [:]
            if let obj: Any = obj {
                body[type(of: self).CoderKeyData] = obj
            }
            
            return [type(of: self).CoderMessageNamePing: body]

        case let .echo(obj):
            
            var body: AferoJSONObject = [:]
            if let obj: Any = obj {
                body[type(of: self).CoderKeyData] = obj
            }
            
            return [type(of: self).CoderMessageNameEcho: body]

        case let .error(code, message):

            let body: AferoJSONCodedType = [
                type(of: self).CoderKeyCode: code,
                type(of: self).CoderKeyMessage: message,
            ]
            
            return [type(of: self).CoderMessageNameError: body]
            
        case .heartbeat: fallthrough
        default:
            return nil
            
        }
    }
    
    public init?(json: AferoJSONCodedType?) {

        if let json = json as? AferoJSONObject {
            
            if let hello = json[type(of: self).CoderMessageNameHello] as? [String: Any] {
                
                if let
                    version = hello[type(of: self).CoderKeyVersion] as? String,
                    let bufferSize = hello[type(of: self).CoderKeyBufferSize] as? Int,
                    let heartbeat = hello[type(of: self).CoderKeyHeartbeat] as? Int {
                        self = .hello(version: version, bufferSize: bufferSize, heartbeat: heartbeat)
                } else {
                    DDLogError("Unable to decode hello: \(hello)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let login = json[type(of: self).CoderMessageNameLogin] as? [String: Any] {
                
                if let
                    channelId = login[type(of: self).CoderKeyChannelId] as? String,
                    let accessToken = login[type(of: self).CoderKeyAccessToken] as? String,
                    let type = login[type(of: self).CoderKeyType] as? String {
                        let deviceId = login[type(of: self).CoderKeyDeviceId] as? String
                        let mobileDeviceId = login[type(of: self).CoderKeyMobileDeviceId] as? String
                        let version = login[type(of: self).CoderKeyVersion] as? String
                        let trace = login[type(of: self).CoderKeyTrace] as? Bool
                        let proto = login[type(of: self).CoderKeyProtocol] as? Int

                    self = .login(channelId: channelId, accessToken: accessToken, type: type, deviceId: deviceId, mobileDeviceId: mobileDeviceId, version: version, trace: trace, protocol: proto)
                    
                } else {
                    DDLogError("Unable to decode login: \(login)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let welcome = json[type(of: self).CoderMessageNameWelcome] as? [String: Any] {
                
                // This is only in place to migrate from accountId -> channelId
                
                let channelId = welcome[type(of: self).CoderKeyChannelId] as? String
                let accountId = welcome[type(of: self).CoderKeyAccountId] as? String
                
                if let
                    sessionId = welcome[type(of: self).CoderKeySessionId] as? Int,
                    let seq = welcome[type(of: self).CoderKeySeq] as? Int,
                    let channelId = channelId ?? accountId,
                    let generation = welcome[type(of: self).CoderKeyGeneration] as? NSNumber {
                        self = .welcome(sessionId: sessionId, seq: seq, channelId: channelId, generation: generation.int64Value)
                } else {
                    DDLogError("Unable to decode welcome: \(welcome)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let leave = json[type(of: self).CoderMessageNameLeave] as? [String: Any] {
                
                if let
                    sessionId = leave[type(of: self).CoderKeySessionId] as? Int,
                    let timestamp = leave[type(of: self).CoderKeyTimestamp] as? Int,
                    let type = leave[type(of: self).CoderKeyType] as? String {
                        let deviceId = leave[type(of: self).CoderKeyDeviceId] as? String
                        let mobileDeviceId = leave[type(of: self).CoderKeyMobileDeviceId] as? String
                        self = .leave(sessionId: sessionId, timestamp: timestamp, type: type, deviceId: deviceId, mobileDeviceId: mobileDeviceId)
                } else {
                    DDLogError("Unable to decode leave: \(leave)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let join = json[type(of: self).CoderMessageNameJoin] as? [String: Any] {
                
                if let
                    sessionId = join[type(of: self).CoderKeySessionId] as? Int,
                    let timestamp = join[type(of: self).CoderKeyTimestamp] as? Int,
                    let type = join[type(of: self).CoderKeyType] as? String {
                        let deviceId = join[type(of: self).CoderKeyDeviceId] as? String
                        let mobileDeviceId = join[type(of: self).CoderKeyMobileDeviceId] as? String
                        let version = join[type(of: self).CoderKeyVersion] as? String
                        self = .join(sessionId: sessionId, timestamp: timestamp, type: type, deviceId: deviceId, mobileDeviceId: mobileDeviceId, version: version)
                } else {
                    DDLogError("Unable to decode join: \(join)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let _: Any = json[type(of: self).CoderMessageNameBye] as Any? {
                
                self = .bye
                
            } else if let _: Any = json[type(of: self).CoderMessageNameWho] as Any? {
                
                self = .who
                
            } else if let say = json[type(of: self).CoderMessageNameSay] as? [String: Any] {
                
                if let event = say[type(of: self).CoderKeyEvent] as? String {
                    let data: Any? = say[type(of: self).CoderKeyData]
                    self = .say(event: event, data: data)
                } else {
                    DDLogError("Unable to decode say: \(say)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let ppublic = json[type(of: self).CoderMessageNamePublic] as? [String: Any] {
                
                if let
                    sessionId = ppublic[type(of: self).CoderKeySessionId] as? Int,
                    let event = ppublic[type(of: self).CoderKeyEvent] as? String,
                    let data = ppublic[type(of: self).CoderKeyData] as? [String: Any],
                    let seq = ppublic[type(of: self).CoderKeySeq] as? Int {
                        self = .public(seq: seq, sessionId: sessionId, event: event, data: data)
                } else {
                    DDLogError("Unable to decode public: \(ppublic)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let whisper = json[type(of: self).CoderMessageNameWhisper] as? [String: Any] {
                
                if
                    let event = whisper[type(of: self).CoderKeyEvent] as? String,
                    let data = whisper[type(of: self).CoderKeyData] as? [String: Any] {
                        let sessionId = whisper[type(of: self).CoderKeySessionId] as? Int
                        let type = whisper[type(of: self).CoderKeyType] as? String
                        self = .whisper(sessionId: sessionId, type: type, event: event, data: data)
                } else {
                    DDLogError("Unable to decode whisper: \(whisper)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if
                let whispered = json[type(of: self).CoderMessageNameWhispered] as? [String: Any],
                let sessionIds = whispered[type(of: self).CoderKeySessionId] as? [Int] {
                self = .whispered(sessionIds: sessionIds)
                
            } else if let pprivate = json[type(of: self).CoderMessageNamePrivate] as? [String: Any] {
                
                if
                    let sessionId = pprivate[type(of: self).CoderKeySessionId] as? Int,
                    let event = pprivate[type(of: self).CoderKeyEvent] as? String,
                    let data = pprivate[type(of: self).CoderKeyData] as? [String: Any] {
                        let seq = pprivate[type(of: self).CoderKeySeq] as? Int
                        let target = pprivate[type(of: self).CoderKeyTarget] as? String
                    self = .private(seq: seq, sessionId: sessionId, target: target, event: event, data: data)
                } else {
                    DDLogError("Unable to decode private: \(pprivate)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else if let ping = json[type(of: self).CoderMessageNamePing] as? [String: Any] {
                
                self = .ping(data: ping[type(of: self).CoderKeyData])
                
            } else if let echo = json[type(of: self).CoderMessageNameEcho] as? [String: Any] {
                
                self = .echo(data: echo[type(of: self).CoderKeyData])
                
            } else if let error = json[type(of: self).CoderMessageNameError] as? [String: Any] {
                
                if let
                    code = error[type(of: self).CoderKeyCode] as? Int,
                    let message = error[type(of: self).CoderKeyMessage] as? String {
                        self = .error(code: code, message: message)
                } else {
                    DDLogError("Unable to decode error: \(error)", tag: type(of: self).TAG)
                    return nil
                }
                
            } else {
                return nil
            }
            
        } else {
            self = .heartbeat
        }
    }
}
