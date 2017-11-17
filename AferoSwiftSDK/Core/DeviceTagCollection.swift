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
    
    // MARK: Private

    private var identifierTagMap: [DeviceTag.Id: DeviceTag] = [:]
    private var keyTagMap: [DeviceTag.Key: [DeviceTag]] = [:]
    
    func invalidate() {
        keyTagMap.removeAll()
    }
    
    typealias AddTagOnDone = ([DeviceTag]?, Error?)->Void

    /// Add a tag to the collection.
    /// - parameter tag: The tag to remove.
    /// - parameter onDone: The completion handler for the call.
    
    private func _add(tag: DeviceTag, onDone: AddTagOnDone) -> Void {
        identifierTagMap[tag.id] = tag

        var ret: [DeviceTag]?
        var error: Error?
        
        defer { onDone(ret, error) }
        
        guard let key = tag.key  else {
            ret = [tag]
            return
        }
        
        keyTagMap.removeValue(forKey: key)
        ret = deviceTags(forKey: key)
    }

    typealias RemoveTagOnDone = ([DeviceTag]?, Error?)->Void

    /// Remove a tag from the collection.
    /// - parameter tag: The tag to remove.
    /// - parameter onDone: The completion handler for the call.
    
    private func _remove(tag: DeviceTag, onDone: RemoveTagOnDone) -> Void {
        
        var ret: [DeviceTag]?
        var error: Error?
        
        defer { onDone(ret, error) }
        
        guard let tag = identifierTagMap.removeValue(forKey: tag.id) else {
            ret = []
            return
        }
        
        guard let key = tag.key else {
            ret = [tag]
            return
        }
        
        keyTagMap.removeValue(forKey: key)
        ret = deviceTags(forKey: key)
    }
    
    // MARK: Getters

    var isEmpty: Bool {
        return identifierTagMap.isEmpty
    }
    
    /// All of the tags.
    
    var tags: LazyMapCollection<[DeviceTag.Id: DeviceTag], DeviceTag> {
        return identifierTagMap.values
    }
    
    /// Get a deviceTag for the given identifier.
    /// - parameter id: The `UUID` of the tag to fetch.
    /// - returns: The matching `DeviceTag`, if any.
    
    public func deviceTag(forIdentifier id: DeviceTag.Id) -> DeviceTag? {
        return identifierTagMap[id]
    }
    
    /// Get all `deviceTag` for the given `key`.
    /// - parameter key: The `DeviceTag.Key` to match.
    /// - returns: All `DeviceTag`s whose key equals `key`
    
    public func deviceTags(forKey key: DeviceTag.Key) -> [DeviceTag] {

        if let ret = keyTagMap[key] {
            return ret
        }
        
        let ret = identifierTagMap
            .filter { $0.value.key == key }
            .map { $0.value }
        
        keyTagMap[key] = ret
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
        return deviceTags(forKey: key).last
    }
    
    // MARK: Setters
    
    func add(tag: DeviceTag, onDone: AddTagOnDone) -> Void {
        
    }
    
    
    
    
}
