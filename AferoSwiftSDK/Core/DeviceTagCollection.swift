//
//  DeviceTagCollection.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 11/15/17.
//

import Foundation
import CocoaLumberjack
import ReactiveSwift
import PromiseKit
import Result

/// Protocol to which DeviceTags (reference or value types) adhere.
@objc public protocol AferoDeviceTagProto: NSCopying, NSMutableCopying {
    
    typealias Id = String
    @objc var id: Id? { get }
    
    typealias Value = String
    @objc var value: Value { get }
    
    typealias Key = String
    @objc var key: Key? { get }
    
    typealias LocalizationKey = String
    @objc var localizationKey: LocalizationKey? { get }
    
    typealias TagTypeRawValue = String
    @objc var tagTypeRawValue: TagTypeRawValue { get }
    
}

@objc public class AferoDeviceTag: NSObject, AferoDeviceTagProto, Codable, NSCopying, NSMutableCopying {
    
    typealias Model = DeviceStreamEvent.Peripheral.DeviceTag
    var model: Model
    
    init(model: Model) {
        self.model = model
    }
    
    @objc convenience init?(id: AferoDeviceTagProto.Id?, value: AferoDeviceTagProto.Value, key: AferoDeviceTagProto.Key? = nil, localizationKey: AferoDeviceTagProto.LocalizationKey? = nil, tagTypeRawValue: AferoDeviceTagProto.TagTypeRawValue = Model.TagType.account.rawValue) {

        guard let tagType = Model.TagType(rawValue: tagTypeRawValue) else {
            print("invalid tagTypeRawValue: \(tagTypeRawValue)")
            return nil
        }
        
        self.init(model: AferoDeviceTag.Model(id: id, key: key, value: value, localizationKey: localizationKey, type: tagType))
    }
    
    @objc public var id: AferoDeviceTagProto.Id? {
        get { return model.id }
    }
    
    @objc public var value: AferoDeviceTagProto.Value {
        get { return model.value }
    }
    
    @objc public var key: AferoDeviceTagProto.Key? {
        get { return model.key }
    }
    
    @objc public var localizationKey: AferoDeviceTagProto.LocalizationKey? {
        get { return model.localizationKey }
    }
    
    @objc public var tagTypeRawValue: AferoDeviceTagProto.TagTypeRawValue {
        get { return model.type.rawValue }
    }
    
    public override var debugDescription: String {
        return "<\(type(of: self))> model: \(String(reflecting: model))"
    }
    
    public override var description: String {
        return "<\(type(of: self))> model: \(String(describing: model))"
    }
    
    // MARK: <Codable>
    
    enum CodingKeys: String, CodingKey {
        case id = "deviceTagId"
        case value = "value"
        case key = "key"
        case localizationKey = "localizationKey"
        case tagTypeRawValue = "deviceTagType"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(value, forKey: .value)
        try container.encode(key, forKey: .key)
        try container.encode(localizationKey, forKey: .localizationKey)
        try container.encode(tagTypeRawValue, forKey: .tagTypeRawValue)
    }
    
    required convenience public init(from decoder: Decoder) throws {
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(AferoDeviceTagProto.Id.self, forKey: .id)
        let value = try values.decode(AferoDeviceTagProto.Value.self, forKey: .value)
        let key = try values.decode(AferoDeviceTagProto.Key.self, forKey: .key)
        let localizationKey = try values.decode(AferoDeviceTagProto.LocalizationKey.self, forKey: .localizationKey)
        let tagTypeRawValue = try values.decode(AferoDeviceTagProto.LocalizationKey.self, forKey: .tagTypeRawValue)
        
        guard let tagType = Model.TagType(rawValue: tagTypeRawValue) else {
            throw "Invalid value for tagType: \(tagTypeRawValue)"
        }
        
        self.init(model: AferoDeviceTag.Model(id: id, key: key, value: value, localizationKey: localizationKey, type: tagType))

    }
    
    // MARK: <Copying>
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoDeviceTag(model: self.model)
    }
    
    // MARK: <MutableCopying>
    
    public func mutableCopy(with zone: NSZone? = nil) -> Any {
        return AferoMutableDeviceTag(model: self.model)
    }
    
    // MARK: <Hashable>
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let model = (object as? AferoDeviceTag)?.model else { return false }
        return self.model == model
    }
    
    override public var hashValue: Int {
        return model.hashValue
    }
    
}

/// Mutable variant of `AferoDeviceTag`

@objc public class AferoMutableDeviceTag: AferoDeviceTag {
    
    override public var id: AferoDeviceTagProto.Id? {
        get { return super.id }
        set { model.id = newValue }
    }
    
    override public var value: AferoDeviceTagProto.Value {
        get { return super.value }
        set { model.value = newValue }
    }
    
    override public var key: AferoDeviceTagProto.Key? {
        get { return super.key }
        set { model.key = newValue }
    }
    
    override public var localizationKey: AferoDeviceTagProto.LocalizationKey? {
        get { return super.localizationKey }
        set { model.localizationKey = newValue }
    }
    
    override public var tagTypeRawValue: AferoDeviceTagProto.TagTypeRawValue {
        get { return super.tagTypeRawValue }
        set {
            guard let newType  = Model.TagType(rawValue: newValue) else {
                fatalError("Invalid TagType rawValue: \(newValue)")
            }
            model.type = newType
        }
    }
    
}

/// An implementation of deviceTag persistence methods. The
/// implementation does not itself preserve any state; the `DeviceTagCollection`
/// relies upon it to perform CRUD operations.

internal protocol DeviceTagPersisting: class {
    
    // MARK: Types

    typealias DeviceTag = AferoDeviceTag

    /// Type for response handler for `deleteTag`
    typealias DeleteTagOnDone = (DeviceTag.Id?, Error?) -> Void

    /// Type for response hander for `addOrUpdateTag`
    typealias AddOrUpdateTagOnDone = (DeviceTag?, Error?) -> Void

    // MARK: CRUD
    
    /// Delete a tag in persistent storage.
    /// - parameter id: The id of the tag to delete.
    /// - parameter onDone: The result handler for the call.
    
    func purgeTag(with id: DeviceTag.Id, onDone: @escaping DeleteTagOnDone)
    
    /// Add or update a tag.
    ///
    /// - parameter value: The tag's value.
    /// - parameter key: An optional key for the tag.
    /// - parameter id: The optional identifier for the tag.
    /// - parameter onDone: The result handler for the call.

    func persist(tag: DeviceTag, onDone: @escaping AddOrUpdateTagOnDone)
    
}

@objc public class DeviceTagCollection: NSObject {
    
    /// The persistence backend to use.
    weak var persistence: DeviceTagPersisting!
    
    init(with persistence: DeviceTagPersisting) {
        self.persistence = persistence
    }

    /// Initialize this collection with the given persistence backend.
    /// - parameter persistence: The persistence backend that will be used,
    ///                          if any.
    
    convenience init(with persistence: DeviceTagPersisting, tags: [DeviceTag]) {
            self.init(with: persistence)
            tags.forEach {
                _add(tag: $0) {
                    tag, _ in DDLogDebug("Added tag: \(String(describing: tag))", tag: "DeviceTagCollection")
                }
            }
    }
    
    public typealias DeviceTag = AferoDeviceTag
    
    // MARK: Private
    
    @objc private(set) public dynamic var deviceTags: [DeviceTag.Id: DeviceTag] = [:] {
        didSet { invalidate() }
    }
    
    @objc private dynamic var keysToDeviceTags: [DeviceTag.Key: Set<DeviceTag>] = [:]
    
    func invalidate() {
        keysToDeviceTags = [:]
        _tagSet = nil
    }
    
    typealias AddTagOnDone = (Set<DeviceTag>?, Error?) -> Void

    /// Add a tag to the collection.
    /// - parameter tag: The tag to add.
    /// - parameter onDone: The completion handler for the call.
    
    private func _add(tag: DeviceTag, onDone: AddTagOnDone) -> Void {
        
        var ret: Set<DeviceTag>?
        var error: Error?
        
        guard let id = tag.id else {
            error = "No tag found."
            return
        }
        
        defer {
            onDone(ret, error)
            ret?.forEach {
                eventSink.send(value: .addedTag($0))
            }
        }
        
        if let maybeExisting = deviceTags[id],
            maybeExisting == tag {
            onDone(ret, error)
            return
        }
        
        let newTag = tag.copy() as! AferoDeviceTag
        
        deviceTags[id] = newTag

        
        if let key = tag.key  {
            keysToDeviceTags.removeValue(forKey: key)
        }
    
        ret = [newTag]

    }
    
    typealias RemoveTagOnDone = (Set<DeviceTag>?, Error?)->Void

    private func _remove(where isIncluded: (DeviceTag)->Bool, onDone: RemoveTagOnDone) {
        
        var ret: Set<DeviceTag>?
        var error: Error?
        
        defer {
            onDone(ret, error)
            ret?.forEach {
                eventSink.send(value: .deletedTag($0))
            }
        }
        
        let deleteIds = deviceTags
            .filter { isIncluded($1) }
            .map { $0.key }
        
        ret = Set(deleteIds.flatMap {
            deviceTags.removeValue(forKey: $0)
        })
        
    }
    
    /// Remove a tag from the collection.
    /// - parameter tag: The tag to remove.
    /// - parameter onDone: The completion handler for the call.
    
    private func _remove(tag: DeviceTag, onDone: RemoveTagOnDone) -> Void {
        _remove(where: { $0 == tag }, onDone: onDone)
    }
    
    // MARK: Getters

    var isEmpty: Bool {
        return deviceTags.isEmpty
    }
    
    /// All of the tags.
    
    var count: Int {
        return deviceTags.count
    }
    
    private var _tagSet: Set<DeviceTag>?
    
    var tagSet: Set<DeviceTag>! {
        if let ret = _tagSet { return ret }
        let ret = Set(deviceTags.values)
        _tagSet = ret
        return ret
    }
    
    /// Get a deviceTag for the given identifier.
    /// - parameter id: The `UUID` of the tag to fetch.
    /// - returns: The matching `DeviceTag`, if any.
    
    public func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag? {
        return deviceTags[id]
    }
    
    /// Get all `deviceTag` for the given `key`.
    /// - parameter key: The `DeviceTag.Key` to match.
    /// - returns: All `DeviceTag`s whose key equals `key`
    
    public func deviceTags(forKey key: DeviceTag.Key) -> Set<DeviceTag> {

        if let ret = keysToDeviceTags[key] {
            return ret
        }
        
        let ret = Set(deviceTags
            .filter { $0.value.key == key }
            .map { $0.value })
        
        keysToDeviceTags[key] = ret
        return ret
    }

    /// Get the last `deviceTag` for the given key.
    /// - parameter key: The key to filter by.
    /// - returns: The last `DeviceTag` matching the key, if any.
    /// - warning: There is no unique constraint on device tags in the Afero
    ///            cloud as of this writing, so it is possible that more than
    ///            one tag for a given key could exist (however, creating duplicate
    ///            keys is not supported by this API. If you would like to see
    ///            *all* keys that match the given key, use `deviceTags(forKey:)`.
    
    func getTag(for key: DeviceTag.Key) -> DeviceTag? {
        return deviceTags(forKey: key).first
    }
    
    // MARK: Signaling
    
    public enum Event: Hashable {
        
        case addedTag(DeviceTag)
        case updatedTag(oldValue: DeviceTag, newValue: DeviceTag)
        case deletedTag(DeviceTag)
        
        public static func ==(lhs: Event, rhs: Event) -> Bool {
            
            switch (lhs, rhs) {
                
            case let (.addedTag(tl), .addedTag(tr)):
                return tl == tr
                
            case let (.updatedTag(tol, tnl), .updatedTag(tor, tnr)):
                return tol == tor && tnl == tnr
                
            case let (.deletedTag(tl), .deletedTag(tr)):
                return tl == tr

            default:
                return false
            }
        }
        
        public var hashValue: Int {
            
            switch self {
            case let .addedTag(t): return t.hashValue
            case let .deletedTag(t): return t.hashValue
            case let .updatedTag(o, n): return o.hashValue ^ n.hashValue
            }
            
        }
        
        
    }
    
    /// Type for the sink to which we send `Event`s.
    private typealias EventSink = Observer<Event, NoError>
    
    /// Type for the signal on which clients listen for `Event`s.
    typealias EventSignal = Signal<Event, NoError>
    
    /// Type for the pipe that ties `EventSink` and `EventSignal` together.
    private typealias EventPipe = (output: EventSignal, input: EventSink)
    
    /// The pipe which casts `Event`s.
    lazy private final var eventPipe: EventPipe = {
        return EventSignal.pipe()
    }()
    
    /// The `Signal` on which `Event`s can be received.
    var eventSignal: EventSignal {
        return eventPipe.0
    }
    
    /**
     The `Sink` to which `Event`s are broadcast.
     */
    
    private final var eventSink: EventSink {
        return eventPipe.1
    }

    // MARK: Protected/Internal
    
    func add(tag: DeviceTag, onDone: AddTagOnDone) {
        _add(tag: tag, onDone: onDone)
    }
    
    func remove(tag: DeviceTag, onDone: RemoveTagOnDone) {
        _remove(where: { $0 == tag }, onDone: onDone)
    }
    
    func remove(withKey key: DeviceTag.Key?, onDone: RemoveTagOnDone) {
        _remove(where: { $0.key == key }, onDone: onDone)
    }
    
    func remove(withId id: DeviceTag.Id, onDone: RemoveTagOnDone) {
        _remove(where: { $0.id == id }, onDone: onDone)
    }
    
    // MARK: Public
    
    /// Type for response hander for `addOrUpdateTag`
    public typealias AddOrUpdateTagOnDone = (DeviceTag?, Error?) -> Void

    
    public func addOrUpdate(tag: DeviceTag?, onDone: @escaping AddOrUpdateTagOnDone) {

        guard let tag = tag else {
            onDone(nil, "Nil deviceTag provided.")
            return
        }
        
        persistence.persist(tag: tag) {
            
            [weak self] maybeTag, maybeError in
            
            guard let tag = maybeTag else {
                onDone(nil, maybeError)
                return
            }
            
            self?.add(tag: tag) {
                onDone($0.0?.first, $0.1)
            }
        }

    }

    public func addOrUpdateTag(with value: DeviceTag.Value, groupedUsing key: DeviceTag.Key?, identifiedBy id: DeviceTag.Id? = nil, using localizationKey: DeviceTag.LocalizationKey? = nil, onDone: @escaping AddOrUpdateTagOnDone) {

        guard let tag = DeviceTag(id: id, value: value, key: key, localizationKey: localizationKey) else {
            onDone(nil, "Unable to create DeviceTag with value:\(value) key:\(String(describing: key)) id:\(String(describing: id)) localizationKey:\(String(describing: localizationKey))")
            return
        }
        
        addOrUpdate(tag: tag, onDone: onDone)
    }
    
    /// Type for response handler for `deleteTag`
    public typealias DeleteTagOnDone = (DeviceTag.Id?, Error?) -> Void
    
    public func deleteTag(identifiedBy id: DeviceTag.Id, onDone: @escaping DeleteTagOnDone) {
        
        persistence.purgeTag(with: id) {

            [weak self] maybeId, maybeError in

            guard let id = maybeId else {
                onDone(nil, maybeError)
                return
            }
            
            self?.remove(withId: id) {
                onDone(id, $0.1)
            }
            
        }
    }
    
}
