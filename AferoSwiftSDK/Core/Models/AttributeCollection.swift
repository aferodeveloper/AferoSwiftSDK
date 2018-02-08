//
//  AttributeCollection.swift
//  Pods
//
//  Created by Justin Middleton on 1/10/18.
//

import Foundation

// MARK: - AferoAttributeDataType -

/// Describes a type for an Afero attribute.

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

// MARK: - AferoAttributeOperation(s) -

@objc public enum AferoAttributeOperation: Int, CustomDebugStringConvertible {

    case read = 1
    case write = 2
    
    public var debugDescription: String {
        var shift = 0
        while (rawValue >> shift != 1) { shift += 1 }
        return ["Read", "Write"][shift]
    }

}

@objcMembers public final class AferoAttributeOperations: NSObject, NSCopying, Codable, OptionSetJSONCoding {
    
    override public var description: String {
        
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
    
    public override var debugDescription: String {
        return "<\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())>: \(description) (\(rawValue))"
    }
    
    // MARK: OptionSetType
    
    public let rawValue: Int
    
    public required init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public override convenience init() {
        self.init(rawValue: 0)
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
            let name = try container.decode(String.self).lowercased()
            switch name {
            case PermissionNames.READ.rawValue.lowercased():
                operations.formUnion(.Read)
            case PermissionNames.WRITE.rawValue.lowercased():
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
            array.append(PermissionNames.READ.rawValue.lowercased())
        }
        
        if contains(.Write) {
            array.append(PermissionNames.WRITE.rawValue.lowercased())
        }
        
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: array)
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String] = []
        
        if contains(.Read) {
            ret.append(PermissionNames.READ.rawValue)
        }
        if contains(.Write) {
            ret.append(PermissionNames.WRITE.rawValue)
        }
        
        return ret

    }
    
    public required convenience init?(json: AferoJSONCodedType?) {
        
        guard let json = (json as? [String])?.map( { $0.lowercased() } ) else { return nil }
        
        var operations = AferoAttributeOperations()
        if json.contains(PermissionNames.READ.rawValue.lowercased()) {
            operations.formUnion(.Read)
        }
        
        if json.contains(PermissionNames.WRITE.rawValue.lowercased()) {
            operations.formUnion(.Write)
        }
        self.init(rawValue: operations.rawValue)
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

// MARK: - AferoAttributeDescriptor -

/// Descriptive metadata about an Afero attribute, including its identifier, type,
/// "semanticType", default value, and operations.

@objcMembers public class AferoAttributeDataDescriptor: NSObject, NSCopying, Codable, AferoJSONCoding {
    
    public override var debugDescription: String {
        return "<AferoAttributeDescriptor> id:\(id) dataType:\(dataType) semanticType:\(String(describing: semanticType)) key:\(String(describing: key)) value:\(String(describing: value)) defaultValue:\(String(describing: defaultValue)) operations:\(String(describing: operations)) givenLength:\(String(describing: _length)) length:\(String(describing: length))"
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
    
    /// The hex representation default value for this attribute, if any.
    public let defaultValue: String?
    
    /// The string representation of the default value for this attribute, if any.
    public let value: String?
    
    /// The max length (in bytes) of this attribute as reported explicitly by the
    /// profile, if any.
    private let _length: Int?
    
    /// The max length (in bytes) of this attribute. If explicitly provided by the profile,
    /// then it that value will be returned. Otherwise, the size of the `dataType`,
    /// if any, is returned.
    /// - note: There is no default `size` returned for `.rawBytes` or `.utf8S` types,
    ///         is `length` for these types must be provided by the profile.
    
    public var length: Int? {
        return _length ?? dataType.size
    }
    
    /// The valid operations (readable, writable) for this attribute.
    public let operations: AferoAttributeOperations

    init(id: Int = 0, type: AferoAttributeDataType, semanticType: String? = nil, key: String? = nil, defaultValue: String? = nil, value: String? = nil, length: Int? = nil, operations: AferoAttributeOperations = []) {
        self.id = id
        self.dataType = type
        self.semanticType = semanticType
        self.key = key
        self.defaultValue = defaultValue
        self.value = value
        self._length = length
        self.operations = operations
    }
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeDataDescriptor else { return false }
        return other.id == id
            && other.dataType == dataType
            && other.semanticType == semanticType
            && other.key == key
            && other.defaultValue == defaultValue
            && other.operations == operations
            && other.value == value
            && other._length == _length
    }
    
    public override var hashValue: Int {
        return id.hashValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeDataDescriptor(id: id, type: dataType, semanticType: semanticType, key: key, defaultValue: defaultValue, operations: operations)
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case id
        case dataType
        case semanticType
        case key
        case defaultValue
        case operations
        case value
        case _length = "length"
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .id: id,
            .dataType: dataType.stringValue!,
            .operations: operations.JSONDict!
        ]
        
        if let semanticType = semanticType {
            ret[.semanticType] = semanticType
        }
        
        if let key = key {
            ret[.key] = key
        }
        
        if let defaultValue = defaultValue {
            ret[.defaultValue] = defaultValue
        }
        
        if let length = _length {
            ret[._length] = length
        }
        
        return ret.stringKeyed
    }
    
    public required convenience init?(json: AferoJSONCodedType?) {
        
        guard let json = json as? [String: Any] else { return nil }
        
        guard
            let id = json[CodingKeys.id.stringValue] as? Int,
            let operations: AferoAttributeOperations = |<(json[CodingKeys.operations.stringValue] as? [String]) else {
                return nil
        }
        
        let dataType: AferoAttributeDataType = AferoAttributeDataType(name: json[CodingKeys.dataType.stringValue] as? String)
        let semanticType = json[CodingKeys.semanticType.rawValue] as? String
        let key = json[CodingKeys.key.rawValue] as? String
        let defaultValue = json[CodingKeys.defaultValue.rawValue] as? String
        let value = json[CodingKeys.value.rawValue] as? String
        let length = json[CodingKeys._length.rawValue] as? Int

        self.init(id: id, type: dataType, semanticType: semanticType, key: key, defaultValue: defaultValue, value: value, length: length, operations: operations)
    }
}

extension AferoAttributeDataDescriptor {
    
    public func attributeValue(for string: String?) -> AttributeValue? {
        return type(of: self).valueForStringLiteral(string, type: dataType)
    }
    
    @available(*, deprecated, message: "Use attributeValue(for:) instead.")
    public func valueForStringLiteral(_ string: String?) -> AttributeValue? {
        return attributeValue(for: string)
    }
    
    static func valueForStringLiteral(_ stringLiteral: String?, type: AferoAttributeDataType) -> AttributeValue? {
        
        AfLogVerbose(String(format: "dataType: %@ will return value for '%@'", type.debugDescription, stringLiteral ?? "<none>"))
        
        
        guard let stringLiteral = stringLiteral else { return nil }
        return AttributeValue(type: type, value: stringLiteral)
    }
}

public extension AferoAttributeDataDescriptor {
    
    public var isWritable: Bool { return operations.contains(.Write) }
}

@objcMembers public final class AferoAttributeOptionFlags: NSObject, OptionSet, Codable, AferoJSONCoding {
    
    // Yes, this is what a bitfield looks like in Swift :(
    
    public typealias RawValue = UInt
    
    fileprivate var value: RawValue = 0
    
    // MARK: NilLiteralConvertible
    
    public init(nilLiteral: Void) {
        self.value = 0
    }
    
    // MARK: RawLiteralConvertible
    
    public init(rawValue: RawValue) {
        self.value = rawValue
    }
    
    static func fromRaw(_ raw: UInt) -> AferoAttributeOptionFlags {
        return self.init(rawValue: raw)
    }
    
    public var rawValue: RawValue { return self.value }
    
    
    // MARK: BooleanType
    
    public var boolValue: Bool {
        return value != 0
    }
    
    // MARK: BitwiseOperationsType
    
    public static var allZeros: AferoAttributeOptionFlags {
        return self.init(rawValue: 0)
    }
    
    // MARK: Actual values
    
    public static func fromMask(_ raw: UInt) -> AferoAttributeOptionFlags {
        return self.init(rawValue: raw)
    }
    
    public convenience init(bitIndex: RawValue) {
        self.init(rawValue: 0x01 << bitIndex)
    }
    
    /// The associated attribute is considered a "primary operation" of the device,
    /// meaning that its state can be reflected, and interacted with, in the gauge.
    public static var PrimaryOperation: AferoAttributeOptionFlags { return self.init(bitIndex: 0) }
    
    /// The associated attribute can be included in local/offline schedules.
    public static var LocallySchedulable: AferoAttributeOptionFlags { return self.init(bitIndex: 1) }
    
    
    // MARK: NSObjectProto
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeOptionFlags else { return false }
        return other.rawValue == rawValue
    }
    
    // Note that this is intentionally (a) named `CodingValues` so as not to
    // conflict with existing Codable-related conventions, and (b) conforms to
    // `CodingKey` just to be a good citizen. But to be clear, `Codable` will
    // NOT recognize this enum automatically.
    
    enum CodingValues: String, CodingKey {
        
        case primaryOperation
        case locallySchedulable = "localSchedulable"
        
        var flagValue: AferoAttributeOptionFlags {
            switch self {
            case .primaryOperation: return .PrimaryOperation
            case .locallySchedulable: return .LocallySchedulable
            }
        }
        
    }
    
    private var arrayRepr: [String] {
        var encoded: [CodingValues] = []
        if contains(type(of: self).PrimaryOperation) {
            encoded.append(.primaryOperation)
        }
        
        if contains(type(of: self).LocallySchedulable) {
            encoded.append(.locallySchedulable)
        }
        return encoded.map { $0.stringValue }
    }
    
    private convenience init(stringArrayRepr: [String]) throws {
        self.init(try stringArrayRepr.map {
            guard let v = CodingValues(stringValue: $0) else { throw "Unknown flag name: \($0)" }
            return v.flagValue
        })
    }
    
    // MARK: Codable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(arrayRepr)
    }
    
    public convenience init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let arrayRepr = try container.decode([String].self)
        try self.init(stringArrayRepr: arrayRepr)
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        return arrayRepr
    }
    
    public required convenience init?(json: AferoJSONCodedType?) {
        
        guard let arrayRepr = json as? [String] else {
            type(of: self).AfLogError("Cannot coerce JSON to [String]: \(String(describing: json))")
            return nil
        }
        
        do {
            try self.init(stringArrayRepr: arrayRepr)
        } catch {
            assert(false, String(reflecting: error))
            type(of: self).AfLogError(String(reflecting: error))
            return nil
        }
        
    }

}

/// Describes a distinct value that is valid for an attribute, along with presentation properties
/// associated with that value.

@objcMembers public final class AferoAttributePresentationValueOption: NSObject, NSCopying, Codable, AferoJSONCoding, ValueOptionPresentable {
    
    override public var description: String {
        return "{ match:\(match), apply:\(apply) }"
    }
    
    public override var debugDescription: String {
        return "\(type(of: self)): \(description)"
    }
    
    /// A value to match against an existing attribute string value. If the attribute's `stringValue` is equal to `match`,
    /// then this `AferoAttributePresentationValueOption` *matches*, and the values in the `apply` property can be applied.
    public let match: String
    
    /// A `[String: Any]`, indicating presentation keys and values that are valid for given attribute.
    public let apply: [String: Any]
    
    public init(match: ValueOptionMatchPresentable, apply: ValueOptionApplyPresentable) {
        self.match = match
        self.apply = apply
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let ret = AferoAttributePresentationValueOption(match: match, apply: apply)
        return ret
    }
    
    // MARK: NSObjectProtocol / Comparable
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributePresentationValueOption else { return false }
        return other.match == match
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case match
        case apply
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(match, forKey: .match)
        try container.encode(apply, forKey: .apply)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let match = try container.decode(String.self, forKey: .match)
        let apply = try container.decode([String: Any].self, forKey: .apply)
        self.init(match: match, apply: apply)
    }

    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            CodingKeys.match: match,
            CodingKeys.apply: apply,
        ].stringKeyed
    }
    
    public convenience init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            return nil
        }
        
        guard
            let match = jsonDict[CodingKeys.match.stringValue] as? ValueOptionMatchPresentable,
            let apply = jsonDict[CodingKeys.apply.stringValue] as? ValueOptionApplyPresentable else {
                type(of: self).AfLogError("Unable to decode DeviceProfile.Presentation.Control.ValueOption: \(String(reflecting: json))")
                return nil
        }
        
        self.init(match: match, apply: apply)
    }

}

@objcMembers public final class AferoAttributePresentationRangeOptions: NSObject, NSCopying, Codable, AferoJSONCoding, RangeOptionsPresentable {
    
    public override var debugDescription: String {
        return "\(type(of: self)): \(description)"
    }
    
    public override var description: String {
        return "{ min:\(min), max:\(max), step:\(step) }, unitLabel:\(String(describing: unitLabel))"
    }
    
    public let min: String
    public let max: String
    public let step: String
    public let unitLabel: String?
    
    public init(min: String, max: String, step: String, unitLabel: String?) {
        self.min = min
        self.max = max
        self.step = step
        self.unitLabel = unitLabel
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributePresentationRangeOptions(min: min, max: max, step: step, unitLabel: unitLabel)
    }
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributePresentationRangeOptions else { return false }
        return other.min == min && other.max == max && other.step == step && other.unitLabel == unitLabel
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case min
        case max
        case step
        case unitLabel
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        var ret: [CodingKeys: Any] = [
            CodingKeys.min: min,
            CodingKeys.max: max,
            CodingKeys.step: step,
        ]
        
        if let unitLabel = unitLabel {
            ret[.unitLabel] = unitLabel
        }
        
        return ret.stringKeyed
    }
    
    public convenience init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else { return nil }
        
        guard
            let min = jsonDict[CodingKeys.min.stringValue] as? String,
            let max = jsonDict[CodingKeys.max.stringValue] as? String,
            let step = jsonDict[CodingKeys.step.stringValue] as? String else {
                type(of: self).AfLogError("Unable to decode DeviceProfile.Presentation.Control.RangeOptions: \(String(reflecting: jsonDict))")
                return nil
        }
        
        let unitLabel = jsonDict[CodingKeys.unitLabel.stringValue] as? String
        
        self.init(min: min, max: max, step: step, unitLabel: unitLabel)
    }
    
}

@objcMembers public class AferoAttributePresentationDescriptor: NSObject, NSCopying, Codable, AferoJSONCoding {
    
    public override var debugDescription: String {
        return "\(type(of: self)): \(description)"
    }
    

    public override var description: String {
        return "{ flags:\(flags), label:\(String(reflecting: label)), rangeOptions:\(String(reflecting: rangeOptions)), valueOptions: \(valueOptions) }"
    }

    public let flags: AferoAttributeOptionFlags
    public let label: String?
    public let rangeOptions: AferoAttributePresentationRangeOptions?
    public let valueOptions: [AferoAttributePresentationValueOption]
    
    private (set) public lazy var valueOptionsMap: [String: [String: Any]] = {
        return self.valueOptions.valueOptionsMap
    }()
    
    init(label: String? = nil, rangeOptions: AferoAttributePresentationRangeOptions? = nil, valueOptions: [AferoAttributePresentationValueOption] = [], flags: AferoAttributeOptionFlags = []) {
        self.label = label
        self.rangeOptions = rangeOptions
        self.valueOptions = valueOptions
        self.flags = flags
    }
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributePresentationDescriptor else { return false }
        return other.label == label
            && other.rangeOptions == rangeOptions
            && other.valueOptions == valueOptions
            && other.flags == flags
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributePresentationDescriptor(label: label, rangeOptions: rangeOptions, valueOptions: valueOptions, flags: flags)
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case flags
        case label
        case rangeOptions
        case valueOptions
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .flags: flags.JSONDict!,
            .valueOptions: valueOptions.map { $0.JSONDict! },
            ]
        
        if let rangeOptions = rangeOptions {
            ret[.rangeOptions] = rangeOptions.JSONDict!
        }
        
        if let label = label {
            ret[.label] = label
        }
        
        return ret.stringKeyed
    }
    
    public required convenience init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else { return nil }
        
        let flags: AferoAttributeOptionFlags = |<(jsonDict[CodingKeys.flags.stringValue]) ?? []
        let label: String? = jsonDict[CodingKeys.label.stringValue] as? String
        let valueOptions: [AferoAttributePresentationValueOption] = |<(jsonDict[CodingKeys.valueOptions.stringValue] as? [AnyObject]) ?? []
        let rangeOptions: AferoAttributePresentationRangeOptions? = |<jsonDict[CodingKeys.rangeOptions.stringValue]
        
        self.init(label: label, rangeOptions: rangeOptions, valueOptions: valueOptions, flags: flags)
    }
    
    public var isPrimaryOperation: Bool { return flags.contains(.PrimaryOperation) }
    
}

// MARK: - AferoAttributeValueState -

/// Represents the current value state of an Afero attribute—its value, when it
/// last changed, and any request id. It does not contain interpretation info.

@objcMembers public class AferoAttributeValueState: NSObject, NSCopying, Codable, AferoJSONCoding {
    
    public override var debugDescription: String {
        return "<AferoAttributeValueState> attributeId:\(String(describing: attributeId)) value:\(stringValue) data:\(String(describing: data)) updatedTimestampMs:\(String(describing: updatedTimestampMs)) requestid:\(String(describing: requestId))"

    }
    
    /// The id of the attribute this state represents.
    let attributeId: Int?
    
    /// Alias for `attributeId`.
    @available(*, deprecated, message: "Use attributeid instead.")
    var id: Int? { return attributeId }
    
    /// The string value of this instance.
    let stringValue: String
    
    @available(*, deprecated, message: "Use stringValue instead.")
    var value: String { return stringValue }
    
    /// The encoded data value of htis instance (if provided).
    let data: String?
    
    /// When this attribute was last updated.
    /// - warning: When an Afero device resets and reports its values, `updatedTimestampMs`
    ///            reflects the time of said report, which will be later than when
    ///            the value was actually changed due to user action, rule execution,
    ///            or MCU activity.
    
    let updatedTimestampMs: NSNumber?
    
    /// Any associated request id, returned from the Afero cloud when setting an attribute.
    let requestId: Int?
    
    init(attributeId: Int? = nil, value: String, data: String? = nil, updatedTimestampMs: NSNumber? = nil, requestId: Int? = nil) {
        self.attributeId = attributeId
        self.stringValue = value
        self.data = data
        self.updatedTimestampMs = updatedTimestampMs
        self.requestId = requestId
    }
    
    convenience init(attributeId: Int? = nil, value: String, data: String? = nil, updatedTimestamp: Date, requestId: Int? = nil) {
        self.init(
            attributeId: attributeId,
            value: value,
            data: data,
            updatedTimestampMs: updatedTimestamp.millisSince1970,
            requestId: requestId
        )
    }
    
    /// When this attribute was last updated.
    /// - warning: When an Afero device resets and reports its values, `updatedTimestamp`
    ///            reflects the time of said report, which will be later than when
    ///            the value was actually changed due to user action, rule execution,
    ///            or MCU activity.
    
    public var updatedTimestamp: Date? {
        guard let ts = updatedTimestampMs else { return nil }
        return Date.dateWithMillisSince1970(ts)
    }
    
    // MARK: NSObjectProtocol
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttributeValueState else { return false }
        return other.attributeId == attributeId
            && other.stringValue == stringValue
            && other.data == data
            && other.updatedTimestampMs == updatedTimestampMs
            && other.requestId == requestId
    }
    
    public override var hashValue: Int {
        return stringValue.hashValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeValueState(
            attributeId: attributeId,
            value: stringValue,
            data: data,
            updatedTimestampMs: updatedTimestampMs,
            requestId: requestId
        )
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case attributeId = "id"
        case stringValue = "value"
        case data
        case updatedTimestampMs = "updatedTimestamp"
        case requestId = "reqId"
        
        var hashValue: Int { return rawValue.hashValue }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stringValue, forKey: .stringValue)
        try container.encodeIfPresent(attributeId, forKey: .attributeId)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(requestId, forKey: .requestId)
        try container.encodeIfPresent(updatedTimestampMs?.int64Value, forKey: .updatedTimestampMs)
        
    }
    
    public required convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let stringValue = try container.decode(String.self, forKey: .stringValue)
        let attributeId = try container.decodeIfPresent(Int.self, forKey: .attributeId)
        let data = try container.decodeIfPresent(String.self, forKey: .data)
        let requestId = try container.decodeIfPresent(Int.self, forKey: .requestId)
        
        var updatedTimestampMs: NSNumber?
        if let maybeUpdatedTimestampMs = try container.decodeIfPresent(Int64.self, forKey: .updatedTimestampMs) {
            updatedTimestampMs = NSNumber(value: maybeUpdatedTimestampMs)
        }
        
        self.init(attributeId: attributeId, value: stringValue, data: data, updatedTimestampMs: updatedTimestampMs, requestId: requestId)
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .stringValue: stringValue,
        ]
        
        if let updatedTimestampMs = updatedTimestampMs {
            ret[.updatedTimestampMs] = updatedTimestampMs
        }
        
        if let attributeId = attributeId {
            ret[.attributeId] = attributeId
        }
        
        if let data = data {
            ret[.data] = data
        }
        
        if let requestId = requestId {
            ret[.requestId] = requestId
        }
        
        return ret.reduce([String: Any]()) {
            curr, next in
            var ret = curr
            ret[next.key.rawValue] = next.value
            return ret
        }
        
    }
    
    public required convenience init?(json: AferoJSONCodedType?) {

        guard let jsonDict = json as? [String: Any] else {
            return nil
        }
        
        guard let value = jsonDict[CodingKeys.stringValue.rawValue] as? String else {
            return nil
        }

        let data = jsonDict[CodingKeys.data.rawValue] as? String
        let requestId = jsonDict[CodingKeys.requestId.rawValue] as? Int
        let attributeId = jsonDict[CodingKeys.attributeId.rawValue] as? Int
        let updatedTimestampMs = jsonDict[CodingKeys.updatedTimestampMs.rawValue] as? NSNumber
        
        self.init(attributeId: attributeId, value: value, data: data, updatedTimestampMs: updatedTimestampMs, requestId: requestId)
    }
    
}

// MARK: - AferoAttribute -

/// Represents an Afero attribute on an Afero peripheral device.
///
/// - note: This class has no 1:1 implementation on the Afero cloud; it's constructed for the SDK's
///         purposes only.

@objcMembers public class AferoAttribute: NSObject, NSCopying, Codable, AferoJSONCoding {
    
    public override var debugDescription: String {
        return "<AferoAttribute> dataDesc:\(String(reflecting: dataDescriptor)) presentationDesc:\(String(reflecting: presentationDescriptor)) current:\(String(reflecting: currentValueState)) pending:\(String(reflecting: pendingValueState))"
    }
    
    /// Metadata describing the native, dimensionless storage of this attribute (its primitive type).
    dynamic internal(set) public var dataDescriptor: AferoAttributeDataDescriptor
    
    /// Metadata describing how this attribute should be presented.
    dynamic internal(set) public var presentationDescriptor: AferoAttributePresentationDescriptor?
    
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
            willChangeValue(for: \.pendingValueState)
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
    
    /// Initialize an `AferoAttribute` with descriptors for data and presentation, current, and pending value state.
    /// - parameter dataDescriptpr: The structure describing the logical type of data being stored,
    /// - parameter presentationDescriptor: The structure that supports, describes
    ///             how this attribute should be interpreted for presentation in a user interface
    ///             or consumption by analytics.
    /// - parameter currentValueState: The current value state reported by the Afero peripheral device to the Afero cloud.
    /// - parameter pendingValueState: The pending value state, resulting from a successful write from the local client
    ///             to the Afero cloud, prior to the associated Afero peripheral device applying
    ///             and reporting the successful application of a new value.
    
    init(dataDescriptor: AferoAttributeDataDescriptor, presentationDescriptor: AferoAttributePresentationDescriptor? = nil, currentValueState: AferoAttributeValueState? = nil, pendingValueState: AferoAttributeValueState? = nil) {
        self.presentationDescriptor = presentationDescriptor
        self.dataDescriptor = dataDescriptor
        self.currentValueState = currentValueState
        self.pendingValueState = pendingValueState
    }
    
    // MARK: NSObjectProtocol
    
    public override var hashValue: Int { return dataDescriptor.hashValue }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AferoAttribute else { return false }
        return other.dataDescriptor == dataDescriptor && other.currentValueState == currentValueState && other.pendingValueState == pendingValueState
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttribute(
            dataDescriptor: dataDescriptor.copy() as! AferoAttributeDataDescriptor,
            presentationDescriptor: presentationDescriptor?.copy() as? AferoAttributePresentationDescriptor,
            currentValueState: currentValueState?.copy() as? AferoAttributeValueState,
            pendingValueState: pendingValueState?.copy() as? AferoAttributeValueState
        )
    }
    
    // MARK: KVO
    
    override public class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        switch key {
            
        case "currentValueState": fallthrough
        case "pendingValueState": fallthrough
        case "hasPendingValueState": fallthrough
        case "displayValueState":
            return false
            
        default:
            return true
            
        }
    }
    
    // MARK: Computed convenience properties
    
    /// If true, a successful call has been made to the Afero cloud to set this attribute's value
    /// on the device with which it's associated, however the client has not yet received
    /// an update from the cloud confirming that the associated device has applied and confirmed
    /// the change.
    
    dynamic public var hasPendingValueState: Bool {
        return pendingValueState != nil
    }
    
    /// Shortcut for getting the state that should be displayed in a UI;
    /// `pendingValueState` if it's non-nil, otherwise `currentValueState`.
    
    dynamic public var displayValueState: AferoAttributeValueState? {
        return pendingValueState ?? currentValueState
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case dataDescriptor
        case presentationDescriptor
        case currentValueState
        case pendingValueState
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .dataDescriptor: dataDescriptor.JSONDict!
        ]
        
        if let presentationDescriptor = presentationDescriptor {
            ret[.presentationDescriptor] = presentationDescriptor
        }
        
        if let currentValueState = currentValueState?.JSONDict {
            ret[.currentValueState] = currentValueState
        }
        
        if let pendingValueState = pendingValueState?.JSONDict {
            ret[.pendingValueState] = pendingValueState
        }
        
        return ret.stringKeyed
    }
    
    public required convenience init?(json: AferoJSONCodedType?) {
        
        guard let json = json as? [String: Any] else { return nil }
        
        guard let dataDescriptor: AferoAttributeDataDescriptor = |<(json[CodingKeys.dataDescriptor.stringValue] as? [String: Any]) else {
            return nil
        }

        let presentationDescriptor: AferoAttributePresentationDescriptor? = |<(json[CodingKeys.presentationDescriptor.stringValue] as? [String: Any])
        let currentValueState: AferoAttributeValueState? = |<(json[CodingKeys.currentValueState.stringValue] as? [String: Any])
        let pendingValueState: AferoAttributeValueState? = |<(json[CodingKeys.pendingValueState.stringValue] as? [String: Any])
        
        self.init(
            dataDescriptor: dataDescriptor,
            presentationDescriptor: presentationDescriptor,
            currentValueState: currentValueState,
            pendingValueState: pendingValueState
        )
        
    }

}

// MARK: - AferoAttributeCollectionError -

/// Errors that can be emitted by an `AferoAttributeCollection`

@objc public enum AferoAttributeCollectionError: Int, Error {
    
    /// One or more duplicate attribute ids found during initialization or modification
    /// of attribute storage. Attribute ids must be unique.
    case duplicateAttributeId = 1
    
    /// One or more duplicate attribute keys were detected. Attribute keys must be unique.
    case duplicateKey
    
    /// An attributeId wasn't recognized when attempting to modify an existing attribute.
    case unrecognizedAttributeId
    
    /// An key wasn't recognized when attempting to modify an existing attribute.
    case unrecognizedKey
    
    
    public var localizedDescription: String {
        switch self {
        case .duplicateAttributeId: return "One or more duplicate attribute ids found; attribute ids must be unique."
        case .duplicateKey: return "One or more duplicate attribute keys found; attribute keys must be unique."
        case .unrecognizedAttributeId: return "The attributeId wasn't recognized when attempting to modify an existing attribute."
        case .unrecognizedKey: return "The key wasn't recognized when attempting to modify an existing attribute"
        }
    }
    
}

// MARK: - AferoAttributeCollection -

/// A collection of Afero attributes.
///
/// # Key-Value Observability
///
/// AferoAttributeCollection is key-value-observable for `attributes`, `attributeKeys`,
/// and `attributeIds`. Observers of individual `AferoAttributes` coming from a
/// collection should observe one of these to ensure that they're able to
/// stop observing `AferoAttribute` instances when they're removed from a collection
/// (e.g. due to a profile reload).

@objcMembers public class AferoAttributeCollection: NSObject, Codable {

    // MARK: Lifecycle
    
    init(attributes: [AferoAttribute]) throws {
        
        super.init()
        
        try attributes.enumerated().forEach {
            _, attr in try register(attribute: attr)
        }
        
    }
    
    convenience override init() {
        try! self.init(attributes: [])
    }
    
    convenience init(descriptors: [AferoAttributeDataDescriptor]) throws {
        try self.init(attributeConfigs: descriptors.map { return ($0, nil) })
    }

    // MARK: Model
    
    /// Primary storage for attributes, keyed by id.
    private var attributeRegistry: [Int: AferoAttribute] = [:]
    
    /// An index of keys to attribute ids.
    private var attributeKeyMap: [String: Int] = [:]

    // MARK: KVO
    
    override public class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        return false
    }
    
    fileprivate func emitWillChangeNotifications() {
        willChangeValue(for: \.attributes)
        willChangeValue(for: \.attributeKeys)
        willChangeValue(for: \.attributeIds)
    }
    
    fileprivate func emitDidChangeNotifications() {
        didChangeValue(for: \.attributes)
        didChangeValue(for: \.attributeKeys)
        didChangeValue(for: \.attributeIds)
    }
    
    // MARK: Internal — Model Definition

    /// Register the given attribues, and send appropriate change notifications.
    /// - parameter attributes: The attributes to register.
    /// - throws: An `AferoAttributeCollectionError` if something goes wrong.
    /// - warning: This is **not** atomic. If error is thrown, the collection will
    ///            **not** be reverted to its previous state.
    
    func register<T: Collection>(attributes: T) throws where T.Element == AferoAttribute {
        emitWillChangeNotifications()
        defer { emitDidChangeNotifications() }
        try attributes.forEach { try register(attribute: $0, notifyObservers: false) }
    }
    
    /// Register an `AferoAttribute`, optionally notifying observers.
    /// - parameter attribute: the attribute to register.
    /// - parameter notifyObservers: If `true` (default) will notify observers of
    ///                              non-automatically notified property changes.
    ///                              If `false`, will not notify, and the caller is responsible
    ///                              for doing so .
    /// - seealso: emitWillChangeNotifications()`, `emitDidChangeNotifications()`
    /// - throws: An AferoAttributeCollectionError if something goes wrong.

    func register(attribute: AferoAttribute, notifyObservers: Bool = true) throws {
        
        var key: String?
        
        guard attributeRegistry[attribute.dataDescriptor.id] == nil else {
            afLogError("Duplicate attribute id: \(attribute.dataDescriptor.id) (attribute ids must be unique)")
            throw AferoAttributeCollectionError.duplicateAttributeId
        }
        
        if let maybeKey = attribute.dataDescriptor.key {
            guard attributeKeyMap[maybeKey] == nil else {
                afLogError("Duplicate attribute key: \(maybeKey) (attribute keys must be unique)")
                throw AferoAttributeCollectionError.duplicateKey
            }
            key = maybeKey
        }
        
        if notifyObservers { emitWillChangeNotifications() }
        defer { if notifyObservers { emitDidChangeNotifications() } }
        attributeRegistry[attribute.dataDescriptor.id] = attribute
        if let key = key {
            attributeKeyMap[key] = attribute.dataDescriptor.id
        }
        
    }
    
    /// Unregister an `AferoAttribute` from the collection, optionally notifying observers.
    /// - parameter id: The `id` of the attribute to remove.
    /// - parameter notifyObservers: If `true` (default) will notify observers of
    ///                              non-automatically notified property changes.
    ///                              If `false`, will not notify, and the caller is responsible
    ///                              for doing so .
    /// - seealso: emitWillChangeNotifications()`, `emitDidChangeNotifications()`
    /// - throws: An AferoAttributeCollectionError if something goes wrong.

    @discardableResult
    func unregister(attributeId id: Int, notifyObservers: Bool = true) -> AferoAttribute? {
        guard let attribute = attributeRegistry[id] else { return nil }
        if notifyObservers { emitWillChangeNotifications() }
        defer { if notifyObservers { emitDidChangeNotifications() }}
        if let key = attribute.dataDescriptor.key {
            attributeKeyMap.removeValue(forKey: key)
        }
        return attributeRegistry.removeValue(forKey: id)
    }
    
    /// Unregister an `AferoAttribute` from the collection, optionally notifying observers.
    /// - parameter key: Possibly a `key` of an attribute to remove. If nil, returns without change.
    /// - parameter notifyObservers: If `true` (default) will notify observers of
    ///                              non-automatically notified property changes.
    ///                              If `false`, will not notify, and the caller is responsible
    ///                              for doing so .
    /// - seealso: emitWillChangeNotifications()`, `emitDidChangeNotifications()`
    /// - throws: An AferoAttributeCollectionError if something goes wrong.
    
    @discardableResult
    func unregister(attributeKey key: String?, notifyObservers: Bool = true) -> AferoAttribute? {
        guard let key = key else { return nil }
        guard let attributeId = attributeKeyMap[key] else { return nil }
        return unregister(attributeId: attributeId, notifyObservers: notifyObservers)
    }
    
    /// Unregister all attributes, and send appropriate change notifications.
    /// - warning: This is **not** atomic. If error is thrown, the collection will
    ///            **not** be reverted to its previous state.
    
    @discardableResult
    func unregisterAllAttributes() -> [AferoAttribute] {
        
        emitWillChangeNotifications()
        defer { emitDidChangeNotifications() }
        
        return attributeIds.flatMap {
            unregister(attributeId: $0, notifyObservers: false)
        }
    }
    
    // MARK: Internal - Model State
    
//    func setDescriptor(_ descriptor: AferoAttributeDescriptor, forAttributeWithId id: Int) throws {
//        guard let attribute = attribute(forId: id) else {
//            afLogError("Unrecognized attribute id \(id)")
//            throw AferoAttributeCollectionError.unrecognizedAttributeId
//        }
//        attribute.descriptor = descriptor
//    }
    
    func setPending(valueState state: AferoAttributeValueState?, forAttributeWithId id: Int) throws {
        
        guard let attribute = attribute(forId: id) else {
            afLogError("Unrecognized attribute id \(id)")
            throw AferoAttributeCollectionError.unrecognizedAttributeId
        }
        
        attribute.pendingValueState = state
    }
    
    func setPending(value: String, data: String? = nil, updatedTimestamp: Date = Date(), requestId: Int? = nil, forAttributeWithId id: Int) throws {
        let state = AferoAttributeValueState(value: value, data: data, updatedTimestamp: updatedTimestamp, requestId: requestId)
        try setPending(valueState: state, forAttributeWithId: id)
    }
    
    func setCurrent(valueState state: AferoAttributeValueState?, forAttributeWithId id: Int) throws {
        
        guard let attribute = attribute(forId: id) else {
            afLogError("Unrecognized attribute id \(id)")
            throw AferoAttributeCollectionError.unrecognizedAttributeId
        }
        
        attribute.currentValueState = state
    }
    
    func setCurrent(value: String, data: String? = nil, updatedTimestamp: Date = Date(), requestId: Int? = nil, forAttributeWithId id: Int) throws {
        let state = AferoAttributeValueState(value: value, data: data, updatedTimestamp: updatedTimestamp, requestId: requestId)
        try setCurrent(valueState: state, forAttributeWithId: id)
    }
    
    // MARK: Public
    
    /// A `Set` of all attributeIds in the collection.
    
    public dynamic var attributeIds: Set<Int> {
        return Set(attributeRegistry.keys)
    }
    
    /// A `Set` of all attributeKeys in the collection.
    
    public dynamic var attributeKeys: Set<String> {
        return Set(attributeKeyMap.keys)
    }
    
    /// A `Set` of all `AferoAttributes` in the collection.
    
    public dynamic var attributes: Set<AferoAttribute> {
        return Set(attributeRegistry.values)
    }
    
    /// Fetch an attribute for the given id
    /// - parameter id: The id of the attribute to fetch. If `nil`, returns `nil`.
    /// - returns: An `AferoAttribute`, if `id` is non-`nil` and the attribute exists.
    ///            Otherwise returns nil.
    
    public func attribute(forId id: Int?) -> AferoAttribute? {
        guard let id = id else { return nil }
        return attributeRegistry[id]
    }
    
    /// Fetch an attribute for the given key.
    /// - parameter key: The key of the attribute to fetch. If `nil`, returns `nil`.
    /// - returns: An `AferoAttribute`, if `key` is non-`nil` and an attribute exists
    ///            with that key. Otherwise returns nil.
    
    public func attribute(forKey key: String?) -> AferoAttribute? {
        guard let key = key else { return nil }
        return attribute(forId: attributeKeyMap[key])
    }
    
}

// MARK: Profile Handling

extension AferoAttributeCollection {
    
    /// Initialize with a collection of `DeviceProfile.AttributeConfig` types.
    convenience init<T: Collection>(attributeConfigs: T) throws
        where T.Element == DeviceProfile.AttributeConfig {
        let attributes = attributeConfigs.map {
            return AferoAttribute(dataDescriptor: $0.0, presentationDescriptor: $0.1)
        }
        try self.init(attributes: attributes)
    }
    
    /// Register the given attribues, and send appropriate change notifications.
    /// - parameter attributes: The attributes to register.
    /// - throws: An `AferoAttributeCollectionError` if something goes wrong.
    /// - warning: This is **not** atomic. If error is thrown, the collection will
    ///            **not** be reverted to its previous state.
    
    func register<T: Collection>(attributeConfigs: T) throws where T.Element == DeviceProfile.AttributeConfig {
        emitWillChangeNotifications()
        defer { emitDidChangeNotifications() }
        try attributeConfigs.forEach {
            try register(
                attribute: AferoAttribute(
                    dataDescriptor: $0.dataDescriptor,
                    presentationDescriptor: $0.presentationDescriptor
                ),
                notifyObservers: false)
        }
    }
    
    /// Initialize with attributes from the given profile.
    convenience init(profile: DeviceProfile) throws {
        try self.init(attributeConfigs: profile.attributeConfigs())
    }

    /// Using the given profile, reload all attributes in this collection.
    /// This results in all attributes being unregistered, and new attributes being registered,
    /// if the new profile is the same as the old one.
    /// If the new profile is `nil`, all attributes are removed.
    
    func configure(with profile: DeviceProfile?) throws {
        unregisterAllAttributes()
        guard let configs = profile?.attributeConfigs() else { return }
        try register(attributeConfigs: configs)
    }
    
}

// MARK: - Attribute Collection KVO Proxies -

public extension AferoAttributeCollection {

    /// Register for KVO changes on individual attributes.
    /// - parameter id: The id of the attribute to observe. If nil, this method returns nil immediately.
    /// - parameter keyPath: The `KeyPath` to observe on the attribute.
    /// - parameter changeHandler: The handler for changes.
    /// - returns: An `NSKeyValueObservation` if we've successfully registered for notifications,
    ///            or nil if `id` is nil or the attribute wasn't found.
    
    public func observeAttribute<Value>(withId id: Int?, on keyPath: KeyPath<AferoAttribute, Value>, using changeHandler: @escaping (AferoAttribute, NSKeyValueObservedChange<Value>) -> Void) throws -> NSKeyValueObservation? {
        
        guard let attribute = attribute(forId: id) else {
            afLogError("Unrecognized attributeId: \(String(describing: id))")
            throw AferoAttributeCollectionError.unrecognizedAttributeId
        }
        
        return attribute.observe(keyPath, changeHandler: changeHandler)
    }
    
    /// Register for KVO changes on individual attributes.
    /// - parameter id: The id of the attribute to observe. If nil, this method returns nil immediately.
    /// - parameter keyPath: The `KeyPath` to observe on the attribute.
    /// - parameter changeHandler: The handler for changes.
    /// - returns: An `NSKeyValueObservation` if we've successfully registered for notifications,
    ///            or nil if `id` is nil or the attribute wasn't found.
    
    public func observeAttribute<Value>(withKey key: String?, on keyPath: KeyPath<AferoAttribute, Value>, using changeHandler: @escaping (AferoAttribute, NSKeyValueObservedChange<Value>) -> Void) throws -> NSKeyValueObservation? {
        
        guard let attribute = attribute(forKey: key) else {
            afLogError("Unrecognized key: \(String(describing: key))")
            throw AferoAttributeCollectionError.unrecognizedKey
        }
        
        return attribute.observe(keyPath, changeHandler: changeHandler)
    }

}

