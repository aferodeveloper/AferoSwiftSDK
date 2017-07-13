//
//  Utils.swift
//  iTokui
//
//  Created by Tony Myles on 11/26/14.
//  Copyright (c) 2014 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack
import CryptoSwift

/// Perform `perform` on `onQueue` after `timeInterval` seconds.
public func after(_ timeInterval: TimeInterval, onQueue: DispatchQueue = DispatchQueue.main, perform: @escaping ()->Void) {
    onQueue.asyncAfter(deadline: DispatchTime.now() + timeInterval, execute: perform)
}

public func asyncMain(_ block: @escaping ()->()) {
    DispatchQueue.main.async(execute: block)
}

public func asyncGlobalDefault(_ block: @escaping ()->()) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: block)
}

open class Utils {

    /**
    Given a hex string, return a `[UInt8]` representation. If the string is empty, return an empty byte array;
    if the string is nil, return nil.
    */
    open class func bytesFromHexString(_ hexString: String?) -> [UInt8]? {
        return Data(hexEncoded: hexString)?.bytes
    }

    /**
    Given an optional byte array, return a hex-encoded string. If the array is nil, return nil.
    */
    open class func hexStringFromBytes(_ bytes: [UInt8]?) -> String? {
        guard let bytes = bytes else { return nil }
        return Data(bytes: bytes).hexEncoded
    }
    
}

open class ResourceUtils {
    
    /**
    Read a JSON file from the given bundle, returning errors in the provided errorpointer.
    
    - parameter file: The JSON file's name, sans extension. For example, to read `rules.json`, the name should just be `rules`.
    - parameter bundle: The bundle whence the file should be read. Defaults to `NSBundle.mainBundle()`
    - parameter error: The optional erropointer to receive any errors reading the file.
    
    - returns: An optional object containint the results.
    */
    
    open class func readJson(_ file: String, bundle: Bundle? = Bundle.main) throws -> Any? {
        
        if let bundle = bundle {
            
            if let path = bundle.path(forResource: file, ofType: "json") {
                
                do {
                    let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let jsonResult: Any = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
                    return jsonResult
                } catch  {
                    throw error
                }
            }
            throw NSError(domain: "No path for file \(file).json in bundle \(bundle).", code: -1, userInfo: nil)
        }
        return nil
    }
}

//public func toHexString<T: DataConvertible>(_ value: T?) -> String? {
//    return Utils.hexStringFromBytes(toByteArray(value))
//}
//
/// Convert a value to a byte array.

//public func toByteArray<T: DataConvertible>(_ value: T?) -> [UInt8]? {
//    if let value = value {
//        var localValue = value
//        return localValue.withUnsafeBufferPointer {
//            $0.baseAddress!.load(as: T.self)
//        }
//        return withUnsafePointer(to: &localValue) {
//            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
//                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size)
//            }
//        }
//    }
//    return nil
//}

///// Given a string possibly containing a byte array encoded as a hex string,
///// attempt to decode and extract the expected type.
//
//public func fromHexString<T: DataConvertible>(_ hexString: String) -> T? {
//
//    if let array: [UInt8] = fromHexString(hexString) {
//        if array.count == MemoryLayout<T>.size {
//            let ret: T = fromByteArray(array)
//            return ret
//        }
//        DDLogInfo("ERROR: byteArray \(array) (hexString \(hexString)) size mismatch for \(T.self)")
//    }
//    return nil
//}
//
//public func fromHexString(_ hexString: String) -> [UInt8]? {
//    return Utils.bytesFromHexString(hexString)
//}

///// Given a byte array, extract a primitive type based on the
///// expected return value T, and return it.
//
//public func fromByteArray<T: DataConvertible>(_ value: [UInt8]) -> T! {
//    return withUnsafeBytes(of: &value) { Array($0) }
//}
//
//public func fromByteArray<T: DataConvertible>(_ value: [UInt8], _: T.Type) -> T {
//    return fromByteArray(value)
//}
//
//public func fromByteArray<T: DataConvertible>(_ value: ArraySlice<UInt8>) -> T {
//    return fromByteAray(Array(value))
//}

/// Given an array of optional values, and a function to convert the opt
public func minimize<T, C: Comparable>(_ values: [T?], f: (T?)->C?) -> T? {
    
    let ret: T? = values.reduce(nil) {
        guard let current = f($0) else { return $1 }
        guard let next = f($1) else { return nil }
        return current < next ? $0 : $1
    }
    
    return ret
}

public func floatNormalize<T: SignedNumber>(_ min: T?, max: T?, current: T?, conv: (T)->Float) -> Float? {
    
    guard let min = min, let max = max else { return nil }
    guard var current = current else { return nil }
    
    if min > max { return nil }
    if current <= min { current = min }
    if current >= max { current = max }
    return conv(current - min) / conv(max - min)
}

public func floatDenormalize<T>(_ min: T?, max: T?, current: Float?, t2f: (T?)->Float?, f2t: (Float)->T?) -> T? {
    guard let current = current, let fmin = t2f(min), let fmax = t2f(max) else { return nil }
    if current < 0 || current > 1.0 { return nil }
    let magnitude = abs(fmax - fmin)
    return f2t(fmin + (current * magnitude))
}


public extension SignedNumber {
    
    public func clamp(_ min: Self, max: Self) -> Self {
        if self < min { return min }
        if self > max { return max }
        return self
    }
}

public extension UnsignedInteger {

    public func clamp(_ min: Self, max: Self) -> Self {
        if self < min { return min }
        if self > max { return max }
        return self
    }
    
}



// Debounce triggers the action after a delay. 
// Subsequent calls to the debounce within the delay will overtake 
// the previous call and trigger the action at the end of the new delay.
public func debounce( _ delay:TimeInterval, queue:DispatchQueue, action: @escaping (()->()) ) -> ()->() {
    var lastFireTime: DispatchTime = .zero
    
    return {
        lastFireTime = .now()
        queue.asyncAfter(deadline: .now() + delay) {
                let now = DispatchTime.now()
                let when = lastFireTime + delay
                if now >= when {
                    action()
                }
        }
    }
}


// Fast debounce triggers the actionable item immediately on first
// event but acts just like the debounce with the following sequence.
//
// Here's an ascii bubble chart of this behavior:
//  1       2 3 4          5
//  ⬇      ⬇⬇⬇          ⬇
//  xxxxx---xxyyzzzzz------xxxxx-----|-->
//  ⬇      ⬇       ⬇     ⬇
//  1       2        4     5
//
public func fastDebounce( _ delay:TimeInterval, queue:DispatchQueue, action: @escaping (()->()) ) -> ()->() {
    
    var lastFireTime: DispatchTime = .zero
//    let dispatchDelay = Int64(delay * Double(NSEC_PER_SEC))
    
    return {
        if lastFireTime == .zero {
            // Initial request, trigger action immediately
            lastFireTime = DispatchTime.now()
            action()
            queue.asyncAfter(
                deadline: .now() + delay) {
                    let now = DispatchTime.now()
                    let when = lastFireTime + delay
                    if now >= when {
                        // No other events followed, rest fire time
                        lastFireTime = .zero
                    }
            }
        } else {
            lastFireTime = DispatchTime.now()
            queue.asyncAfter(
                deadline: .now() + delay) {
                    let now = DispatchTime.now()
                    let when = lastFireTime + delay
                    if now >= when {
                        // Trigger action and reset fire time
                        action()
                        lastFireTime = .zero
                    }
            }
        }
    }
}

/// The underlying `UPRouter` params are stored as an NSDictionary, which
/// doesn't allow value types (structs, enums, tuples). This is a simple
/// wrapper that gets around the limitation.

public class AnyWrapped: CustomDebugStringConvertible {
    
    var TAG: String { return "Wrapped" }
    
    public var debugDescription: String {
        
        let desc: String
        
        if let wrapped = wrapped as? CustomDebugStringConvertible {
            desc = wrapped.debugDescription
        } else {
            desc = "\(wrapped)"
        }
        
        return "<ValueWrapper> value: \(desc)"
    }
    
    private(set) var wrapped: Any
    
    /// Recursively unwrap the wrapped object (e.g if there are nested `Wrapped` objects,
    /// unpeel the onion.
    
    public var unwrapped: Any {
        DDLogDebug("Unwrapping: \(self.debugDescription)", tag: TAG)
        if let wrapped = wrapped as? AnyWrapped {
            return wrapped.unwrapped
        }
        return wrapped
    }
    
    public init?(value: Any?) {
        guard let value = value else { return nil }
        wrapped = value
    }
}

public class Wrapped<T>: CustomDebugStringConvertible {
    
    var TAG: String { return "Wrapped" }
    
    public var debugDescription: String {
        
        let desc: String
        
        if let wrapped = wrapped as? CustomDebugStringConvertible {
            desc = wrapped.debugDescription
        } else {
            desc = "\(wrapped)"
        }
        
        return "<ValueWrapper> value: \(desc)"
    }
    
    private(set) var wrapped: T
    
    /// Recursively unwrap the wrapped object (e.g if there are nested `Wrapped` objects,
    /// unpeel the onion.
    
    public var unwrapped: T {
        DDLogDebug("Unwrapping: \(self.debugDescription)", tag: TAG)
        if let wrapped = wrapped as? Wrapped<T> {
            return wrapped.unwrapped
        }
        return wrapped
    }
    
    public init?(value: T?) {
        guard let value = value else { return nil }
        wrapped = value
    }
}

extension Timer {
    
    //    // Usage:
    //    var count = 0
    //    NSTimer.schedule(repeatInterval: 1) { timer in
    //    println(++count)
    //    if count >= 10 {
    //    timer.invalidate()
    //    }
    //    }
    //
    //    NSTimer.schedule(delay: 5) { timer in
    //    println("5 seconds")
    //    }
    
    /**
     Brazenly lifted from https://gist.github.com/natecook1000/b0285b518576b22c4dc8.
     Creates and schedules a one-time `NSTimer` instance.
     
     - parameter delay: The delay before execution.
     - parameter handler: A closure to execute after `delay`.
     
     - returns: The newly-created `NSTimer` instance.
     */
    class func schedule(delay: TimeInterval, handler: @escaping (Timer?) -> Void) -> Timer? {
        let fireDate = delay + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
        return timer
    }
    
}

extension Data {
    
    var byteArray: [UInt8] {
        var ret = [UInt8](repeating: 0, count: self.count)
        copyBytes(to: &ret, count: self.count)
        return ret
    }
    
}

/**
 Given a hex string, return a `[UInt8]` representation. If the string is empty, return an empty byte array;
 if the string is nil, return nil.
 */
func bytesFromHexString(_ hexString: String?) -> [UInt8]? {
    if let hexString = hexString {
        
        if hexString.characters.count % 2 != 0 {
            DDLogError("Error: invalid hex string '\(hexString)")
            return nil
        }
        
        var data: [UInt8] = []
        
        var startIndex = hexString.startIndex
        
        while(startIndex < hexString.endIndex) {
            let endIndex = hexString.index(startIndex, offsetBy: 2)
            let byteString = hexString.substring(with: startIndex..<endIndex)
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append(num)
            startIndex = endIndex
        }
        
        return data
    }
    return nil
}

/**
 Given an optional byte array, return a hex-encoded string. If the array is nil, return nil.
 */
func hexStringFromBytes(_ bytes: [UInt8]?) -> String? {
    if let bytes = bytes {
        var s = String()
        
        for b in bytes {
            s += String(format:"%02X", b)
        }
        
        return s
    }
    return nil
}


