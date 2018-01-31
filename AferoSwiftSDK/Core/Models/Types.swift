//
//  Types.swift
//  iTokui
//
//  Created by Justin Middleton on 5/30/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import CocoaLumberjack


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}


public protocol SafeSubscriptable {
    
    associatedtype Key
    associatedtype Value
    
    subscript(safe key: Key?) -> Value? { get }
}

public enum AttributeFlavor {
    case raw
    case string
    case boolean
    case sIntegral
    case uIntegral
    case fractional
}

public enum AttributeValue: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
    
    case rawBytes([UInt8])
    case boolean(Bool)
    case signedInt8(Int8)
    case signedInt16(Int16)
    case signedInt32(Int32)
    case signedInt64(Int64)
    case q1516(Double)
    case q3132(Double)
    case utf8S(String)
    
    public var flavor: AttributeFlavor {
        
        switch self {
            
        case .rawBytes: return .raw
            
        case .utf8S: return .string
            
        case .boolean: return .boolean
            
        case .signedInt8: fallthrough
        case .signedInt16: fallthrough
        case .signedInt32: fallthrough
        case .signedInt64:
            return .sIntegral
            
        case .q1516: fallthrough
        case .q3132:
            return .fractional
        }
    }
    
    public var description: String { return localizedStringValue }
    
    public var debugDescription: String {
        
        let preamble = "<AttributeValue> "
        
        switch(self) {
        case .boolean(let value):
            return preamble + ".Boolean(\(value))"
        case .signedInt8(let value):
            return preamble + ".SignedInt8(\(value))"
        case .signedInt16(let value):
            return preamble + ".SignedInt16(\(value))"
        case .signedInt32(let value):
            return preamble + ".SignedInt32(\(value))"
        case .signedInt64(let value):
            return preamble + ".SignedInt64(\(value))"
        case .q1516(let value):
            return preamble + ".Q1516(\(value))"
        case .q3132(let value):
            return preamble + ".Q3132(\(value))"
        case .utf8S(let value):
            return preamble + ".UTF8S(\(value))"
        case .rawBytes(let value):
            return preamble + ".RawBytes(\(value.debugDescription))"
        }
    }
    
    /// ByteArray representation of this value. If the type is `.RawBytes`, then it's just
    /// the value, otherwise it's the value converted to a `[UInt8]` according to its type.
    
    public var byteArray: [UInt8] {
        
        switch self {
        case .rawBytes(let v):      return v
        case .boolean(let v):       return v.bytes
        case .utf8S(let v):
            return [UInt8](v.utf8)
            
        case .signedInt8(let v):    return v.bytes
        case .signedInt16(let v):   return v.bytes
        case .signedInt32(let v):   return v.bytes
        case .signedInt64(let v):   return v.bytes
            
        case .q1516(let v):
            return doubleToQ(v, n: 16, t: Int32.self)
            
        case .q3132(let v):
            return doubleToQ(v, n: 32, t: Int64.self)
        }
        
    }
    
    public init(_ v: [UInt8]) {
        self = .rawBytes(v)
    }
    
    public init(_ v: Bool) {
        self = .boolean(v)
    }
    
    public init(_ v: Int) {
        self = .signedInt64(Int64(v))
    }
    
    public init(_ v: Int8) {
        self = .signedInt8(v)
    }
    
    public init(_ v: Int16) {
        self = .signedInt16(v)
    }
    
    public init(_ v: Int32) {
        self = .signedInt32(v)
    }
    
    public init(_ v: Int64) {
        self = .signedInt64(v)
    }
    
    public init(_ v: Float) {
        self = .q3132(Double(v))
    }
    
    public init(_ v: Double) {
        self = .q3132(v)
    }
    
    public init(_ v: String) {
        self = .utf8S(v)
    }
    
    public init?<T>(_ t: T?) {
        switch t {
            
        case let value as [UInt8]:
            self = .rawBytes(value)
            
        case let value as Bool:
            self = .boolean(value)
            
        case let value as Int8:
            self = .signedInt8(value)
            
        case let value as Int16:
            self = .signedInt16(value)
            
        case let value as Int32:
            self = .signedInt32(value)
            
        case let value as Int64:
            self = .signedInt64(value)
            
        case let value as Float:
            self = .q3132(Double(value))
            
        case let value as Double:
            self = .q3132(value)
            
        case let value as String:
            self = .utf8S(value)
            
        default:
            return nil
        }
    }
}

public extension NSDecimalNumber {
    
    class IntegerBehaviors: NSObject, NSDecimalNumberBehaviors {
        
        static let sharedInstance = IntegerBehaviors()
        
        open func scale() -> Int16 {
            return 0
        }
        
        open func roundingMode() -> NSDecimalNumber.RoundingMode {
            return .plain
        }
        
        open func exceptionDuringOperation(_ operation: Selector, error: NSDecimalNumber.CalculationError, leftOperand: NSDecimalNumber, rightOperand: NSDecimalNumber?) -> NSDecimalNumber? {
            return nil
        }
        
    }
    
}

public extension AttributeValue {
    
    // NOTE: This is a workaround for rdar #25465729 (http://stackoverflow.com/questions/36322336/positive-nsdecimalnumber-returns-unexpected-64-bit-integer-values)
    
    public init?(type: AferoAttributeDataType, value: Decimal) {
        self.init(value as Decimal)
    }

    public init?(type: AferoAttributeDataType, value: NSDecimalNumber) {

        switch type {
            
        case .q1516: fallthrough
        case .q3132:
            let roundedValue = value.doubleValue
            self = .q3132(roundedValue)

        case .sInt64:
            let roundedValue = value.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance).int64Value
            self = .signedInt64(roundedValue)
            
        case .sInt32:
            let roundedValue = value.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance).intValue
            self = .signedInt32(Int32(roundedValue))
            
        case .sInt16:
            let roundedValue = value.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance).int16Value
            self = .signedInt16(roundedValue)
            
        case .sInt8:
            let roundedValue = value.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance).int8Value
            self = .signedInt8(roundedValue)
            
        case .boolean: self = .boolean(value.boolValue)
        let roundedValue = value.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance).boolValue
        self = .boolean(roundedValue)
            
        case .utf8S:
            let formatter = NumberFormatter()
            formatter.locale = .current
            formatter.numberStyle = NumberFormatter.Style.decimal
            self = .utf8S(formatter.string(from: value) ?? "\(value)")
            
        case .bytes:
            self = .rawBytes(value.doubleValue.bytes)
           
        case .unknown:
            return nil
            
        }
    }
    public init?(type: AferoAttributeDataType, value: Int) {
        switch type {
        case .sInt64: self = .signedInt64(Int64(value))
        case .sInt32: self = .signedInt32(Int32(value))
        case .sInt16: self = .signedInt16(Int16(value))
        case .sInt8: self = .signedInt8(Int8(value))
        case .boolean: self = .boolean(Bool(value != 0))
        case .utf8S: self = .utf8S("\(value)")
        case .bytes:
            self = .rawBytes(value.bytes)
        default: return nil
        }
    }
    
    public init?(type: AferoAttributeDataType, value: Int64) {
        switch type {
        case .sInt64: self = .signedInt64(value)
        case .sInt32: self = .signedInt32(Int32(value))
        case .sInt16: self = .signedInt16(Int16(value))
        case .sInt8: self = .signedInt8(Int8(value))
        case .boolean: self = .boolean(value != 0)
        case .utf8S: self = .utf8S("\(value)")
        case .bytes:
            self = .rawBytes(value.bytes)
        default: return nil
        }
    }
    
    public init?(type: AferoAttributeDataType, value: Float) {
        switch type {
        case .sInt64: self = .signedInt64(Int64(value))
        case .sInt32: self = .signedInt32(Int32(value))
        case .sInt16: self = .signedInt16(Int16(value))
        case .sInt8: self = .signedInt8(Int8(value))
        case .boolean: self = .boolean(Bool(value > 0))
        case .utf8S: self = .utf8S("\(value)")
        case .q1516: self = .q1516(Double(value))
        case .q3132: self = .q3132(Double(value))
        case .bytes:
            self = .rawBytes(value.bytes)
        default: return nil
        }
    }
    
    public init?(type: AferoAttributeDataType, value: Double) {
        switch type {
        case .sInt64: self = .signedInt64(Int64(value))
        case .sInt32: self = .signedInt32(Int32(value))
        case .sInt16: self = .signedInt16(Int16(value))
        case .sInt8: self = .signedInt8(Int8(value))
        case .boolean: self = .boolean(Bool(value > 0))
        case .utf8S: self = .utf8S("\(value)")
        case .bytes:
            self = .rawBytes(value.bytes)
        default: return nil
        }
    }
    
    public init?(type: AferoAttributeDataType, value: Bool) {
        
        let intValue = value ? 0 : 1
        
        switch type {
        case .sInt64: self = .signedInt64(Int64(intValue))
        case .sInt32: self = .signedInt32(Int32(intValue))
        case .sInt16: self = .signedInt16(Int16(intValue))
        case .sInt8: self = .signedInt8(Int8(intValue))
        case .boolean: self = .boolean(value)
        case .utf8S: self = .utf8S("\(value)")
        case .bytes:
            self = .rawBytes(value.bytes)
        default: return nil
        }
    }

    public init?(type: AferoAttributeDataType, slice: ArraySlice<UInt8>) {
        self.init(type: type, bytes: Array(slice))
    }
    
    public init?(type: AferoAttributeDataType, bytes: [UInt8]) {
        
        switch type {
            
        case .q1516:
            guard let v = qToDouble(bytes, n: 16, t: Int32.self) else { return nil }
            self = .q1516(v)
            
        case .q3132:
            guard let v = qToDouble(bytes, n: 32, t: Int64.self) else { return nil }
            self = .q3132(v)
            
        case .sInt64:
            guard let v = Int64(byteArray: bytes) else { return nil }
            self = .signedInt64(Int64(v))
            
        case .sInt32:
            guard let v = Int32(byteArray: bytes) else { return nil }
            self = .signedInt32(Int32(v))
            
        case .sInt16:
            guard let v = Int16(byteArray: bytes) else { return nil }
            self = .signedInt16(Int16(v))
            
        case .sInt8:
            guard let v = Int8(byteArray: bytes) else { return nil }
            self = .signedInt8(Int8(v))
            
        case .boolean:
            guard let v = Bool(byteArray: bytes) else { return nil }
            self = .boolean(v)
            
        case .utf8S:
            guard let v = String(byteArray: bytes) else { return nil }
            self = .utf8S(v)
            
        case .bytes:
            self = .rawBytes(bytes)
            
        default: return nil
        }
    }

    public init?(type: AferoAttributeDataType, value: String) {
        switch type {
            
        case .q1516:
            guard let v = Double(value) else { return nil }
            self = .q1516(v)
            
        case .q3132:
            guard let v = Double(value) else { return nil }
            self = .q3132(v)
        case .sInt64:
            guard let v = Int64(value) else { return nil }
            self = .signedInt64(Int64(v))
            
        case .sInt32:
            guard let v = Int32(value) else { return nil }
            self = .signedInt32(v)
            
        case .sInt16:
            guard let v = Int16(value) else { return nil }
            self = .signedInt16(v)
            
        case .sInt8:
            guard let v = Int8(value) else { return nil }
            self = .signedInt8(v)
            
        case .boolean:
            let lv = value.lowercased()
            if lv.hasPrefix("true") {
                self = .boolean(true)
            } else if lv.hasPrefix("false") {
                self = .boolean(false)
            } else if let i = Int(lv) {
                self = .boolean(Bool(i != 0))
            } else {
                return nil
            }
            
        case .utf8S: self = .utf8S(value)
        case .bytes:
            guard let v = Utils.bytesFromHexString(value) else { return nil }
            self = .rawBytes(v)
            
        default: return nil
        }
    }
    
    
}

// MARK: - <Hashable> 

extension AttributeValue: Hashable, Comparable {
    
    public func hash(into h: inout Hasher) {
        switch(self) {
            
        case .rawBytes(let value):
            h.combine(value)
        case .boolean(let value):
            h.combine(1)
            h.combine(value)
        case .utf8S(let value):
            h.combine(2)
            h.combine(value)
        case .signedInt8(let value):
            h.combine(3)
            h.combine(value)
        case .signedInt16(let value):
            h.combine(4)
            h.combine(value)
        case .signedInt32(let value):
            h.combine(5)
            h.combine(value)
        case .signedInt64(let value):
            h.combine(6)
            h.combine(value)
        case .float32(let value):
            h.combine(7)
            h.combine(value)
        case .float64(let value):
            h.combine(8)
            h.combine(value)
        case .q1516:
            h.combine(9)
            h.combine(byteArray)
        case .q3132:
            h.combine(10)
            h.combine(byteArray)
        }
    }
    
    var value: Any {
        switch(self) {
        case .rawBytes(let value):      return value
        case .boolean(let value):       return value
        case .utf8S(let value):         return value
        case .signedInt8(let value):    return value
        case .signedInt16(let value):   return value
        case .signedInt32(let value):   return value
        case .signedInt64(let value):   return value
        case .q1516(let value):       return value
        case .q3132(let value):       return value
        }
    }
}

// Determine whether something is "equal" from a DisplayRules perspective.

infix operator ~==

public func ~==<T: Equatable>(lhs: T, rhs: T) -> Bool {
    if let
        
        // This is a horrible, horrible hack, and reflects a design flaw.
        // If I'd been aware of [this problem](https://devforums.apple.com/message/1072987#1072987),
        // I would have designed things differently. When revisiting, some alternative
        // means of dynamic dispatch hould be considered. For a demo/isolation of the issue,
        // see Opers.playground.
        
        lhs = lhs as? AttributeValue,
        let rhs = rhs as? AttributeValue {
        return lhs ~== rhs
    }
    return lhs == rhs
}

public func ~==(lhs: AttributeValue, rhs: AttributeValue) -> Bool {
    
    if (lhs == rhs) { return true }
    
    switch (lhs.flavor, rhs.flavor) {
        
    case (.string, .string): return lhs.stringValue == rhs.stringValue
        
    case (.string, .boolean): fallthrough
    case (.boolean, .string): fallthrough
    case (.boolean, .boolean): return lhs.boolValue == rhs.boolValue
        
    case (.string, .uIntegral): fallthrough
    case (.uIntegral, .string): fallthrough
    case (.uIntegral, .uIntegral): return lhs.uintValue == rhs.uintValue
        
    case (.string, .sIntegral): fallthrough
    case (.sIntegral, .string): fallthrough
    case (.sIntegral, .sIntegral): return lhs.intValue == rhs.intValue
        
    case (.string, .fractional): fallthrough
    case (.fractional, .string): fallthrough
    case (.fractional, .fractional): return lhs.doubleValue == rhs.doubleValue
        
    default:
        DDLogInfo("Warning: unsupported ~== comparison between \(lhs) , \(rhs); returning false.")
        return false
    }
    
}

public func ==(lhs: AttributeValue, rhs: AttributeValue) -> Bool {
    
    // At this point we know that our hash values are the same, and that
    // we're of the same type.
    
    switch(lhs) {
        
    case .rawBytes(let v):
        return v == rhs.byteArray
        
    case .boolean(let v):
        return v == rhs.boolValue
        
    case .utf8S(let v):         return v == rhs.stringValue
        
    case .signedInt8: fallthrough
    case .signedInt16: fallthrough
    case .signedInt32: fallthrough
    case .signedInt64: fallthrough
    case .q1516: fallthrough
    case .q3132: return lhs.number == rhs.number
    }
}

public func <(lhs: AttributeValue, rhs: AttributeValue) -> Bool {
    
    switch (lhs.flavor, rhs.flavor) {
        
    case (.string, .string): return lhs.stringValue < rhs.stringValue
        
    case (.string, .boolean): fallthrough
    case (.boolean, .string): fallthrough
    case (.boolean, .boolean): return lhs.boolValue == false && rhs.boolValue == true
        
    case (.string, .uIntegral): fallthrough
    case (.uIntegral, .string): fallthrough
    case (.uIntegral, .uIntegral): return lhs.uintValue < rhs.uintValue
        
    case (.string, .sIntegral): fallthrough
    case (.sIntegral, .string): fallthrough
    case (.sIntegral, .sIntegral): return lhs.intValue < rhs.intValue
        
    case (.string, .fractional): fallthrough
    case (.fractional, .string): fallthrough
    case (.fractional, .fractional): return lhs.doubleValue < rhs.doubleValue
        
    default:
        DDLogInfo("Warning: unsupported < comparison between \(lhs) , \(rhs); returning false.")
        return false
    }
    
}

// MARK: - LiteralConvertible compliance

extension AttributeValue: ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self = .utf8S("\(value)")
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self = .utf8S(value)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self = .utf8S(value)
    }
}

extension AttributeValue: ExpressibleByBooleanLiteral {
    
    public typealias BooleanLiteralConvertibleType = BooleanLiteralType
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .boolean(value)
    }
}

extension AttributeValue: ExpressibleByIntegerLiteral {
    
    public typealias IntegerLiteralConveribleType = IntegerLiteralType
    
    public init(integerLiteral value: IntegerLiteralType) {
        self = .signedInt64(Int64(value))
    }
}

extension AttributeValue: ExpressibleByFloatLiteral {
    
    public typealias FloatLiteralConvertibleType = FloatLiteralType
    
    public init(floatLiteral value: FloatLiteralType) {
        self = .q3132(value)
    }
}

extension AttributeValue: ExpressibleByArrayLiteral {
    
    public typealias Element = UInt8
    
    public init(arrayLiteral elements: Element...) {
        self = .rawBytes(elements)
    }
}

// MARK: - Operations

prefix func ~(operand: AttributeValue?) -> AttributeValue? {
    
    guard let operand = operand else { return nil }
    
    switch operand {
        
    case .signedInt16(let value): return .signedInt16(Int16.max - value)
    case .signedInt32(let value): return .signedInt32(Int32.max - value)
    case .signedInt64(let value): return .signedInt64(Int64.max - value)
    case .signedInt8(let value): return .signedInt8(Int8.max - value)
        
        
    case .boolean(let value): return .boolean(!value)
        
    default: return nil
        
    }
    
}

// MARK: - Casts

public extension AttributeValue {
    
    var decimal: Decimal? {
        return number as Decimal?
    }
    
    var number: NSDecimalNumber? {
        
        get {
            switch self {
            case .rawBytes: return nil
            case .boolean(let v): return NSDecimalNumber(value: v as Bool)
            case .utf8S(let v):
                if v.hasPrefix("0x") {
                    return NSDecimalNumber(value: v.intValue ?? 0 as Int)
                }
                return NSDecimalNumber(string: v)
            case .q1516(let v): return NSDecimalNumber(string: "\(v)")
            case .q3132(let v): return NSDecimalNumber(string: "\(v)")
                
            case .signedInt8(let v): return NSDecimalNumber(string: "\(v)")
            case .signedInt16(let v): return NSDecimalNumber(string: "\(v)")
            case .signedInt32(let v): return NSDecimalNumber(string: "\(v)")
            case .signedInt64(let v): return NSDecimalNumber(string: "\(v)")
                
            }
        }
        
    }
    
    var boolValue: Bool { return suited() }
    var doubleValue: Double? { return suited() }
    var floatValue: Float? { return suited() }
    var intValue: Int? { return suited() }
    
    var int32Value: Int32? { return suited() }
    var int64Value: Int64? { return suited() }
    var int16Value: Int16? { return suited() }
    var int8Value: Int8? { return suited() }
    var uintValue: UInt? { return suited() }
    var uint64Value: UInt64? { return suited() }
    var stringValue: String? { return suited() }
    
    func suited() -> Bool {
        
        switch self {
        case .boolean(let value): return value
        case .rawBytes:
            #if compiler(>=5)
            return byteArray.firstIndex { $0 != 0 } != nil
            #endif
            #if !compiler(>=5)
            return byteArray.index { $0 != 0 } != nil
            #endif
        case .utf8S(let v):
            switch v.lowercased() {
                
            case "0x01": fallthrough
            case "01": fallthrough
            case "1": fallthrough
            case "true": return true
                
            case "0x00": fallthrough
            case "00": fallthrough
            case "0": fallthrough
            case "false": return false
                
            // TODO: Justification
            default: return false
            }
            
        default:
            guard let number = number else { return false }
            // WARNING: contrary to documentation, -[NSNumber  boolValue] ≠ true for n < 0.
            return number != 0
            
        }
    }
    
    /**
     Return the value as a byte array. Identical to accessing the `byteArray` property.
     */
    func suited() -> [UInt8] {
        return byteArray
    }
    
    func suited() -> Double? { return number?.doubleValue }
    
    /**
     If possible, return value as a `Float`.
     
     - returns: a `Float` representing the wrapped value, if the value is a numeric type and and not Double, or if it's a String for which `NSString.floatValue` returns non-nil. Otherwise nil.
     */
    
    
    func suited() -> Float? { return number?.floatValue }
    
    /**
     If possible, return value as a Int.
     
     - returns: a `Int` representing the wrapped value, if the value is a numeric
     type and `0 <= value <= Int.max`. Otherwise nil.
     */
    
    func suited() -> Int? { return number?.intValue }
    
    /**
     If possible, return value as an Int64.
     
     - returns: a `Int` representing the wrapped value, if the value is a numeric
     type and `0 <= value <= Int.max`. Otherwise nil.
     */
    
    func suited() -> Int64? { return number?.int64Value }
    
    /**
     If possible, return value as an Int32.
     
     - returns: a `Int32` representing the wrapped value, if the value is a numeric
     type and `0 ≤ value ≤ Int.max`. Otherwise nil.
     */
    
    func suited() -> Int32? {
        guard let n = number?.int64Value, (Int64(Int32.min)...Int64(Int32.max)).contains(n) else {
            return nil
        }
        return Int32(n)
    }
    
    /**
     If possible, return value as an Int16.
     
     - returns: a `Int16` representing the wrapped value, if the value is a numeric
     type and `Int16 ≤ value ≤ Int16.max`. Otherwise nil.
     */
    
    func suited() -> Int16? {
        guard let n = number?.int64Value, (Int64(Int16.min)...Int64(Int16.max)).contains(n) else {
            return nil
        }
        return Int16(n)
    }
    
    /**
     If possible, return value as an Int8.
     
     - returns: an `Int8` representing the wrapped value, if the value is a numeric
     type and `Int.min ≤ value ≤ Int.max`. Otherwise nil.
     */
    
    func suited() -> Int8? {
        guard let n = number?.int64Value, (Int64(Int8.min)...Int64(Int8.max)).contains(n) else {
            return nil
        }
        return Int8(n)
    }
    
    
    /**
     If possible, return value as a UInt.
     
     - returns: a `UInt` representing the wrapped value, if the value is a numeric
     type and `0 <= value <= UInt.max`. Otherwise nil.
     */
    
    func suited() -> UInt? { return number?.uintValue }
    
    /**
     If possible, return value as a UInt.
     
     - returns: a `UInt` representing the wrapped value, if the value is a numeric
     type and `0 <= value <= UInt.max`. Otherwise nil.
     */
    
    func suited() -> UInt64? { return number?.uint64Value }
    
    /**
     If possible, return value as a String.
     
     - returns: a `String` representing the wrapped value, iff the wrapped value is indeed a string.
     */
    
    func suited() -> String? {
        switch self {
            
        case .rawBytes(let value):   return Utils.hexStringFromBytes(value)
        case .utf8S(let value):      return value
        case .boolean(let value):    return "\(value)"
            
        default:
            guard let number = number else { return nil }
            let formatter = NumberFormatter()
            formatter.locale = .current
            formatter.usesGroupingSeparator = false
            formatter.numberStyle = NumberFormatter.Style.decimal
            return formatter.string(from: number)
        }
    }
    
    var localizedStringValue: String {
        switch self {
            
        case .rawBytes(let value):   return Utils.hexStringFromBytes(value) ?? ""
        case .utf8S(let value):      return value
        case .boolean(let value):    return "\(value)"
            
        default:
            guard let number = number else { return "0" }
            let formatter = NumberFormatter()
            formatter.locale = .current
            formatter.usesGroupingSeparator = true
            formatter.numberStyle = NumberFormatter.Style.decimal
            return formatter.string(from: number) ?? "0"
        }
    }
    
    
}

public extension AttributeValue {
    
    var JSONValue: Any? {
        switch self {
        case .rawBytes(let value):
            return Utils.hexStringFromBytes(value)
        case .boolean:       return intValue ?? 0
        case .utf8S:         return stringValue ?? ""
        case .signedInt8:    return NSDecimalNumber(value: int8Value ?? 0 as Int8)
        case .signedInt16:   return NSDecimalNumber(value: int16Value ?? 0 as Int16)
        case .signedInt32:   return NSDecimalNumber(value: int32Value ?? 0 as Int32)
        case .signedInt64:   return NSDecimalNumber(value: int64Value ?? 0 as Int64)
        case .q1516: fallthrough
        case .q3132:
            return NSDecimalNumber(value: doubleValue ?? 0 as Double)
        }
    }
}

public struct AttributeInstance: Hashable, Equatable, CustomDebugStringConvertible {
    
    public var TAG: String { return "AttributeInstance" }
    
    // <CustomDebugStringConvertible>
    
    public var debugDescription: String {
        return "<Attribute> id: \(id) value: \(value.debugDescription)"
    }
    
    // <Hashable>
    
    public func hash(into h: inout Hasher) {
        h.combine(id)
    }
    
    public var id: Int
    public var value: AttributeValue
    
    public var bytes: [UInt8] {
        return value.byteArray
    }
    
    public var boolValue: Bool {
        get { return value.boolValue }
        set { value = AttributeValue.boolean(newValue) }
    }
    
    public init(id: Int, value: AttributeValue) {
        self.id = id
        self.value = value
    }
    
    public init(id: Int, bytes: [UInt8]) {
        self.init(id: id, value: AttributeValue.rawBytes(bytes))
    }
    
    public init(id: Int, stringValue: String) {
        self.init(id: id, value: AttributeValue.utf8S(stringValue))
    }
    
    public init?(id: Int, data: String) {
        guard let bytes = Utils.bytesFromHexString(data) else { return nil }
        self.init(id: id, bytes: bytes)
    }
    
    // MARK: Equatable
    
    public static func ==(lhs: AttributeInstance, rhs: AttributeInstance) -> Bool {
        return (lhs.id == rhs.id) && (lhs.value == rhs.value)
    }
    
}

extension AttributeInstance: AferoJSONCoding {
    
    static let CoderKeyId = "id"
    static let CoderKeyData = "data"
    static let CoderKeyValue = "value"
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        DDLogVerbose("*** encoding attributeInstance \(self.debugDescription) value \(value) debug \(value.debugDescription)", tag: TAG)
        
        return [
            type(of: self).CoderKeyId: id,
            type(of: self).CoderKeyValue: value.stringValue!
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        if
            let json = json as? AferoJSONObject,
            let id = json[type(of: self).CoderKeyId] as? Int {
            
            if let value = json[type(of: self).CoderKeyValue] as? String {
                let attributeValue = AttributeValue.utf8S(value)
                self.init(id: id, value: attributeValue)
                return
            }
        }
        
        DDLogVerbose("Invalid Attribute JSON: \(String(reflecting: json))")
        return nil
    }
    
}

public func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.adding(rhs)
}

public func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.multiplying(by: rhs)
}

public func -(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.subtracting(rhs)
}

public func /(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.dividing(by: rhs)
}

public func abs(_ number: NSDecimalNumber) -> NSDecimalNumber {
    
    if number.compare(NSDecimalNumber.zero) == .orderedAscending {
        return NSDecimalNumber(value: -1 as Int32) * number
    }
    
    return number
}

public extension NSDecimalNumber {
    
    func clamp(_ min: NSDecimalNumber, max: NSDecimalNumber) -> NSDecimalNumber {
        
        if compare(min) == .orderedAscending {
            return min
        }
        
        if compare(max) == .orderedDescending {
            return max
        }
        
        return self
    }
}

// MARK: Q-number handling

//protocol QCoded: FloatLiteralConvertible, IntegerLiteralConvertible, StringLiteralConvertible {
//    
//    associatedtype Storage: QCodable
//    var storage: Storage { get }
//
//}
//
//extension QCoded {
//
//    init(floatLiteral: FloatLiteralType) {
//        self.init(storage: doubleToQ(Double(floatLiteral), n: 16))
//    }
//    
//    init(integerLiteral: IntegerLiteralType) {
//        storage = doubleToQ(Double(integerLiteral), n: 16)
//    }
//
//    init(stringLiteral value: StringLiteralType) {
//        guard let floatValue = Double(String(value)) else {
//            fatalError("Unable to derive float from stringLiteral [\(value)]")
//        }
//        self = floatValue
//    }
//    
//    init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
//        self.init(stringLiteral: value)
//    }
//
//    init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
//        self.init(stringLiteral: value)
//    }
//}
//
//struct Q1516: QCoded {
//    
//    typealias Storage = Int32
//    typealias IntegerLiteralType = Storage
//    var storage: Storage
//    
//}
//
//struct Q3132: QCoded {
//
//    typealias Storage = Int64
//    typealias IntegerLiteralType = Storage
//    var storage: Storage
//    
//}

protocol QCodable: DataConvertible {
    init(_: Double)
    var doubleVal: Double { get }
}

extension Int32: QCodable {
    var doubleVal: Double { return Double(self) }
}
extension Int64: QCodable {
    var doubleVal: Double { return Double(self) }
}

func doubleToQ<T>(_ value: Double, n: Double, t: T.Type) -> [UInt8] where T: QCodable {
    return T(floor(value * pow(2, n))).bytes
}

func doubleToQ<T>(_ value: Double, n: Double) -> T where T: QCodable {
    return T(floor(value * pow(2, n)))
}

func qToDouble<T>(_ qVal: [UInt8], n: Double, t: T.Type) -> Double? where T: QCodable  {
    guard let q = T(byteArray: qVal) else { return nil }
    return q.doubleVal / pow(2, n)
}

func qToDouble<T>(_ qVal: T, n: Double) -> Double where T: QCodable  {
    return qVal.doubleVal / pow(2, n)
}

// MARK: Date/Time wrappers

public struct DateTypes {
    
    public enum DayOfWeek: String, Comparable, CustomDebugStringConvertible {
        
        /*
         The astute reader will note that there's some ahem overlap between
         this and what's in NSDateFormatter. This is NOT localized, but simply provides
         a shallow interface to what the server expects (3-letter capitalized date abbreviations).
         A more complete solution would map these to localized day-of-week names, and
         take into consideration the first day of the week.
         
         That's for later.
         */
        
        case sunday    = "SUN"
        case monday    = "MON"
        case tuesday   = "TUE"
        case wednesday = "WED"
        case thursday  = "THU"
        case friday    = "FRI"
        case saturday  = "SAT"
        
        /// 1-based, ordinal day-of-week number, starting with .Sunday == 1.
        
        public var dayNumber: Int {
            switch self {
            case .sunday: return 1
            case .monday: return 2
            case .tuesday: return 3
            case .wednesday: return 4
            case .thursday: return 5
            case .friday: return 6
            case .saturday: return 7
            }
        }
        
        public var debugDescription: String {
            return "<Afero.DayOfWeek> \(rawValue) = \(dayNumber)"
        }
        
        public static var allDays: [DayOfWeek] {
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        }
        
        public static func Today() -> DayOfWeek {
            return DayOfWeek(dayNumber: Calendar.current.dateComponents(in: TimeZone.autoupdatingCurrent, from: Date()).weekday!)!
        }
        
        public var tomorrow: DayOfWeek {
            return DayOfWeek(dayNumber: (self.dayNumber + 1) % 8)!
        }
        
        public var yesterday: DayOfWeek {
            return DayOfWeek(dayNumber: (self.dayNumber - 1) % 8)!
        }
        
        /// Initialize with an ordiinal day number (1-based)
        public init?(dayNumber: Int) {
            switch dayNumber {
            case 1...type(of: self).allDays.count:
                self = type(of: self).allDays[dayNumber - 1]
            default:
                return nil
            }
        }
        
        // MARK: Comparable
        
        public static func <(lhs: DayOfWeek, rhs: DayOfWeek) -> Bool {
            return lhs.dayNumber < rhs.dayNumber
        }
        
    }
    
    public struct Time: Equatable, Comparable, CustomDebugStringConvertible {
        
        public var debugDescription: String {
            var hourDesc = "-"
            var minuteDesc = "-"
            var secondsDesc = "-"
            
            if let hour = hour {
                hourDesc = "\(hour)"
            }
            
            if let minute = minute {
                minuteDesc = "\(minute)"
            }
            
            if let seconds = seconds {
                secondsDesc = "\(seconds)"
            }
            
            return "<Time> \(hourDesc):\(minuteDesc):\(secondsDesc) T \(timeZone.abbreviation(for: Date()) ?? "-")"
        }
        
        private var componentsCache = NSCache<NSTimeZone, NSDateComponents>()
        
        /// The primary model for all component storage.
        private(set) public var components: DateComponents {
            didSet {
                if oldValue == components { return }
                componentsCache.removeAllObjects()
            }
        }
        
        /// Get the components for this Date in the given timezone. Results
        /// are cached.
        
        public func components(in timeZone: TimeZone) -> DateComponents {
            
            if self.components.timeZone == timeZone {
                return self.components
            }
            
            if let ret = componentsCache.object(forKey: timeZone as NSTimeZone) {
                return ret as DateComponents
            }
            
            var calendar = Calendar.autoupdatingCurrent
            calendar.timeZone = timeZone
            var ret = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute, .second, .timeZone], from: date)
            ret.calendar = Calendar.autoupdatingCurrent
            
            componentsCache.setObject(ret as NSDateComponents, forKey: timeZone as NSTimeZone)
            return ret
        }
        
        public typealias Second = Int
        
        /// The `seconds` component the internal `components` object.
        public var seconds: Second! {
            get { return components.second! }
            set { components.second = newValue }
        }
        
        public typealias Hour = Int
        
        /// The `hour` component the internal `components` object.
        public var hour: Hour! {
            get { return components.hour }
            set { components.hour = newValue }
        }
        
        public typealias Minute = Int
        
        /// The `minute` component the internal `components` object.
        public var minute: Minute! {
            get { return components.minute }
            set { components.minute = newValue }
        }
        
        /// The `timeZone` component the internal `components` object.
        public var timeZone: TimeZone {
            get { return components.timeZone! }
            set { components.timeZone = newValue }
        }
        
        /// A `Date` object, representing the current day, year, and month, with
        /// hour, minute, and second pulled from this instance's underlying components.
        
        public var date: Date {
            
            // We create our components from the current date in order
            // to ensure era, etc., are correct (otherwise we run into
            // leap time accumulation skew).
            
            var localComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .weekday, .hour, .minute, .second, .timeZone],
                from: Date()
            )
            
            // Now update with the components we store.
            
            localComponents.hour = components.hour
            localComponents.minute = components.minute
            localComponents.second = components.second
            localComponents.timeZone = components.timeZone
            
            return Calendar.current.date(from: localComponents)!
        }
        
        /// `DateComponents` in UTC with the current calendar.
        
        public var utcComponents: DateComponents {
            return components(in: .UTC)
        }
        
        public var utcHour: Hour {
            return utcComponents.hour!
        }
        
        public var utcMinute: Minute {
            return utcComponents.minute!
        }
        
        public var utcSecond: Second {
            return utcComponents.second!
        }
        
        public init(components: DateComponents) {
            self.components = components
        }
        
        public init(hour: Hour, minute: Minute, seconds: Second, timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
            
            var components = Calendar.current.dateComponents(
                [.year, .month, .day, .weekday, .hour, .minute, .second, .timeZone],
                from: Date()
            )
            
            components.timeZone = timeZone
            components.hour = hour
            components.minute = minute
            components.second = seconds
            
            self.init(components: components)
        }
        
        public init(date: Date = Date(), timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
            
            var calendar = Calendar.current
            calendar.timeZone = timeZone
            
            var components = calendar.dateComponents(
                [.year, .month, .day, .weekday, .hour, .minute, .second, .timeZone],
                from: date
            )
            
            components.second = 0
            components.nanosecond = 0
            
            self.init(components: components)
        }
        
        // MARK: Comparable
        
        public static func ==(lhs: Time, rhs: Time) -> Bool {
            return (lhs.timeZone == rhs.timeZone)
                && (lhs.hour == rhs.hour)
                && (lhs.minute == rhs.minute)
                && (lhs.seconds == rhs.seconds)
        }
        
        public static func <(lhs: Time, rhs: Time) -> Bool {
            return lhs.date.compare(rhs.date) == .orderedAscending
        }
        
    }
    
}


extension DateTypes.DayOfWeek {
    
    public static func SetFrom(_ json: [String]) -> Set<DateTypes.DayOfWeek>? {
        
        let dayArray: [DateTypes.DayOfWeek] = json.map {
            DateTypes.DayOfWeek(rawValue: $0)
            }.filter() {
                $0 != nil
            }.map() {
                $0!
        }
        
        let ret = Set(dayArray)
        
        if ret.count == json.count {
            return ret
        }
        return nil
    }
    
}

extension DateTypes.Time: AferoJSONCoding {
    
    static let CoderKeyHour = "hour"
    static let CoderKeyMinute = "minute"
    static let CoderKeySeconds = "seconds"
    static let CoderKeyTZ = "timeZone"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyTZ: timeZone.identifier,
        ]
        
        if let hour = hour {
            ret[type(of: self).CoderKeyHour] = hour
        }
        
        if let minute = minute {
            ret[type(of: self).CoderKeyMinute] = minute
        }
        
        if let seconds = seconds {
            ret[type(of: self).CoderKeySeconds] = seconds
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? AferoJSONObject,
            let hour = json[type(of: self).CoderKeyHour] as? Int,
            let minute = json[type(of: self).CoderKeyMinute] as? Int,
            let seconds = json[type(of: self).CoderKeySeconds] as? Int,
            let timeZoneStr = json[type(of: self).CoderKeyTZ] as? String {
            
            let timeZone: TimeZone
            
            if let tz = TimeZone(identifier: timeZoneStr) {
                timeZone = tz
            } else if let tz = TimeZone(abbreviation: timeZoneStr) {
                timeZone = tz
            } else {
                DDLogInfo("Unexpected timezone: \(timeZoneStr)")
                return nil
            }
            
            self.init(hour: hour, minute: minute, seconds: seconds, timeZone: timeZone)
            
        } else {
            return nil
        }
    }
    
}

