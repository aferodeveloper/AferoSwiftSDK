//
//  DeviceTagCollection.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 11/15/17.
//

import Foundation
import CocoaLumberjack
import ReactiveSwift
import Result

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
    /// - parameter tag: The tag to remove.
    /// - parameter onDone: The completion handler for the call.
    
    private func _add(tag: DeviceTag, onDone: AddTagOnDone) -> Void {
        _identifierTagMap[tag.id] = tag

        var ret: Set<DeviceTag>?
        var error: Error?
        
        defer { onDone(ret, error) }
        
        guard let key = tag.key  else {
            ret = [tag]
            return
        }
        
        _keyTagMap.removeValue(forKey: key)
        ret = deviceTags(forKey: key)
    }
    
    typealias DeleteTagOnDone = (Set<DeviceTag>?, Error?)->Void

    private func _remove(where isIncluded: (DeviceTag)->Bool, onDone: DeleteTagOnDone) {
        
        var ret: Set<DeviceTag>?
        var error: Error?
        
        defer { onDone(ret, error) }
        
        let deleteKeys = _identifierTagMap
            .filter { isIncluded($1) }
            .map { $0.key }
        
        let deletedTags = Set(deleteKeys.flatMap {
            _identifierTagMap.removeValue(forKey: $0)
        })
        
        onDone(deletedTags, nil)
    }
    
    /// Remove a tag from the collection.
    /// - parameter tag: The tag to remove.
    /// - parameter onDone: The completion handler for the call.
    
    private func _remove(tag: DeviceTag, onDone: DeleteTagOnDone) -> Void {
        
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
    
    // MARK: Setters
    
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
    
}
