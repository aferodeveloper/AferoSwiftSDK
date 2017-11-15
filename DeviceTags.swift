//
//  DeviceTags.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 11/15/17.
//

import Foundation
import CocoaLumberjack

/// Device tags are a simple list of values associated with a specific device. When a device is
/// associated, this list is initially empty. When a device is disassociated, the tags are purged
/// from the device record, such that no information applied to that device via tags from a previous
/// owner are not retained for a new device owner.

public struct DeviceTag: Hashable, CustomStringConvertible, CustomDebugStringConvertible, AferoJSONCoding {
    
    public typealias Id = String
    
    /// A UUID value that identifies this tag, such that it can be deleted
    /// in the future.
    public var id: Id
    
    public typealias Key = String
    
    public var key: Key
    
    /// A free form field that can be used by clients for organizational
    /// purposes. Optional.
    public typealias Value = String
    
    /// This is the value of the tag. This is just a simple character string,
    /// so that it can be used
    /// alone, or with a delimiter of the developers' choice to create a key/value pair.
    public var value: Value?
    
    public enum TagType: String {
        case account = "ACCOUNT"
    }
    
    /// In the future, Afero may deploy different categories of tags.
    /// This field is not currently in use, will always be 'ACCOUNT',
    /// and can be safely ignored by the developer.
    public var tagType: TagType = .account
    
    public typealias LocalizationKey = String
    
    /// In the future, Afero may create the ability to localize these tags
    /// for different locales in different global markets. This field is not
    /// currently in use and can be safely ignored by the developer.
    public var localizationKey: LocalizationKey?
    
    public init(id: Id, key: Key, value: Value? = nil, tagType: TagType = .account, localizationKey: LocalizationKey? = nil) {
        self.id = id
        self.key = key
        self.value = value
        self.tagType = tagType
        self.localizationKey = localizationKey
    }
    
    // MARK: <Equatable>
    
    public static func ==(lhs: DeviceTag, rhs: DeviceTag) -> Bool {
        return lhs.id == rhs.id
            && lhs.value == rhs.value
            && lhs.tagType == rhs.tagType
            && lhs.localizationKey == rhs.localizationKey
    }
    
    // MARK: <Hashable>
    
    public var hashValue: Int {
        return id.hashValue ^ key.hashValue ^ (value?.hashValue ?? 0)
    }
    
    // MARK: <CustomStringConvertible>
    
    public var description: String {
        return "id:\(id) value:\(String(describing: value)) tagType:\(tagType) localizationKey:\(String(describing: localizationKey))"
    }
    
    // MARK: <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        return "\(String(reflecting: type(of: self))) id:\(id) value:\(String(reflecting: value)) tagType:\(tagType) localizationKey:\(String(reflecting: localizationKey))"
    }
    
    // MARK: <AferoJSONCoding>
    
    private static let CoderKeyId = "deviceTagId"
    private static let CoderKeyKey = "key"
    private static let CoderKeyValue = "value"
    private static let CoderKeyTagType = "deviceTagType"
    private static let CoderKeyLocalizationKey = "localizationKey"
    
    public var JSONDict: AferoJSONCodedType? {
        var ret: [String: Any] = [
            type(of: self).CoderKeyId: id,
            type(of: self).CoderKeyKey: key,
            type(of: self).CoderKeyTagType: tagType,
            ]
        
        if let value = value {
            ret[type(of: self).CoderKeyValue] = value
        }
        
        if let localizationKey = localizationKey {
            ret[type(of: self).CoderKeyLocalizationKey] = localizationKey
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        let logTag = "DeviceTagCollection.Tag"
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogWarn("Unrecognized DeviceTag JSON \(String(reflecting: json))", tag: logTag)
            return nil
        }
        
        guard let id = jsonDict[type(of: self).CoderKeyId] as? Id else {
            DDLogError("No 'id' found in \(jsonDict); bailing", tag: logTag)
            return nil
        }
        
        guard let key = jsonDict[type(of: self).CoderKeyKey] as? Id else {
            DDLogError("No 'key' found in \(jsonDict); bailing", tag: logTag)
            return nil
        }
        
        guard
            let tagTypeRawValue = jsonDict[type(of: self).CoderKeyTagType] as? TagType.RawValue,
            let tagType = TagType(rawValue: tagTypeRawValue) else {
            DDLogError("No (or invalid) 'tagType' found in \(jsonDict); bailing", tag: logTag)
            return nil
        }
        
        self.init(
            id: id,
            key: key,
            value: jsonDict[type(of: self).CoderKeyValue] as? Value,
            tagType: tagType,
            localizationKey: jsonDict[type(of: self).CoderKeyLocalizationKey] as? LocalizationKey
        )
        
    }
    
}
