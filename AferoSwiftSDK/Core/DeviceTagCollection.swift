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


/// An implementation of deviceTag persistence methods. The
/// implementation does not itself preserve any state; the `DeviceTagCollection`
/// relies upon it to perform CRUD operations.

internal protocol DeviceTagPersisting: class {
    
    // MARK: Types

    typealias DeviceTag = DeviceTagCollection.DeviceTag

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

public class DeviceTagCollection {
    
    /// The persistence backend to use.
    weak var persistence: DeviceTagPersisting!
    
    /// Initialize this collection with the given persistence backend.
    /// - parameter persistence: The persistence backend that will be used,
    ///                          if any.
    
    init<T: Sequence>(with persistence: DeviceTagPersisting, tags: T? = nil)
        where T.Element == DeviceTag {
            self.persistence = persistence
            tags?.forEach {
                _add(tag: $0) {
                    tag, _ in DDLogDebug("Added tag: \(String(describing: tag))", tag: "DeviceTagCollection")
                }
            }
    }
    
    public typealias DeviceTag = DeviceStreamEvent.Peripheral.DeviceTag
    
    // MARK: Private
    
    private var _identifierTagMap: [DeviceTag.Id: DeviceTag] = [:] {
        didSet {
            invalidate()
        }
    }
    
    private var _keyTagMap: [DeviceTag.Key: Set<DeviceTag>] = [:]
    
    func invalidate() {
        _keyTagMap = [:]
        _tags = nil
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
        
        if let maybeExisting = _identifierTagMap[id],
            maybeExisting == tag {
            onDone(ret, error)
            return
        }
        
        _identifierTagMap[id] = tag

        
        if let key = tag.key  {
            _keyTagMap.removeValue(forKey: key)
        }
    
        ret = [tag]

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
        
        let deleteIds = _identifierTagMap
            .filter { isIncluded($1) }
            .map { $0.key }
        
        ret = Set(deleteIds.flatMap {
            _identifierTagMap.removeValue(forKey: $0)
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
        return _identifierTagMap.isEmpty
    }
    
    /// All of the tags.
    
    var count: Int {
        return _identifierTagMap.count
    }
    
    private var _tags: Set<DeviceTag>?
    
    var tags: Set<DeviceTag>! {
        if let ret = _tags { return ret }
        let ret = Set(_identifierTagMap.values)
        _tags = ret
        return ret
    }
    
    /// Get a deviceTag for the given identifier.
    /// - parameter id: The `UUID` of the tag to fetch.
    /// - returns: The matching `DeviceTag`, if any.
    
    public func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag? {
        return _identifierTagMap[id]
    }
    
    /// Get all `deviceTag` for the given `key`.
    /// - parameter key: The `DeviceTag.Key` to match.
    /// - returns: All `DeviceTag`s whose key equals `key`
    
    public func deviceTags(forKey key: DeviceTag.Key) -> Set<DeviceTag> {

        if let ret = _keyTagMap[key] {
            return ret
        }
        
        let ret = Set(_identifierTagMap
            .filter { $0.value.key == key }
            .map { $0.value })
        
        _keyTagMap[key] = ret
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

    
    public func addOrUpdate(tag: DeviceTag, onDone: @escaping AddOrUpdateTagOnDone) {

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
        
        addOrUpdate(tag: DeviceTag(id: id, key: key, value: value, localizationKey: localizationKey), onDone: onDone)
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
