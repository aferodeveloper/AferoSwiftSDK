//
//  DeviceEventStreamEvent.swift
//  Pods
//
//  Created by Justin Middleton on 5/22/17.
//
//

import Foundation
import CocoaLumberjack


/// Describes a kind of invalidate envent that can be received.

public struct InvalidationEvent: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return "<InvalidationEvent.\(kind.rawValue)> info: \(String(describing: info))"
    }

    public var debugDescription: String {
        return "<InvalidationEvent.\(kind.rawValue)> info: \(String(reflecting: info))"
    }

    public enum Kind: String {
        
        /// Accounts were invalidated. This is received when a the accounts to which a
        /// given user has access changes.
        case accounts = "accounts"
        
        /// The user's pending sharing invitations list was invalidated. This is received
        /// when a user is invited to share an account, or when an invitation is rescinded.
        case invitations = "invitations"
        
        /// Profiles have been invalidate for a device.
        case profiles = "profiles"
        
        /// A device's location has been invalidated.
        case location = "location"
        
        /// A device's timezone has been invalidate.
        case timezone = "timezone"
        
        /// A device's tags have been invalidated. This is received when a tag has
        /// been added to a device, removed from a device, or updated.
        case tags = "tags"
        
        public init?(notificationName: String) {
            switch notificationName {
            case Kind.accounts.notificationName: self = .accounts
            case Kind.invitations.notificationName: self = .invitations
            case Kind.profiles.notificationName: self = .profiles
            case Kind.location.notificationName: self = .location
            case Kind.tags.notificationName: self = .tags
            default: return nil
            }
        }
        
        public var notificationName: String {
            switch self {
            case .accounts: return "InvalidationKindAccounts"
            case .invitations: return "InvalidationKindInvitations"
            case .profiles: return "InvalidationKindProfiles"
            case .location: return "InvalidationKindLocation"
            case .timezone: return "InvalidationKindTimeZone"
            case .tags: return "InvalidationKindTags"
            }
        }
        
    }
    
    /// The kind of invalidation event.
    public var kind: Kind
    
    public typealias EventInfo = [String: Any]
    public var info: EventInfo?
    
    public init(kind: Kind, info: EventInfo? = nil) {
        self.kind = kind
        self.info = info
    }
    
    public init?(kind: Kind.RawValue, info: EventInfo? = nil) {
        guard let kind = Kind(rawValue: kind) else {
            return nil
        }
        self.kind = kind
        self.info = info
    }

}

// MARK: - DeviceStreamEvent

/// An event related to a device  in the stream. Note that this covers
/// Object Sync V2.0 (https://docs.google.com/document/d/1inMJ2AdM-q4W-YXl2nZUCZzGuDW5xKaCMWYgN1Q9qHg/edit#heading=h.pyws1ms1vhet).

public enum DeviceStreamEvent: CustomStringConvertible, CustomDebugStringConvertible {
    
    /// A snapshot of peripherals and their state at the time of receipt.
    /// * `peripherals`: The peripherals and their states.
    /// * `currentSeq`: The conclave channel's current sequence number at the time of receipt.
    
    case peripheralList(peripherals: [Peripheral], currentSeq: DeviceStreamEventSeq)

    /// An attribute state has changed on a device.
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected
    /// * `requestId`: The id of the request that originated the change (returned as part of
    ///                a successful attribute write on the restful API).
    /// * `state`: The error code, or `0` for no error, from the peripheral.
    /// * `reason`: The reason code for the error, if any.
    /// * `attribute`: The `Peripheral.Attribute` value representing the new value
    ///                of the attribute.
    /// * `sourceHubId`: The hub which relayed the message, if any.
    
    case attributeChange(seq: DeviceStreamEventSeq?, peripheralId: String, requestId: Int, state: Peripheral.UpdateState?, reason: Peripheral.UpdateReason?, attribute: Peripheral.Attribute, sourceHubId: String?)
    
    /// A device's status has changed.
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected.
    /// * `status`: The new status of the peripheral.
    
    case statusChange(seq: DeviceStreamEventSeq?, peripheralId: String, status: Peripheral.Status)
    
    /// An OTA is available for the device.
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected.
    /// * `packageInfos`: An array of `OTAPackageInfo` instances for the device. See `DeviceStreamEvent.OTAPackageInfo`.
    
    case deviceOTA(seq: DeviceStreamEventSeq?, peripheralId: String, packageInfos: [OTAPackageInfo])
    
    /// OTA progress has been updated for a device.
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected.
    /// * `state`: The state of the OTA
    /// * `offset`: The offset of the OTA
    /// * `total`: The total expected bytes of the OTA
    
    case deviceOTAProgress(seq: DeviceStreamEventSeq?, peripheralId: String, progress: OTAProgress)
    
    /// Some aspect of the stream has been invalidated, and needs to be refetched.
    ///
    /// This is an informational message, and clients may need to do additional work
    /// to resolve the invalidation. See `InvalidationEventKind`.
    ///
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected, if any (not all invalidation
    ///                   events relate specifically to devices).
    /// * `kind`: The type of the invalidation event. See `InvalidationEventKind`.
    /// * `data`: The raw data provided in the message.
    
    case invalidate(seq: DeviceStreamEventSeq?, peripheralId: String?, kind: InvalidationEvent.Kind.RawValue, data: DeviceStreamEventData)

    /// An error was encountered for a device.
    ///
    /// If a command (“write”) sent to a peripheral fails, the peripheral may
    /// send back an error message. The hub broadcasts this message back to the
    /// channel. Note that “write” commands are sent by clients through the
    /// client API, not via conclave.
    ///
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected.
    /// * `error`: The error encountered.
    ///
    /// - warning: This is an attempt to document current hub behavior. It may change.
    
    case deviceError(seq: DeviceStreamEventSeq?, peripheralId: String, error: DeviceError)
    
    /// The device has been throttled for the given duration.
    ///
    /// If a peripheral is being "too chatty" according to some rate limit set
    /// by conclave (and subject to change), it may cause conclave to start
    /// ignoring it. When this happens, a "mute" event will be broadcast,
    /// asking all hubs to squelch traffic from this peripheral until the
    /// timeout has passed. Usually, the timeout is the time remaining in
    /// the current rate-limit period, so it will be less than one minute.
    ///
    /// * `seq`: The sequence number of the change, if any.
    /// * `peripheralId`: The id of the peripheral affected.
    /// * `timeout`: The duration of the mute.
    
    case deviceMute(seq: DeviceStreamEventSeq?, peripheralId: String, timeout: TimeInterval)
    
    init?(name: DeviceStreamEventName, seq: DeviceStreamEventSeq? = nil, data: DeviceStreamEventData, target: DeviceStreamEventTarget? = nil) {
        
        let TAG = "DeviceStreamEvent"
        
        guard let canonicalName = Name(rawValue: name) else {
            DDLogWarn("Unrecognized stream event name \(name)")
            //            assertionFailure("Unrecognized stream event name \(name)")
            return nil
        }
        
        switch canonicalName {
            
        case .peripheralList:
            
            guard
                let peripherals: [Peripheral] = |<(data["peripherals"] as? [[String: Any]]),
                let currentSeq = data["currentSeq"] as? Int else {
                    DDLogError("Unable to extract peripherals from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            self = .peripheralList(peripherals: peripherals, currentSeq: currentSeq)
            
        case .attributeChange:
            
            guard
                let peripheralId = data["id"] as? String,
                let requestId = data["requestId"] as? Int,
                let attribute: Peripheral.Attribute = |<data["attribute"] else {
                    DDLogError("Unable to extract attrChange from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            let state = Peripheral.UpdateState(maybeStateCode: data["state"] as? Int)
            let reason = Peripheral.UpdateReason(maybeReasonCode: data["reason"] as? Int)
            let sourceHubId = data["sourceHubId"] as? String
            
            self = .attributeChange(seq: seq, peripheralId: peripheralId, requestId: requestId, state: state, reason: reason, attribute: attribute, sourceHubId: sourceHubId)
            
        case .statusChange:
            
            guard
                let peripheralId = data["id"] as? String,
                let status: Peripheral.Status = |<data["status"] else {
                    DDLogError("Unable to extract statusChange from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            self = .statusChange(seq: seq, peripheralId: peripheralId, status: status)
            
        case .deviceOTA:
            guard
                let peripheralId = data["id"] as? String,
                let packageInfos: [OTAPackageInfo] = |<(data["packageInfos"] as? [[String: Any]]) else {
                    DDLogError("Unable to extract deviceOta from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            self = .deviceOTA(seq: seq, peripheralId: peripheralId, packageInfos: packageInfos)
            
        case .deviceOTAProgress:
            guard
                let peripheralId = data["id"] as? String,
                let state = data["state"] as? OTAProgress.State.IntegerLiteralType,
                let offset = data["offset"] as? Int,
                let total = data["total"] as? Int else {
                    DDLogError("Unable to extract deviceOtaProgress from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            guard let progress = OTAProgress(state: state, offset: offset, total: total) else {
                DDLogError("Unable to instantiate OTAProgress from (state:\(state) offset:\(offset) total:\(total)")
                return nil
            }
            
            self = .deviceOTAProgress(
                seq: seq,
                peripheralId: peripheralId,
                progress: progress
            )
            
        case .invalidate:
            guard
                let kind = data["kind"] as? InvalidationEvent.Kind.RawValue else {
                    DDLogError("Unable to extract Invalidate from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            let peripheralId = (data["deviceId"] as? String) ?? (data["id"] as? String)
            self = .invalidate(seq: seq, peripheralId: peripheralId, kind: kind, data: data)

        case .deviceError:
            
            guard
                let event = data["event"] as? String,
                let peripheralId = data["id"] as? String,
                let status = data["status"] as? String,
                let channelId = data["channelId"] as? Int,
                let requestId = data["requestId"] as? Int else {
                    DDLogError("Unable to extract DeviceError from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            self = .deviceError(
                seq: seq,
                peripheralId: peripheralId,
                error: DeviceError(
                    event: event,
                    peripheralId: peripheralId,
                    status: status,
                    channelId: channelId,
                    requestId: requestId
                )
            )
            
        case .deviceMute:
            guard
                let peripheralId = data["id"] as? String,
                let timeoutMillis = data["timeout"] as? Int64 else {
                    DDLogError("Unable to extract DeviceMute from \(String(reflecting: data))", tag: TAG)
                    return nil
            }
            
            let timeout = TimeInterval(timeoutMillis) / 1000.0
            
            self = .deviceMute(seq: seq, peripheralId: peripheralId, timeout: timeout)
        }
        
    }

    public var enumeratedName: Name {
        switch self {
        case .peripheralList: return .peripheralList
        case .attributeChange: return .attributeChange
        case .statusChange: return .statusChange
        case .deviceOTA: return .deviceOTA
        case .deviceOTAProgress: return .deviceOTAProgress
        case .invalidate: return .invalidate
        case .deviceError: return .deviceError
        case .deviceMute: return .deviceMute
        }
    }
    
    public var name: String {
        return enumeratedName.rawValue
    }
    
    public var seq: DeviceStreamEventSeq? {
        switch self {
        case let .peripheralList(_, seq): return seq
        case let .attributeChange(seq, _, _, _, _, _, _): return seq
        case let .statusChange(seq, _, _): return seq
        case let .deviceOTA(seq, _, _): return seq
        case let .deviceOTAProgress(seq, _, _): return seq
        case let .invalidate(seq, _, _, _): return seq
        case let .deviceError(seq, _, _): return seq
        case let .deviceMute(seq, _, _): return seq
        }
    
    }
    
    // MARK: <CustomStringConvertible>
    
    public var description: String {
        return "\(name): seq:\(String(describing: seq))"
    }
    
    // MARK: <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        
        let verboseString: String
        
        switch self {
            
        case let .peripheralList(peripherals, _):
            verboseString = "peripherals:\(String(describing: peripherals))"
            
        case let .attributeChange(_, peripheralId, requestId, state, reason, attribute, sourceHubId):
            verboseString = "peripheralId:\(String(describing: peripheralId)) reqId:\(String(describing: requestId)) state:\(String(describing: state)) reason:\(String(describing: reason)) attribute:\(String(describing: attribute)) sourceHubId:\(String(describing: sourceHubId))"
            
        case let .statusChange(_, peripheralId, status):
            verboseString = "peripheralId:\(String(describing: peripheralId)) status:\(String(describing: status))"
            
        case let .deviceOTA(_, peripheralId, packageInfo):
            verboseString = "peripheralId:\(String(describing: peripheralId)) packageInfo:\(String(describing: packageInfo))"
            
        case let .deviceOTAProgress(_, peripheralId, progress):
            verboseString = "peripheralId:\(String(describing: peripheralId)) progress:\(String(describing: progress))"
            
        case let .invalidate(_, maybePeripheralId, kind, data):
            verboseString = "peripheralId:\(String(describing: maybePeripheralId)) kind:\(String(describing: kind)) data:\(String(reflecting: data))"
            
        case let .deviceError(_, _, error):
            verboseString = String(reflecting: error)
            
        case let .deviceMute(_, peripheralId, timeout):
            verboseString = "peripheralId:\(peripheralId) timeout:\(timeout)"
            
        }
        
        return "<DeviceStreamEvent> \(description) \(verboseString)"
    }
    
    // MARK: - DeviceStreamEvent.Name
    
    public enum Name: String {
        case peripheralList = "peripheralList"
        case attributeChange = "attr_change"
        case statusChange = "status_change"
        case deviceOTA = "device:ota"
        case deviceOTAProgress = "device:ota_progress"
        case invalidate = "invalidate"
        case deviceError = "device:error"
        case deviceMute = "device:mute"
    }
    
    // MARK: - DeviceStreamEvent.Peripheral
    
    /// Represents a peripheral in a DeviceStreamEvent peripheral list.
    
    public struct Peripheral: Hashable, AferoJSONCoding, CustomDebugStringConvertible {

        public typealias AttributeId = Int
        
        public var id: String
        public var profileId: String
        public var attributes: [AttributeId: Attribute]
        public var status: Status
        
        @available(*, deprecated, message: "Use status.isAvailable instead.")
        public var isAvailable: Bool? {
            return status.isAvailable
        }
        
        @available(*, deprecated, message: "Use status.isVisible instead.")
        public var isVisible: Bool? {
            return status.isVisible
        }
        
        /// If true, this peripheral's connection to the Afero service is direct,
        /// rather than through a hub (e.g., Wifi capable devices)
        
        @available(*, deprecated, message: "Use status.isDirect instead.")
        public var isDirect: Bool? {
            return status.isDirect
        }
        
        public var friendlyName: String?
        public var virtual: Bool
        public var tags: [DeviceTag]
        
        /// The location state of the peripheral.
        ///
        /// - note: When decoding from JSON, `locationState` is set if and only if
        ///         a value was provided in the JSON. In that case, it is set to
        ///         `.known(loc)`. Otherwise it is left `nil`, as an indication that
        ///         the location needs to be acquired from the client API.
        
        public var locationState: LocationState?
        
        public var createdTimestampMs: DeviceStreamEventTimestamp
        
        public var created: Date {
            return Date.dateWithMillisSince1970(createdTimestampMs)
        }
        
        public init(id: String,  profileId: String, attributes: [Attribute], status: Status, friendlyName: String? = nil, virtual: Bool, locationState: LocationState? = nil, tags: [DeviceTag], createdTimestampMs: DeviceStreamEventTimestamp) {
            self.id = id
            self.profileId = profileId

            self.attributes = attributes.reduce([:]) {
                curr, next in
                var ret = curr
                ret[next.id] = next
                return ret
            }
            
            self.status = status
            self.friendlyName = friendlyName
            self.virtual = virtual
            self.locationState = locationState
            self.tags = tags
            self.createdTimestampMs = createdTimestampMs
        }
        
        // MARK: <CustomDebugStringConvertible>
        
        public var debugDescription: String {
            return "<Peripheral> id:\(id) profileId:\(profileId) friendlyName:\(String(describing: friendlyName)) virtual:\(virtual) status:\(String(reflecting: status)) locationState:\(String(reflecting: locationState)) tags: \(String(reflecting: tags)) created: \(String(describing: created)) createdTimestampMs:\(createdTimestampMs) attributes:\(String(reflecting: attributes))"
        }

        // MARK: <Hashable>
        
        public var hashValue: Int { return id.hashValue }
        
        public static func ==(lhs: Peripheral, rhs: Peripheral) -> Bool {
            return lhs.id == rhs.id
                && lhs.profileId == rhs.profileId
                && lhs.attributes == rhs.attributes
                && lhs.status == rhs.status
                && lhs.friendlyName == rhs.friendlyName
                && lhs.virtual == rhs.virtual
                && lhs.locationState == rhs.locationState
                && lhs.tags == rhs.tags
                && lhs.createdTimestampMs == rhs.createdTimestampMs
        }
        
        // MARK: <AferoJSONCoding>
        
        static let CoderKeyId = "id"
        static let CoderKeyProfileId = "profileId"
        static let CoderKeyAttributes = "attributes"
        static let CoderKeyStatus = "status"
        static let CoderKeyFriendlyName = "friendlyName"
        static let CoderKeyVirtual = "virtual"
        static let CoderKeyTags = "tags"
        static let CoderKeyDeviceTags = "deviceTags"
        static let CoderKeyCreatedTimestamp = "createdTimestamp"
        static let CoderKeyLocationState = "locationState"
        
        public var JSONDict: AferoJSONCodedType? {
            
            var ret: [String: Any] = [
                type(of: self).CoderKeyId: id,
                type(of: self).CoderKeyProfileId: profileId,
                type(of: self).CoderKeyAttributes: Array(attributes.values.map { $0.JSONDict! }),
                type(of: self).CoderKeyStatus: status.JSONDict!,
                type(of: self).CoderKeyVirtual: virtual,
                type(of: self).CoderKeyDeviceTags: tags.JSONDict,
                type(of: self).CoderKeyCreatedTimestamp: createdTimestampMs
            ]
            
            if let friendlyName = friendlyName {
                ret[type(of: self).CoderKeyFriendlyName] = friendlyName
            }
            
            if
                case let .some(.known(loc)) = locationState,
                let locationJSON = loc.JSONDict {
                ret[type(of: self).CoderKeyLocationState] = locationJSON
            }
            
            return ret
        }
        
        public init?(json: AferoJSONCodedType?) {
            
            guard let jsonDict = json as? [String: Any] else {
                DDLogWarn("\(String(reflecting: json)) not a dict", tag: "DeviceStreamEvent.Peripheral")
                return nil
            }
            
            guard
                let id = jsonDict[type(of: self).CoderKeyId] as? String,
                let profileId = jsonDict[type(of: self).CoderKeyProfileId] as? String,
                let status: Status = |<jsonDict[type(of: self).CoderKeyStatus],
                let virtual = jsonDict[type(of: self).CoderKeyVirtual] as? Bool,
                let createdTimestampMs = jsonDict[type(of: self).CoderKeyCreatedTimestamp] as? DeviceStreamEventTimestamp else {
                    DDLogWarn("Unable to decode peripheral from \(jsonDict)", tag: "DeviceStreamEvent.Peripheral")
                    return nil
            }
            
            // NOTE: We intentionally don't set locationState "unknown" here. AS of this writing,
            // location state is officially acquired by fetching from the Client API,
            // otherwise it's <nil> as a sentinel that it /needs/ to be fetched.
            
            var locationState: LocationState? = nil
            if let loc: LocationState.Location = |<(jsonDict[type(of: self).CoderKeyLocationState] as? [String: Any]) {
                locationState = .known(loc)
            }
            
            let tags = jsonDict[type(of: self).CoderKeyTags]
            let deviceTags = jsonDict[type(of: self).CoderKeyDeviceTags]
            
            self.init(
                id: id,
                profileId: profileId,
                attributes: |<(jsonDict[type(of: self).CoderKeyAttributes] as? [Any]) ?? [],
                status: status,
                friendlyName: jsonDict[type(of: self).CoderKeyFriendlyName] as? String,
                virtual: virtual,
                locationState: locationState,
                tags: (|<((tags ?? deviceTags) as? [Any]) ?? []),
                createdTimestampMs: createdTimestampMs
            )
            
        }
        
        // MARK: Public

        /// Retrieve a value for an attribute.
        ///
        /// - parameter attributeId: The id of the attribute to fetch. Can be `nil`, in
        ///                  which case `nil` is returned.
        ///
        /// - returns: The `Attribute` instance dereferenced by `attributeId`, if
        ///            present.
        
        public func attribute(for attributeId: Int?) -> Attribute? {
            guard let attributeId = attributeId else { return nil }
            return attributes[attributeId]
        }
        
        /// Set a value for an attribute.
        ///
        /// - parameter attribute: The value to set. If `nil`, deletes the existing value.
        /// - returns: The previous value of the attribute, if available.
        
        @discardableResult
        public mutating func setAttribute(_ attribute: Attribute) -> Attribute? {
            let ret = self.attribute(for: attribute.id)
            attributes[attribute.id] = attribute
            return ret
        }
        
        /// Remove and return the attribute for the given id, if any.
        ///
        /// - parameter attributeId: The id of the attribute to remove.
        /// - returns: The previous value of the attribute, if any.
        
        @discardableResult
        public mutating func removeAttribute(for attributeId: Int) -> Attribute? {
            return attributes.removeValue(forKey: attributeId)
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.Status
        
        /// Peripheral Status
        ///
        /// For each registered peripheral on an account, conclave tracks the
        /// RSSI (signal strength) and various other status flags (like visibility)
        /// summarizing transient information from each hub, coalescing this data
        /// and re-broadcasting it.
        ///
        /// - note: While strucurally similar to `Afero.DeviceModelState`,
        ///         this structure represents updates. In practice, this means that
        ///         values are overlaid on top of an `Afero.DeviceModelState` instance's
        ///         existing values, if and only if they're present in the `Status`
        ///         instance.
        
        public struct Status: Hashable, AferoJSONCoding, CustomDebugStringConvertible {

            /// Whether or not the device is available.
            ///
            /// - note: Calculation of `isAvailable` is based upon `isDirect`, `isVisible`,
            ///         `isRebooted`, `isConnectablre`, `isConnected`, `isLinked`, and `isDirty`.
            ///         Generally, application developers only need be concerned with `isAvailable`
            public var isAvailable: Bool?
            
            /// Whether or not a hub can see the device.
            public var isVisible: Bool?
            
            /// Whether or not the device rebooted recently.
            public var isRebooted: Bool?
            
            /// Whether or not the device is connectable.
            public var isConnectable: Bool?
            
            /// Whether or not the device is connected to the Afero cloud.
            public var isConnected: Bool?
            
            /// If true, the device is connected directly to the Afero cloud. If false,
            /// the device is connected via a hub.
            public var isDirect: Bool?
            
            /// The device has one or more attributes pending write to the Afero cloud.
            public var isDirty: Bool?
            
            /// The peripheral's current RSSI.
            public var RSSI: Int?
            
            init(isAvailable: Bool? = nil, isVisible: Bool? = nil, isDirty: Bool? = nil, isConnectable: Bool? = nil, isConnected: Bool? = nil, isRebooted: Bool? = nil, isDirect: Bool? = nil, RSSI: Int? = nil) {
                self.isAvailable = isAvailable
                self.isVisible = isVisible
                self.isDirty = isDirty
                self.isConnectable = isConnectable
                self.isConnected = isConnected
                self.isRebooted = isRebooted
                self.isDirect = isDirect
                self.RSSI = RSSI
            }
            
            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                
                var flags: [String] = []
                
                if let isAvailable = isAvailable {
                    flags.append("isAvailable:\(isAvailable)")
                }

                if let isVisible = isVisible {
                    flags.append("isVisible:\(isVisible)")
                }

                if let isDirty = isDirty {
                    flags.append("isDirty:\(isDirty)")
                }
                
                if let isConnectable = isConnectable {
                    flags.append("isConnectable:\(isConnectable)")
                }
                
                if let isConnected = isConnected {
                    flags.append("isConnected:\(isConnected)")
                }
                
                if let isRebooted = isRebooted {
                    flags.append("isRebooted:\(isRebooted)")
                }
                
                if let isDirect = isDirect {
                    flags.append("isDirect:\(isDirect)")
                }
                
                if let rssi = RSSI {
                    flags.append("rssi:\(rssi)")
                }
                
                if flags.count > 0 {
                    return "<Status> \(flags.joined(separator: " "))"
                }
                return "<Status> (empty)"
                
            }
            
            // MARK: <Hashable>
            
            public var hashValue: Int {
                return (isAvailable ?? false).hashValue
                    ^ (isVisible ?? false).hashValue
                    ^ (isDirty ?? false).hashValue
                    ^ (isConnectable ?? false).hashValue
                    ^ (isConnected ?? false).hashValue
                    ^ (isRebooted ?? false).hashValue
                    ^ (isDirect ?? false).hashValue
                    ^ (RSSI ?? 0).hashValue
            }
            
            public static func ==(lhs: Status, rhs: Status) -> Bool {
                return lhs.isAvailable == rhs.isAvailable
                    && lhs.isVisible == rhs.isVisible
                    && lhs.isDirty == rhs.isDirty
                    && lhs.isConnectable == rhs.isConnectable
                    && lhs.isConnected == rhs.isConnected
                    && lhs.isRebooted == rhs.isRebooted
                    && lhs.isDirect == rhs.isDirect
                    && lhs.RSSI == rhs.RSSI
            }
            
            // MARK: <AferoJSONCoding>
            
            static let CoderKeyAvailable = "available"
            static let CoderKeyVisible = "visible"
            static let CoderKeyDirty = "dirty"
            static let CoderKeyConnectable = "connectable"
            static let CoderKeyConnected = "connected"
            static let CoderKeyRebooted = "rebooted"
            static let CoderKeyDirect = "direct"
            static let CoderKeyRSSI = "rssi"
            
            public var JSONDict: AferoJSONCodedType? {

                var ret: [String: Any] = [:]
                
                if let isAvailable = isAvailable {
                    ret[type(of: self).CoderKeyAvailable] = isAvailable
                }
                
                if let isVisible = isVisible {
                    ret[type(of: self).CoderKeyVisible] = isVisible
                }
                
                if let isDirty = isDirty {
                    ret[type(of: self).CoderKeyDirty] = isDirty
                }

                if let isConnectable = isConnectable {
                    ret[type(of: self).CoderKeyConnectable] = isConnectable
                }
                
                if let isConnected = isConnected {
                    ret[type(of: self).CoderKeyConnected] = isConnected
                }
                
                if let isRebooted = isRebooted {
                    ret[type(of: self).CoderKeyRebooted] = isRebooted
                }
                
                if let isDirect = isDirect {
                    ret[type(of: self).CoderKeyDirect] = isDirect
                }
                
                if let RSSI = RSSI {
                    ret[type(of: self).CoderKeyRSSI] = RSSI
                }
                
                return ret
            }
            
            public init?(json: AferoJSONCodedType?) {

                guard let jsonDict = json as? [String: Any] else {
                    DDLogWarn("\(String(reflecting: json)) not a dict", tag: "DeviceStreamEvent.Peripheral.Status")
                    return nil
                }
                
                self.init(
                    isAvailable: jsonDict[type(of: self).CoderKeyAvailable] as? Bool,
                    isVisible: jsonDict[type(of: self).CoderKeyVisible] as? Bool,
                    isDirty: jsonDict[type(of: self).CoderKeyDirty] as? Bool,
                    isConnectable: jsonDict[type(of: self).CoderKeyConnectable] as? Bool,
                    isConnected: jsonDict[type(of: self).CoderKeyConnected] as? Bool,
                    isRebooted: jsonDict[type(of: self).CoderKeyRebooted] as? Bool,
                    isDirect: jsonDict[type(of: self).CoderKeyDirect] as? Bool,
                    RSSI: jsonDict[type(of: self).CoderKeyRSSI] as? Int
                    )
            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.DeviceTag
        
        public struct DeviceTag: Hashable, AferoJSONCoding, CustomDebugStringConvertible {
            
            public typealias Id = String
            
            /// A UUID value that identifies this tag, such that it can be deleted
            /// in the future.
            public var id: Id?
            
            public typealias Value = String
            
            /// This is the value of the tag. This is just a simple character string,
            /// so that it can be used
            /// alone, or with a delimiter of the developers' choice to create a key/value pair.
            public var value: Value
            
            public typealias Key = String

            /// A free form field that can be used by clients for organizational
            /// purposes. Optional.
            public var key: Key?
            
            public typealias LocalizationKey = String
            
            /// In the future, Afero may create the ability to localize these tags
            /// for different locales in different global markets. This field is not
            /// currently in use and can be safely ignored by the developer.
            public var localizationKey: LocalizationKey?
            
            public enum TagType: String {
                case account = "ACCOUNT"
            }
            
            /// In the future, Afero may deploy different categories of tags.
            /// This field is not currently in use, will always be `.account`,
            /// and can be safely ignored by the developer.
            public var type: TagType
            
            public init(id: Id?, key: Key? = nil, value: Value, localizationKey: LocalizationKey? = nil, type: TagType = .account) {
                self.id = id
                self.value = value
                self.key = key
                self.localizationKey = localizationKey
                self.type = type
            }
            
            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                return "<DeviceTag> id:\(String(describing: id)) value:\(value) type: \(type) key:\(String(describing: key)) localizationkey: \(String(describing :localizationKey))"
            }
            
            // MARK: <Hashable>
            
            public var hashValue: Int {
                return value.hashValue ^ (key?.hashValue ?? 0)
            }
            
            public static func ==(lhs: DeviceTag, rhs: DeviceTag) -> Bool {
                return lhs.id == rhs.id
                    && lhs.value == rhs.value
                    && lhs.key == rhs.key
                    && lhs.type == rhs.type
                    && lhs.localizationKey == rhs.localizationKey
            }
            
            // MARK: <AferoJSONCodeing>
            
            static let CoderKeyValue = "value"
            static let CoderKeyKey = "key"
            static let CoderKeyLocalizationKey = "localizationKey"
            static let CoderKeyType = "deviceTagType"
            static let CoderKeyId = "deviceTagId"
            
            public var JSONDict: AferoJSONCodedType? {

                var ret: [String: Any] = [
                    type(of: self).CoderKeyValue: value,
                    type(of: self).CoderKeyType: type.rawValue,
                ]
                
                if let id = id {
                    ret[type(of: self).CoderKeyId] = id
                }
                
                if let key = key {
                    ret[type(of: self).CoderKeyKey] = key
                }
                
                if let localizationKey = localizationKey {
                    ret[type(of: self).CoderKeyLocalizationKey] = localizationKey
                }
                
                return ret
            }
            
            public init?(json: AferoJSONCodedType?) {
                
                let tag = "DeviceStreamEvent.Peripheral.DeviceTag"
                
                guard let jsonDict = json as? [String: Any] else {
                    DDLogWarn("\(String(reflecting: json)) not a dict", tag: tag)
                    return nil
                }
                
                guard let value = jsonDict[type(of: self).CoderKeyValue] as? Value else {
                    DDLogWarn("\(jsonDict) doesn't represent a valid DeviceTag (missing 'value')", tag: tag)
                    return nil
                }
                
                var type = TagType.account

                if
                    let maybeTypeRawValue = jsonDict[type(of: self).CoderKeyType] as? TagType.RawValue,
                    let maybeType = TagType(rawValue: maybeTypeRawValue) {
                    type = maybeType
                }
                
                self.init(
                    id: jsonDict[type(of: self).CoderKeyId] as? Id,
                    key: jsonDict[type(of: self).CoderKeyKey] as? Key,
                    value: value,
                    localizationKey: jsonDict[type(of: self).CoderKeyLocalizationKey] as? LocalizationKey,
                    type: type
                )
                
            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.Attribute
        
        /// Represents an Attribute id/value in a Peripheral.
        
        public struct Attribute: Hashable, AferoJSONCoding, CustomDebugStringConvertible {
            
            /// Attribute Id
            public var id: Int
            
            /// The byte-array value of the attribute, as a hex-encoded string
            public var data: String?
            
            /// The stringly value of the attribute.
            public var value: String?
            
            public init(id: Int, data: String?, value: String?) {
                self.id = id
                self.data = data
                self.value = value
            }
            
            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                return "<Attribute> id: \(id) data: \(data ?? "<nil>") value: \(value ?? "<nil>")"
            }
            
            // MARK: <Hashable>
            
            public var hashValue: Int { return id.hashValue }
            
            public static func ==(lhs: Attribute, rhs: Attribute) -> Bool {
                return lhs.id == rhs.id && lhs.data == rhs.data && lhs.value == rhs.value
            }
            
            // MARK: <AferoJSONCoding>
            
            static let CoderKeyId = "id"
            static let CoderKeyData = "data"
            static let CoderKeyValue = "value"
            
            public var JSONDict: AferoJSONCodedType? {
                
                var ret: [String: Any] = [
                    type(of: self).CoderKeyId: id,
                ]

                if let data = data {
                    ret[type(of: self).CoderKeyData] = data
                }
                
                if let value = value {
                    ret[type(of: self).CoderKeyValue] = value
                }
                
                return ret
            }
            
            public init?(json: AferoJSONCodedType?) {
                
                let tag = "DeviceStreamEvent.Peripheral.Attribute"
                
                guard let jsonDict = json as? [String: Any] else {
                    DDLogWarn("\(String(reflecting: json)) not a dict", tag: tag)
                    return nil
                }
                
                guard let id = jsonDict[type(of: self).CoderKeyId] as? Int else {
                        DDLogWarn("\(jsonDict) doesn't represent a valid Attribute", tag: tag)
                        return nil
                }
                
                self.init(
                    id: id,
                    data: jsonDict[type(of: self).CoderKeyData] as? String,
                    value: jsonDict[type(of: self).CoderKeyValue] as? String
                )
            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.LocationState

        /// Physical location state for an Afero device.
        ///
        /// Afero devices can optionally be given a physical location. This may be
        /// assigned by a hub, optionally by the user during initial association,
        /// or afterward by the user in device settings.
        ///
        /// # Interpretation
        /// * `unknown`: The location state has been fetched from the service, and
        ///              the service has responded that the device does not have a set
        ///              location.
        ///
        /// * `known(location)`: The device has a known `location`.

        public enum LocationState: Hashable, CustomDebugStringConvertible {
            
            /// The Afero service does not have a known location for this peripheral.
            case unknown
            
            /// Where this device is, and whence the information comes
            ///
            /// * `location`: The physical location of the device on Planet Earth
            
            case known(Location)
            
            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                switch self {
                case .unknown: return "(unknown)"
                case let .known(loc): return String(reflecting: loc)
                }
            }
            
            // MARK: <Equatable>
            
            public static func ==(lhs: LocationState, rhs: LocationState) -> Bool {
                switch (lhs, rhs) {
                case (.unknown, .unknown): return true
                case let(.known(lpos), .known(rpos)):
                    return lpos == rpos
                default:
                    return false
                }
            }
            
            // MARK: <Hashable>
            
            public var hashValue: Int {
                switch self {
                case .unknown: return 0
                case let .known(pos): return 1 ^ pos.hashValue
                }
            }
            
            // MARK: - DeviceStreamEvent.Peripheral.LocationState.Location
            
            /// Represents a physical location within a volume centered at Earth's core.
            /// Essentially equivalent to a `CoreLocation.CLLocation` value.
            
            public struct Location: Hashable, AferoJSONCoding {

                /// The latitude of this `Position`
                public var latitude: Double
                
                /// The longitude of this `Position`
                public var longitude: Double

                /// The altitude of this `Postion`, if known.
                public var altitude: Double?
                
                /// The horizontal accuracy of the lat/lon values,
                /// if known.
                
                public var horizontalAccuracy: Double?
                
                /// The accuracy of the altitude value, if known.
                public var verticalAccuracy: Double?
                
                /// The "postal address" of this place, if known.
                public var formattedAddress: [String]?
                
                public var source: Source
                
                init(latitude: Double, longitude: Double, altitude: Double? = nil, horizontalAccuracy: Double? = nil, verticalAccuracy: Double? = nil, formattedAddress: [String]? = nil, source: Source) {
                    
                    self.latitude = latitude
                    self.longitude = longitude
                    self.altitude = altitude
                    self.horizontalAccuracy = horizontalAccuracy
                    self.verticalAccuracy = verticalAccuracy
                    
                    self.formattedAddress = formattedAddress
                    self.source = source
                }
                
                // MARK: <Equatable>
                
                public static func ==(lhs: Location, rhs: Location) -> Bool {
                    return lhs.latitude == rhs.latitude
                        && lhs.longitude == rhs.longitude
                        && lhs.altitude == rhs.altitude
                        && lhs.horizontalAccuracy == rhs.horizontalAccuracy
                        && lhs.verticalAccuracy == rhs.verticalAccuracy
                        && lhs.source == rhs.source
                        && (lhs.formattedAddress ?? []) == (rhs.formattedAddress ?? [])
                }
                
                // MARK: <Hashable>
                
                public var hashValue: Int {
                    return latitude.hashValue ^ longitude.hashValue ^ source.hashValue
                }
                
                // MARK: <AferoJSONCoding>
                
                static let CoderKeyLatitude = "latitude"
                static let CoderKeyLongitude = "longitude"
                static let CoderKeyAltitude = "altitude"
                static let CoderKeyHorizontalAccuracy = "horizontalAccuracy"
                static let CoderKeyVerticalAccuracy = "verticalAccuracy"
                static let CoderKeyCreatedFormattedAddressLines = "formattedAddressLines"
                static let CoderKeyLocationSourceType = "locationSourceType"
                
                public var JSONDict: AferoJSONCodedType? {
                    
                    var ret: [String: Any] = [
                        type(of: self).CoderKeyLatitude: String(latitude),
                        type(of: self).CoderKeyLongitude: String(longitude),
                        type(of: self).CoderKeyLocationSourceType: source.rawValue
                    ]
                    
                    ret[type(of: self).CoderKeyCreatedFormattedAddressLines] = formattedAddress
                    
                    if let altitude = altitude {
                        ret[type(of: self).CoderKeyAltitude] = String(altitude)
                    }
                    
                    if let horizontalAccuracy = horizontalAccuracy {
                        ret[type(of: self).CoderKeyHorizontalAccuracy] = String(horizontalAccuracy)
                    }

                    if let verticalAccuracy = verticalAccuracy {
                        ret[type(of: self).CoderKeyVerticalAccuracy] = String(verticalAccuracy)
                    }
                    
                    return ret
                }
                
                public init?(json: AferoJSONCodedType?) {
                    
                    guard let jsonDict = json as? [String: Any] else {
                        DDLogVerbose("Unable to decode Location: \(String(reflecting: json))")
                        return nil
                    }
                    
                    guard
                        let latitudeString = jsonDict[type(of: self).CoderKeyLatitude] as? String,
                        let latitude = Double(latitudeString),
                        let longitudeString = jsonDict[type(of: self).CoderKeyLongitude] as? String,
                        let longitude = Double(longitudeString),
                        let sourceString = jsonDict[type(of: self).CoderKeyLocationSourceType] as? String,
                        let source = Source(rawValue: sourceString)
                    
                        else {
                            DDLogError("Unable to decode DeviceStreamEvent.Peripheral.Location.Position: \(String(reflecting: json))")
                            return nil
                    }
                    
                    var altitude: Double? = nil
                    
                    if let altitudeString = jsonDict[type(of: self).CoderKeyAltitude] as? String {
                        altitude = Double(altitudeString)
                    }
                    
                    var horizontalAccuracy: Double? = nil
                    if let horizontalAccuracyString = jsonDict[type(of: self).CoderKeyHorizontalAccuracy] as? String {
                        horizontalAccuracy = Double(horizontalAccuracyString)
                    }

                    var verticalAccuracy: Double? = nil
                    if let verticalAccuracyString = jsonDict[type(of: self).CoderKeyVerticalAccuracy] as? String {
                        verticalAccuracy = Double(verticalAccuracyString)
                    }

                    self.init(
                        latitude: latitude,
                        longitude: longitude,
                        altitude: altitude,
                        horizontalAccuracy: horizontalAccuracy,
                        verticalAccuracy: verticalAccuracy,
                        formattedAddress: jsonDict[type(of: self).CoderKeyCreatedFormattedAddressLines] as? [String],
                        source: source
                    )
                }

                // MARK: - DeviceStreamEvent.Peripheral.Location.Source
                
                /// Location provenance.
                ///
                /// Location information can come from multiple sources:
                ///
                /// * `initialDeviceAssociate`: The location was set during initial device association, either
                /// using the client's GPS, or manually set by the user.
                ///
                /// * `hubLocationGPS`: The location was set using a hub's GPS location.
                ///
                /// * `userDefinedLocation`: The location was set manually by the user, sometime after
                /// device association.
                
                public enum Source: String {
                    
                    /// The location was set during initial device association, either
                    /// using the client's GPS, or manually set by the user.
                    case initialDeviceAssociate = "INITIAL_DEVICE_ASSOCIATE"
                    
                    /// The location was set using a hub's GPS location.
                    case hubLocationGPS         = "HUB_LOCATION_GPS"
                    
                    /// The location was set manually by the user, sometime after
                    /// device association.
                    case userDefinedLocation    = "USER_DEFINED_LOCATION"
                }
    
            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.UpdateState
        
        /// Terminal states for device update requests
        /// - `.updated`: Update successful..
        /// - `.interrupted`: Interrupted (device-side update in progress or preempted by device-side update).
        /// - `.unknownAttribute`: The attribute being updated is unrecognized by this device.
        /// - `.lengthExceeded`: The new value for the attribute being updated is too large.
        /// - `.conflict`: A conflict was detected when attempting to update the attribute (previous 'set' in progress).
        /// - `.timeout`: Timed out attempting to update the attribute.
        
        public enum UpdateState: Int, CustomStringConvertible, CustomDebugStringConvertible {
            
            var name: String {
                switch self {
                case .updated: return ".updated"
                case .interrupted: return ".interupted"
                case .unknownAttribute: return ".unknownAttribute"
                case .lengthExceeded: return ".lengthExceeded"
                case .conflict: return ".conflict"
                case .timeout: return ".timeout"
                }
            }
            
            public var description: String {
                return debugDescription
            }
            
            public var debugDescription: String {
                let preamble = "DeviceUpdateState\(name)(\(code)): "
                switch self {

                case .updated:
                    return preamble + "Update successful."

                case .interrupted:
                    return preamble + "Operation interrupted (device-side update in progress or preempted by device-side update)."

                case .unknownAttribute:
                    return preamble + "The attribute being updated is unrecognized by this device"
                    
                case .lengthExceeded:
                    return preamble + "The new value for the attribute being updated is too large"
                
                case .conflict:
                    return preamble + "A conflict was detected when attempting to update the attribute (previous 'set' in progress)."

                case .timeout:
                    return preamble + "Timed out attempting to update the attribute."
                    
                }
            }
            
            public var code: Int { return rawValue }
            
            public init?(maybeStateCode: Any?) {
                
                guard let rawAny = maybeStateCode else {
                    return nil
                }
                
                guard
                    let rawValue = rawAny as? Int,
                    let v = UpdateState(rawValue: rawValue) else {
                        DDLogWarn("Unrecognized DeviceUpdateState value: \(rawAny)", tag: "DeviceUpdateState")
                        return nil
                }
                
                self = v
                
            }
            
            /// Everything A-OK
            case updated           = 0
            
            /// Interrupted (device-side update in progress or preempted by device-side update)
            case interrupted       = 1
            
            /// Unknown UUID
            case unknownAttribute       = 2
            
            /// Length exceeded
            case lengthExceeded    = 3
            
            /// Conflict (previous Set in progress)
            case conflict          = 4
            
            /// Timeout (Set timed out)
            case timeout           = 5
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.UpdateReason

        /// Reasons for device update events
        /// - `.unknown`: Unknown
        /// - `.unsolicted`: Unsolicited Kiban-module-initiated or MCU-initiated Update (e.g., button press)
        /// - `.serviceInitiated`: Response to Service-initiated Set
        /// - `.mcuInitiated`: Response to MCU-initiated Set
        /// - `.linkingCompleted`: Linking completed
        /// - `.boundAttriuteChanged`: A bound attribute was changed
        /// - `.fake`: Fake update.
        
        public enum UpdateReason: Int, CustomStringConvertible, CustomDebugStringConvertible {
            
            public var description: String {
                switch self {
                case .unknown: return ".unknown"
                case .unsolicited: return ".unsolicited"
                case .serviceInitiated: return ".serviceInitiated"
                case .mcuInitiated: return ".mcuInitiated"
                case .linkingCompleted: return ".linkingCompleted"
                case .boundAttributeChanged: return ".boundAttributeChanged"
                case .fake: return ".fake"
                }
            }
            
            public var debugDescription: String {
                return "DeviceUpdateReason\(description)(\(code))"
            }
            
            public var code: Int { return rawValue }
            
            public init?(maybeReasonCode: Any?) {
                
                guard let rawAny = maybeReasonCode else {
                    return nil
                }
                
                guard
                    let rawValue = rawAny as? Int,
                    let v = UpdateReason(rawValue: rawValue) else {
                        DDLogWarn("Unrecognized DeviceUpdateReason value: \(rawAny)", tag: "DeviceUpdateReason")
                        return nil
                }
                
                self = v
                
            }
            
            /// Unknown
            case unknown = 0
            
            /// Unsolicited Kiban-module-initiated or MCU-initiated Update (e.g., button press)
            case unsolicited = 1
            
            /// Response to Service-initiated Set
            case serviceInitiated
            
            /// Response to MCU-initiated Set
            case mcuInitiated
            
            /// Linking completed
            case linkingCompleted
            
            /// A bound attribute was changed
            case boundAttributeChanged
            
            /// Fake update
            case fake
            
        }
        
    }
    
    // MARK: - DeviceStreamEvent.OTAPackageInfo
    
    public struct OTAPackageInfo: CustomDebugStringConvertible, Hashable, AferoJSONCoding {
        
        public var packageTypeId: Int
        public var packageName: String
        public var version: String
        public var versionNumber: String
        public var downloadURL: String
        
        public init(packageTypeId: Int, packageName: String, version: String, versionNumber: String, downloadURL: String) {
            
            self.packageTypeId = packageTypeId
            self.packageName = packageName
            self.version = version
            self.versionNumber = versionNumber
            self.downloadURL = downloadURL
        }

        // MARK: <CustomDebugStringConvertible>
        
        public var debugDescription: String {
            return "<OTAPackageInfo> packageTypeId:\(packageTypeId) packageName:\(packageName) version:\(version) versionNumber:\(versionNumber) downloadURL:\(downloadURL)"
        }
        
        // MARK: <Hashable>
        
        public static func ==(lhs: OTAPackageInfo, rhs: OTAPackageInfo) -> Bool {
            return lhs.packageTypeId == rhs.packageTypeId
                && lhs.packageName == rhs.packageName
                && lhs.version == rhs.version
                && lhs.versionNumber == rhs.versionNumber
                && lhs.downloadURL == rhs.downloadURL
        }
        
        public var hashValue: Int { return downloadURL.hashValue }
        
        // MARK: <AferoJSONCoding>
        
        static let CoderKeyPackageTypeId = "packageTypeId"
        static let CoderKeyPackageName = "packageName"
        static let CoderKeyVersion = "version"
        static let CoderKeyVersionNumber = "versionNumber"
        static let CoderKeyDownloadURL = "downloadUrl"
        
        public var JSONDict: AferoJSONCodedType? {
            return [
                type(of: self).CoderKeyPackageTypeId: packageTypeId,
                type(of: self).CoderKeyPackageName: packageName,
                type(of: self).CoderKeyVersion: version,
                type(of: self).CoderKeyVersionNumber: versionNumber,
                type(of: self).CoderKeyDownloadURL: downloadURL
            ]
        }

        public init?(json: AferoJSONCodedType?) {
            
            let tag = "DeviceStreamEvent.OTAPackageInfo"
            
            guard let jsonDict = json as? [String: Any] else {
                DDLogWarn("\(String(reflecting: json)) not a dict", tag: tag)
                return nil
            }
            
            guard
                let id = jsonDict[type(of: self).CoderKeyPackageTypeId] as? Int,
                let packageName = jsonDict[type(of: self).CoderKeyPackageName] as? String,
                let version = jsonDict[type(of: self).CoderKeyVersion] as? String,
                let versionNumber = jsonDict[type(of: self).CoderKeyVersionNumber] as? String,
                let downloadURL = jsonDict[type(of: self).CoderKeyDownloadURL] as? String else {
                    DDLogWarn("\(jsonDict) doesn't represent a valid DeviceStreamEvent.OTAPackageInfo", tag: tag)
                    return nil
            }
            
            self.init(
                packageTypeId: id,
                packageName: packageName,
                version: version,
                versionNumber: versionNumber,
                downloadURL: downloadURL
            )
        }

        
    }
    
    // MARK: - DeviceEventStream.OTAProgress
    
    public struct OTAProgress: CustomDebugStringConvertible, Hashable {
        
        /// The state of OTA progress
        var state: State

        /// The offset, denominated by partition size.
        public var offset: Int

        /// The size of a bootloader partition, giving the reported total size.
        public var partitionSize: Int {
            return total / 2
        }
        
        /// The total OTA size (in bytes)
        public var total: Int
        
        /// The calculated progress of the OTA.
        public var progress: Float? {
            
            switch state {
                
            case .start: return 0.0
                
            case .inProgress:
                let partitionSize = Float(self.partitionSize)
                let offset = Float(self.offset)
                
                let partitionOffset = (offset < partitionSize) ? offset : offset - partitionSize
                
                return partitionOffset / (partitionSize - 1)
                
            case .complete: fallthrough
            case .unknown:
                return nil
                
            }
        }
        
        init(state: State, offset: Int, total: Int) {
            self.state = state
            self.offset = offset
            self.total = total
        }
        
        init?(state: State.IntegerLiteralType, offset: Int, total: Int) {
            
            let lstate = State(state)
            if case .unknown(_) = lstate {
                DDLogError("Unrecognized state: \(state)")
                return nil
            }
            
            self.init(
                state: State(state),
                offset: offset,
                total: total
            )
        }
        
        // MARK: <CustomDebugStringConvertible>
        
        public var debugDescription: String {
            return "<OTAProgress> state:\(String(describing: state)) progress:\(String(describing: progress)) offset:\(offset) total:\(total)"
        }
        
        // MARK: <Hashable>
        
        public var hashValue: Int {
            return state.hashValue ^ total.hashValue ^ offset.hashValue
        }
        
        public static func ==(lhs: OTAProgress, rhs: OTAProgress) -> Bool {
            return lhs.state == rhs.state
                && lhs.offset == rhs.offset
                && lhs.total == rhs.total
        }
        
        // MARK: - DeviceStreamEvent.OTAProgress.State
        
        /// Represents the state of an OTA operation.
        /// * `start`: The OTA has started
        /// * `inProgress`: The OTA is in progress
        /// * `complete`: The OTA has completed
        /// * `unknown(Int)`: An unknown state value was encountered, and associated
        ///                   with the case.
        
        public enum State: CustomDebugStringConvertible, ExpressibleByIntegerLiteral, Hashable, Comparable {

            /// the OTA has started
            case start
            
            /// The OTA is in progress
            case inProgress
            
            /// The OTA is complete
            case complete
            
            /// Unrecognized state.
            case unknown(Int)
            
            // MARK: <ExpressibleByIntegerLiteral>
            
            public typealias IntegerLiteralType = Int

            public init(integerLiteral value: IntegerLiteralType) {
                switch value {
                case State.start.rawValue: self = .start
                case State.inProgress.rawValue: self = .inProgress
                case State.complete.rawValue: self = .complete
                default: self = .unknown(value)
                }
            }
            
            public init(_ value: IntegerLiteralType) {
                self.init(integerLiteral: value)
            }
            
            public var rawValue: IntegerLiteralType {
                switch self {
                case .start: return 0
                case .inProgress: return 1
                case .complete: return 2
                case let .unknown(ret): return ret
                }
            }
            
            // MARK: <Hashable>
            
            public var hashValue: Int { return rawValue }
            
            // MARK: <Equatable>
            
            public static func ==(lhs: State, rhs: State) -> Bool {

                switch(lhs, rhs) {
                    
                case (.start, .start): fallthrough
                case (.inProgress, .inProgress): fallthrough
                case (.complete, .complete):
                    return true
                    
                case let (.unknown(lrv), .unknown(rrv)): return lrv == rrv
                    
                default: return false
                }
                
            }
            
            // MARK: <Comparable>
            
            public static func <(lhs: State, rhs: State) -> Bool {
                return lhs.rawValue < rhs.rawValue
            }

            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                var ret = "OTAProgress"
                switch self {
                case .start: ret += ".start"
                case .inProgress: ret += ".inProgress"
                case .complete: ret += ".complete"
                case .unknown: ret += ".unknown"
                }
                return "\(ret) (\(self.rawValue))"
            }
        }

    }
    
    // MARK: DeviceStreamEvent.DeviceError
    
    /// Holds error information from a DeviceError message.
    public struct DeviceError: LocalizedError, CustomDebugStringConvertible {
        
        /// The event that caused it (usually “device:write”)
        public var event: String
        
        /// The id of the peripheral that experienced the error.
        public var peripheralId: String
        
        /// The error status
        
        public var status: Status {
            return Status(stringValue: givenStatusString)
        }
        
        /// The string interpretation of the code that came from the peripheral.
        public var givenStatusString: String
        
        /// The channelId for the error.
        public var channelId: Int
        
        /// The id of the associated request.
        public var requestId: Int?
        
        init(event: String, peripheralId: String, status: String, channelId: Int, requestId: Int) {
            self.event = event
            self.peripheralId = peripheralId
            self.givenStatusString = status
            self.channelId = channelId
            self.requestId = requestId
        }
        
        // MARK: <CustomDebugStringConvertible>
        
        public var debugDescription: String {
            return "<DeviceError> event:\(event) peripheralId:\(peripheralId) status:\(String(reflecting: status)) givenStatusstring:\(givenStatusString) channelId:\(channelId) requestId:\(String(describing: requestId))"
        }
        
        public var errorDescription: String? {
            return "\(event)/\(String(reflecting: status))"
        }
        
        /**
         Describes result codes for device requests.
         
         - **`.ok`**: Related event was successful.
         - **`.fail`**: This is the kitchen sink of statuses - we don't know what exactly went wrong, only that something did.
         - **`.notFound`**: We couldn't find what you were looking for.  The 'what' depends on the context (and function) you were calling.
         - **`.already`**: The thing you're trying to do is already done.
         - **`.invalidParam`**: A parameter you passed into a function was invalid for the function you passed it to.
         - **`.timedOut`**: The operation you were attempting to do has timed out.
         - **`.cancelled`**: The operation you were attempting has been cancelled.
         - **`.connectionFailed`**: The connection to a peripheral has failed.
         - **`.shutdown`**: Hubby has been shutdown.
         - **`.connectionNotAllowed`**: A connection to a peripheral is not allowed at this time because they're advertising as not connectable.
         - **`.otaDownloadFailed`**: The OTA download failed.
         - **`.fileIOError`**: We had a file io error.
         - **`.otaStartError`**: OTA start error.
         - **`.notAllowed`**: The thing you're trying to do isn't allowed.
         */
        
        public enum Status: UInt64 , CustomStringConvertible, CustomDebugStringConvertible, ExpressibleByStringLiteral {
            
            case ok                          = 0x0
            
            /// This is the kitchen sink of statuses - we don't know what exactly
            /// went wrong, only that something did.
            case fail                        = 0xFFFFFFFF
            
            /// We couldn't find what you were looking for.  The 'what' depends
            /// on the context (and function) you were calling.
            case notFound                   = 0x1
            
            /// The thing you're trying to do is already done.
            case already                     = 0x2
            
            /// A parameter you passed into a function was invalid for the
            /// function you passed it to.
            case invalidParam               = 0x3
            
            /// The operation you were attempting to do has timed out.
            case timedOut                   = 0x4
            
            /// The operation you were attempting has been cancelled.
            case cancelled                   = 0x5
            
            /// The connection to a peripheral has failed.
            case connectionFailed           = 0x6
            
            /// Hubby has been shutdown.
            case shutdown                    = 0x7
            
            /// A connection to a peripheral is not allowed at this time because
            /// they're advertising as not connectable.
            case connectionNotAllowed      = 0x8
            
            /// The OTA download failed.
            case otaDownloadFailed         = 0x9
            
            /// We had a file io error.
            case fileIOError               = 0xA
            
            /// OTA start error.
            case otaStartError             = 0xB
            
            /// The thing you're trying to do isn't allowed.
            case notAllowed                 = 0xC
            
            // MARK: <CustomStringConvertible>
            
            public var description: String {
                switch self {
                case .ok: return "Status::OK"
                case .fail: return "Status::FAIL"
                case .notFound: return "Status::NOT_FOUND"
                case .already: return "Status::ALREADY"
                case .invalidParam: return "Status::INVALID_PARAM"
                case .timedOut: return "Status::TIMED_OUT"
                case .cancelled: return "Status::CANCELLED"
                case .shutdown: return "Status::SHUTDOWN"
                case .connectionFailed: return "Status::CONNECTION_FAILED"
                case .connectionNotAllowed: return "Status::CONNECTION_NOT_ALLOWED"
                case .otaDownloadFailed: return "Status::OTA_DOWNLOAD_FAILED"
                case .fileIOError: return "Status::FILE_IO_ERROR"
                case .otaStartError: return "Status::OTA_START_ERROR"
                case .notAllowed: return "Status::NOT_ALLOWED"
                }
            }
            
            // MARK: <CustomDebugStringConvertible>
            
            public var debugDescription: String {
                return "<DeviceEvent.Status> \(description) == \(rawValue)"
            }
            
            public init(stringValue: String?) {
                
                guard let stringValue = stringValue else {
                    self = .fail
                    return
                }
                
                switch stringValue {
                case Status.ok.description: self = .ok
                case Status.fail.description: self = .fail
                case Status.notFound.description: self = .notFound
                case Status.already.description: self = .already
                case Status.invalidParam.description: self = .invalidParam
                case Status.timedOut.description: self = .timedOut
                case Status.cancelled.description: self = .cancelled
                case Status.shutdown.description: self = .shutdown
                case Status.connectionFailed.description: self = .connectionFailed
                case Status.connectionNotAllowed.description: self = .connectionNotAllowed
                case Status.otaDownloadFailed.description: self = .otaDownloadFailed
                case Status.fileIOError.description: self = .fileIOError
                case Status.otaStartError.description: self = .otaStartError
                case Status.notAllowed.description: self = .notAllowed
                default: self = .fail
                }
                
            }
            
            // MARK: <ExpressibleByStringLiteral>
            
            public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
            public typealias UnicodeScalarLiteralType = StringLiteralType
            
            public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
                self.init(stringLiteral: value)
            }
            
            public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
                self.init(stringLiteral: value)
            }
            
            public init(stringLiteral value: StringLiteralType) {
                self.init(stringValue: value)
            }

        }
        
    }
    
}

