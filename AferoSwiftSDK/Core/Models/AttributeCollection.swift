//
//  AttributeCollection.swift
//  Pods
//
//  Created by Justin Middleton on 1/10/18.
//

import Foundation


/// Describes a type for an attribute.

@objc public enum AferoAttributeDataType: Int, CustomStringConvertible, CustomDebugStringConvertible, Codable {
    
    case
    unknown,
    boolean,
    sInt8,
    sInt16,
    sInt32,
    sInt64,
    q1516,
    q3132,
    utf8S,
    bytes
    
    public var stringValue: String? {
        switch(self) {
        case .boolean: return "boolean"
        case .sInt8:   return "sint8"
        case .sInt16:  return "sint16"
        case .sInt32:  return "sint32"
        case .sInt64:  return "sint64"
        case .q1516:   return "q1516"
        case .q3132:   return "q3132"
        case .utf8S:   return "utf8s"
        case .bytes:   return "bytes"
        case .unknown: return nil
        }
    }
    
    // MARK: CustomDebugStringConvertible
    
    public var debugDescription: String {
        return "<DataType> \(description)"
    }
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        return stringValue ?? "<unknown>"
    }

    /// Byte size of values of this type
    public var size: Int? {
        switch self {
        case .boolean: return MemoryLayout<Bool>.size
        case .sInt8:   return MemoryLayout<Swift.Int8>.size
        case .sInt16:  return MemoryLayout<Swift.Int16>.size
        case .sInt32:  return MemoryLayout<Swift.Int32>.size
        case .sInt64:  return MemoryLayout<Swift.Int64>.size
        case .q1516:   return MemoryLayout<Swift.Int32>.size
        case .q3132:   return MemoryLayout<Swift.Int64>.size
        default:       return nil
        }
    }
    
    init(name: String?) {
        
        self = .unknown
        
        guard let name = name else {
            return
        }
        
        switch(name.lowercased()) {

         case type(of: self).boolean.stringValue!:     self = .boolean
        case type(of: self).sInt8.stringValue!:       self = .sInt8
        case type(of: self).sInt16.stringValue!:      self = .sInt16
        case type(of: self).sInt32.stringValue!:      self = .sInt32
        case type(of: self).sInt64.stringValue!:      self = .sInt64

        case type(of: self).utf8S.stringValue!:       self = .utf8S
        case type(of: self).bytes.stringValue!:       self = .bytes

        case "fixed_16_16": fallthrough
        case type(of: self).q1516.stringValue!:       self = .q1516
            
        case "fixed_32_32": fallthrough
        case type(of: self).q3132.stringValue!:       self = .q3132
            
        default:            break
        }
        
    }
    
}

@objc public enum AferoAttributeOperation: Int, CustomDebugStringConvertible {

    case read = 1
    case write = 2
    
    public var debugDescription: String {
        var shift = 0
        while (rawValue >> shift != 1) { shift += 1 }
        return ["Read", "Write"][shift]
    }

}

@objc public final class AferoAttributeOperations: NSObject, NSCopying, Codable, OptionSet {
    
    @objc override public var debugDescription: String {
        
        var result: [String] = []
        var shift = 0
        
        while let currentOperation = AferoAttributeOperation(rawValue: 1 << shift) {
            shift += 1
            if self.contains(AferoAttributeOperations(currentOperation)) {
                result.append(currentOperation.debugDescription)
            }
        }
        
        return result.joined(separator: ",")
    }
    
    // MARK: OptionSetType
    
    public let rawValue: Int
    
    @objc public required init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    init(_ operation: AferoAttributeOperation) {
        self.rawValue = operation.rawValue
    }
    
    // MARK: Codable
    
    enum PermissionNames: String {
        case READ
        case WRITE
    }
    
    public convenience init(from decoder: Decoder) throws {
        
        var container = try decoder.unkeyedContainer()
        var operations = AferoAttributeOperations()
        
        while !container.isAtEnd {
            let name = try container.decode(String.self)
            switch name {
            case PermissionNames.READ.rawValue:
                operations.formUnion(.Read)
            case PermissionNames.WRITE.rawValue:
                operations.formUnion(.Write)
            default:
                break
            }
        }
        
        self.init(rawValue: operations.rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var array = [String]()
        
        if contains(.Read) {
            array.append(PermissionNames.READ.rawValue)
        }
        
        if contains(.Write) {
            array.append(PermissionNames.WRITE.rawValue)
        }
        
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: array)
    }
    
    // MARK: NSCoding

    public convenience init?(coder aDecoder: NSCoder) {
        self.init(rawValue: aDecoder.decodeInteger(forKey: "rawValue"))
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.setValue(rawValue, forKey: "rawValue")
    }
    
    // MARK: NSObject

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeOperations else { return false }
        return other.intersection(type(of: self).ReadWrite).rawValue == intersection(type(of: self).ReadWrite).rawValue
    }
    
    @objc override public var hashValue: Int {
        return rawValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeOperations(rawValue: rawValue)
    }
    
    public static let Read = AferoAttributeOperations(.read)
    public static let Write = AferoAttributeOperations(.write)
    public static let ReadWrite = AferoAttributeOperations(rawValue: 3)
    
}

/// Descriptive metadata about an Afero attribute, including its identifier, type,
/// "semanticType", default value, and operations.

@objcMembers
public class AferoAttributeDescriptor: NSObject, NSCopying, Codable {
    
    public override var debugDescription: String {
        return "<AferoAttributeDescriptor> id:\(id) dataType:\(dataType) semanticType:\(String(describing: semanticType)) key:\(String(describing: key)) defaultValue:\(String(describing: defaultValue)) operations:\(String(describing: operations))"
    }
    
    /// The id for this attribute, unique to a profile.
    public let id: Int
    
    /// The `AferoAttributeDataType` associated with this attribute.
    public let dataType: AferoAttributeDataType
    
    /// The "semantic" type (usually a human-readable description) of the associated
    /// attribute.
    public let semanticType: String?
    
    /// A string identifier, unique to the associated attribute on a given
    /// Afero peripheral.
    public let key: String?
    
    /// The default value for this attribute, if any.
    public let defaultValue: String?
    
    /// The valid operations (readable, writable) for this attribute.
    public let operations: AferoAttributeOperations

    init(id: Int = 0, type: AferoAttributeDataType, semanticType: String? = nil, key: String? = nil, defaultValue: String? = nil, operations: AferoAttributeOperations = []) {
        self.id = id
        self.dataType = type
        self.semanticType = semanticType
        self.key = key
        self.defaultValue = defaultValue
        self.operations = operations
    }
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeDescriptor else { return false }
        return other.id == id
            && other.dataType == dataType
            && other.semanticType == semanticType
            && other.key == key
            && other.defaultValue == defaultValue
            && other.operations == operations
    }
    
    public override var hashValue: Int {
        return id.hashValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeDescriptor(id: id, type: dataType, semanticType: semanticType, key: key, defaultValue: defaultValue, operations: operations)
    }
    
}

/// Represents the current value state of an Afero attribute—its value, when it
/// last changed, and any request id. It does not contain interpretation info.

@objcMembers
public class AferoAttributeValueState: NSObject, NSCopying, Comparable, Codable {
    
    public override var debugDescription: String {
        return "<AferoAttributeValueState> value:\(value) data:\(data) updatedTimestampMs:\(updatedTimestampMs) requestid:\(String(describing: requestId))"
    }
    
    /// The string value of this instance.
    let value: String
    
    /// The encoded data value of htis instance (if provided).
    let data: String?
    
    /// When this attribute was last updated.
    /// - warning: When an Afero device resets and reports its values, `updatedTimestampMs`
    ///            reflects the time of said report, which will be later than when
    ///            the value was actually changed due to user action, rule execution,
    ///            or MCU activity.
    
    let updatedTimestampMs: Int64
    
    /// Any associated request id, returned from the Afero cloud when setting an attribute.
    let requestId: Int?
    
    init(value: String, data: String?, updatedTimestampMs: Int64, requestId: Int?) {
        self.value = value
        self.data = data
        self.updatedTimestampMs = updatedTimestampMs
        self.requestId = requestId
    }
    
    convenience init(value: String, data: String?, updatedTimestamp: Date, requestId: Int?) {
        self.init(value: value, data: data, updatedTimestampMs: Int64(updatedTimestamp.millisSince1970), requestId: requestId)
    }
    
    /// When this attribute was last updated.
    /// - warning: When an Afero device resets and reports its values, `updatedTimestamp`
    ///            reflects the time of said report, which will be later than when
    ///            the value was actually changed due to user action, rule execution,
    ///            or MCU activity.
    
    lazy private(set) public var updatedTimestamp: Date = {
        return Date.dateWithMillisSince1970(NSNumber(value: self.updatedTimestampMs))
    }()
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeValueState else { return false }
        return other.value == value && other.data == data && other.updatedTimestampMs == updatedTimestampMs && other.requestId == requestId
    }
    
    public override var hashValue: Int {
        return value.hashValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeValueState(value: value, data: data, updatedTimestampMs: updatedTimestampMs, requestId: requestId)
    }
    
    // MARK: Comparable
    
    /// Compares by updatedTimestamp only. For comparing by value, etc,
    /// convert the `value` to a meaningful type first.
    
    public static func <(lhs: AferoAttributeValueState, rhs: AferoAttributeValueState) -> Bool {
        return lhs.updatedTimestamp < rhs.updatedTimestamp
    }
    
}

/// Represents an Afero attribute on an Afero peripheral device.

@objcMembers
public class AferoAttribute: NSObject, NSCopying, Codable {
    
    public override var debugDescription: String {
        return "<AferoAttribute> desc:\(String(reflecting: descriptor)) current:\(String(reflecting: currentValueState)) pending:\(String(reflecting: pendingValueState))"
    }

    /// Metadata describing this attribute's content
    dynamic internal(set) public var descriptor: AferoAttributeDescriptor
    
    /// The current value state reported by the Afero peripheral device to the Afero cloud.
    dynamic internal(set) public var currentValueState: AferoAttributeValueState? {
        willSet {
            guard newValue != currentValueState else { return }
            willChangeValue(for: \.currentValueState)
            willChangeValue(for: \.displayValueState)
        }
        
        didSet {
            guard oldValue != currentValueState else { return }
            didChangeValue(for: \.currentValueState)
            didChangeValue(for: \.displayValueState)
        }
    }
    
    /// The pending value state, resulting from a successful write from the local client
    /// to the Afero cloud, prior to the associated Afero peripheral device applying
    /// and reporting the successful application of a new value.
    dynamic internal(set) public var pendingValueState: AferoAttributeValueState? {
        willSet {
            guard newValue != pendingValueState else { return }
            willChangeValue(for: \.currentValueState)
            willChangeValue(for: \.hasPendingValueState)
            willChangeValue(for: \.displayValueState)
        }
        
        didSet {
            guard oldValue != pendingValueState else { return }
            didChangeValue(for: \.pendingValueState)
            didChangeValue(for: \.hasPendingValueState)
            didChangeValue(for: \.displayValueState)
        }

    }
    
    init(descriptor: AferoAttributeDescriptor, currentValueState: AferoAttributeValueState? = nil, pendingValueState: AferoAttributeValueState? = nil) {
        self.descriptor = descriptor
        self.currentValueState = currentValueState
        self.pendingValueState = pendingValueState
    }
    
    // MARK: NSObjectProtocol
    
    public override var hashValue: Int { return descriptor.hashValue }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttribute else { return false }
        return other.descriptor == descriptor && other.currentValueState == currentValueState && other.pendingValueState == pendingValueState
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttribute(
            descriptor: descriptor.copy() as! AferoAttributeDescriptor,
            currentValueState: currentValueState?.copy() as? AferoAttributeValueState,
            pendingValueState: pendingValueState?.copy() as? AferoAttributeValueState
        )
    }
    
    // MARK: KVO
    
    @objc override public class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        switch key {
        case "currentValueState": fallthrough
        case "pendingValueState": fallthrough
        case "hasPendingValueState": fallthrough
        case "displayValueState": fallthrough
            return false
        default:
            return true
        }
    }
    
    // MARK: Computed convenience properties
    
    dynamic public var hasPendingValueState: Bool {
        return pendingValueState != nil
    }
    
    dynamic public var displayValueState: AferoAttributeValueState? {
        return pendingValueState ?? currentValueState
    }

}

//
//@objc public class AferoAttributeCollection: NSObject {
//
//
//}

