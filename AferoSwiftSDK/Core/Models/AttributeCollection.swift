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
        case "boolean":     self = .boolean
        case "sint8":       self = .sInt8
        case "sint16":      self = .sInt16
        case "sint32":      self = .sInt32
        case "sint64":      self = .sInt64
        case "fixed_16_16": fallthrough
        case "q1516":       self = .q1516
        case "fixed_32_32": fallthrough
        case "q3132":       self = .q3132
        case "utf8s":       self = .utf8S
        case "bytes":       self = .bytes
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


@objc public class AferoAttributeDescriptor: NSObject, Codable {
    
    // MARK: NSCoding
    
    internal(set) public var id: Int
    internal(set) public var dataType: AferoAttributeDataType
    internal(set) public var semanticType: String?
    internal(set) public var defaultValue: String?
    internal(set) public var operations: AferoAttributeOperations = AferoAttributeOperations(rawValue: 0)

    init(id: Int = 0, type: AferoAttributeDataType, semanticType: String? = nil, defaultValue: String? = nil, operations: AferoAttributeOperations = [.Read]) {
        self.id = id
        self.dataType = type
        self.semanticType = semanticType
        self.defaultValue = defaultValue
        self.operations = operations
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeDescriptor else { return false }
        return other.id == id
            && other.dataType == dataType
            && other.semanticType == semanticType
            && other.defaultValue == defaultValue
            && other.operations == operations
    }
    
    public override var hashValue: Int {
        return id.hashValue
    }
    
}

@objc public class AferoAttribute: NSObject {
    
    
}

@objc public class AferoAttributeCollection: NSObject {

    
}
