//
//  JSONCoding.swift
//  iTokui
//
//  Created by Justin Middleton on 7/27/2016.
//  Copyright (c) 2016 Afero, Inc. All rights reserved.
//

import Foundation

public typealias AferoJSONCodedType = Any
public typealias AferoJSONObject = [String: AferoJSONCodedType]

public protocol AferoJSONCoding {
    init?(json: AferoJSONCodedType?)
    var JSONDict: AferoJSONCodedType? { get }
}

public protocol OptionSetJSONCoding: AferoJSONCoding, OptionSet {}


public extension AferoJSONCoding {
    
    var prettyJSONValue: String? {

        guard let
            json = JSONDict,
            let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
            return nil
        }
        
        return data.stringValue
    }
}

/**
Given an [AnyObject] array, attempt to instantiate an array of objects
from its elements and return it. If any of the instantiations fails,
fail the entire lot.

- parameter json: An `[AnyObject]` array

- returns: If all objects were successfully instantiated, an array of the objects.
If any failed, nil.
*/

public func FromJSON<T: AferoJSONCoding>(_ json: [Any]?) -> [T]? {
    
    guard let json = json else { return nil }
    
    let ret: [T] = json.compactMap { return T(json: $0) }
    
    if ret.count != json.count {
        NSLog("Warning: expected \(json.count) results, got \(ret.count)")
    }
    
    return ret
    
}

public func FromJSON<T: OptionSetJSONCoding>(_ json: [AferoJSONCodedType]?) -> T {
    return T(json: json as AferoJSONCodedType?) ?? T()
}

public func FromJSON<T: AferoJSONCoding>(_ json: AferoJSONCodedType?) -> T? {
        return T(json: json)
}

prefix operator |<

public prefix func |< <T: AferoJSONCoding>(json: AferoJSONCodedType?) -> T? {
    return FromJSON(json)
}

public prefix func |< <T: AferoJSONCoding>(json: [AferoJSONCodedType]?) -> [T]? {
    return FromJSON(json)
}

public prefix func |< <T: AferoJSONCoding>(json: AferoJSONObject?) -> T? {
    return FromJSON(json as AferoJSONCodedType?)
}

public prefix func |< <T: OptionSetJSONCoding>(json: [AferoJSONCodedType]?) -> T {
    return FromJSON(json)
}

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: AferoJSONCoding {
    
    var JSONDict: AferoJSONCodedType {
    
        return self.reduce([:]) {
            (curr: [String: AferoJSONCodedType], next: (Key, Value))->[String: AferoJSONCodedType] in
            guard let jsonDict = next.1.JSONDict else { return curr }
            var ret = curr
            ret[String(describing: next.0)] = jsonDict
            return ret
        }
    }
}

public extension Array where Element: AferoJSONCoding {
    
    var JSONDict: AferoJSONCodedType {
        return self.compactMap { $0.JSONDict }
    }
    
}

public extension Dictionary where Key: CodingKey {
    
    var stringKeyed: [String: Value] {
        return reduce([:]) {
            curr, next in
            var ret = curr
            ret[next.key.stringValue] = next.value
            return ret
        }
        
    }
}

