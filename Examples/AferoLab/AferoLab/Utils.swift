//
//  Utils.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation

public func asyncMain(_ block: @escaping ()->()) {
    DispatchQueue.main.async(execute: block)
}

public func asyncGlobalDefault(_ block: @escaping ()->()) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: block)
}

/**
 Given a hex string, return a `[UInt8]` representation. If the string is empty, return an empty byte array;
 if the string is nil, return nil.
 */
func bytesFromHexString(_ hexString: String?) -> [UInt8]? {
    return Data(hexEncoded: hexString)?.bytes
}

/**
 Given an optional byte array, return a hex-encoded string. If the array is nil, return nil.
 */
func hexStringFromBytes(_ bytes: [UInt8]?) -> String? {
    guard let bytes = bytes else { return nil }
    return Data(bytes: bytes).hexEncoded
}

public func ==<T>(lhs: T?, rhs: T?) -> Bool {
    if let lhs = lhs, let rhs = rhs  {
        return lhs == rhs
    }
    return lhs != nil || rhs != nil
}
