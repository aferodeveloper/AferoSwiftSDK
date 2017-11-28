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


/// Events describing changes to the population of device tags in a
/// `DeviceTagPersisting` implementor.
///
/// # Cases
/// * `.add(tag: DeviceTag)`: `tag` was added to the `DeviceTagPersisting` implementor.
/// * `.update(tag: DeviceTag)`: `tag` was added to the `DeviceTagPersisting` implementor.
/// * `.delete(id: DeviceTag.Id)`: The tag with the given `id` was deleted
///                              on the `DeviceTagPersisting` implementor.

enum DeviceTagPersistingEvent {

    typealias DeviceTag = DeviceTagPersisting.DeviceTag

    /// `tag` was added to the `DeviceTagPersisting` implementor.
    case add(tag: DeviceTag)
    
    /// `tag` was updated on the `DeviceTagPersisiting` implementor.
    case update(tag: DeviceTag)
    
    /// The tag with the given `id` was deleted on the `DeviceTagPersisting` implementor.
    case delete(id: DeviceTag.Id)
}

protocol DeviceTagPersisting {
    
    // MARK: Types
    
    typealias DeviceTag = DeviceTagCollection.DeviceTag

    /// Type for response handler for `deleteTag`
    typealias DeleteTagOnDone = (DeviceTag.Key?, Error?) -> Void
    
    /// Type for response hander for `addOrUpdateTag`
    typealias AddOrUpdateTagOnDone = (DeviceTag?, Error?) -> Void

    // MARK: CRUD
    
    /// Delete a tag in persistent storage.
    /// - parameter id: The id of the tag to delete.
    /// - parameter onDone: The result handler for the call.
    
    func deleteTag(with id: DeviceTag.Id, onDone: DeleteTagOnDone)
    
    /// Add or update a tag.
    ///
    /// - parameter value: The tag's value.
    /// - parameter key: An optional key for the tag.
    /// - parameter id: The optional identifier for the tag.
    /// - parameter onDone: The result handler for the call.

    func addOrUpdateTag(value: DeviceTag.Value, key: DeviceTag.Key?, id: DeviceTag.Id?, onDone:AddOrUpdateTagOnDone)
    
    // MARK: Observation
    
    /// A Reactive `Signal`
    var eventSignal: Signal<DeviceTagPersistingEvent, NoError> { get }
    
}

class DeviceTagCollection {
    
    typealias DeviceTag = DeviceStreamEvent.Peripheral.DeviceTag
    
    // MARK: Private

    private var _identifierTagMap: [DeviceTag.Id: DeviceTag] = [:]
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
        
        defer {
            onDone(ret, error)
            ret?.forEach {
                eventSink.send(value: .addedTag($0))
            }
        }
        
        if let maybeExisting = _identifierTagMap[tag.id],
            maybeExisting == tag {
            onDone(ret, error)
            return
        }
        
        _identifierTagMap[tag.id] = tag

        
        if let key = tag.key  {
            _keyTagMap.removeValue(forKey: key)
        }
    
        ret = [tag]

    }
    
    typealias DeleteTagOnDone = (Set<DeviceTag>?, Error?)->Void

    private func _remove(where isIncluded: (DeviceTag)->Bool, onDone: DeleteTagOnDone) {
        
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
    
    private func _remove(tag: DeviceTag, onDone: DeleteTagOnDone) -> Void {
        
        _remove(where: { $0.id == tag.id }, onDone: onDone)
        
        var ret: Set<DeviceTag>?
        var error: Error?
        
        defer { onDone(ret, error) }
        
        guard let tag = _identifierTagMap.removeValue(forKey: tag.id) else {
            ret = []
            return
        }
        
        guard let key = tag.key else {
            ret = [tag]
            return
        }
        
        _keyTagMap.removeValue(forKey: key)
        ret = deviceTags(forKey: key)
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
    /// - parameter key: The key to fliter by.
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
    
    enum Event: Hashable {
        
        case addedTag(DeviceTag)
        case updatedTag(oldValue: DeviceTag, newValue: DeviceTag)
        case deletedTag(DeviceTag)
        
        static func ==(lhs: Event, rhs: Event) -> Bool {
            
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
        
        var hashValue: Int {
            
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

    // MARK: Protected
    
    func add(tag: DeviceTag, onDone: AddTagOnDone) {
        _add(tag: tag, onDone: onDone)
    }
    
    func remove(tag: DeviceTag, onDone: DeleteTagOnDone) {
        _remove(where: { $0 == tag }, onDone: onDone)
    }
    
    func remove(withKey key: DeviceTag.Key?, onDone: DeleteTagOnDone) {
        _remove(where: { $0.key == key }, onDone: onDone)
    }
    
    func remove(withId id: DeviceTag.Id, onDone: DeleteTagOnDone) {
        _remove(where: { $0.id == id }, onDone: onDone)
    }
    
    // MARK: Public
    
    
    
}
