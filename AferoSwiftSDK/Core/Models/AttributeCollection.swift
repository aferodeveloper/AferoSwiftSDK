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

@objcMembers public class AferoAttributeDescriptor: NSObject, NSCopying, Codable, AferoJSONCoding {
    
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
        guard let other = object as? AferoAttributeDescriptor else { return false }
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
        return AferoAttributeDescriptor(id: id, type: dataType, semanticType: semanticType, key: key, defaultValue: defaultValue, operations: operations)
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

extension AferoAttributeDescriptor {
    
    func attributeValue(for string: String?) -> AttributeValue? {
        return type(of: self).valueForStringLiteral(string, type: dataType)
    }
    
    @available(*, deprecated, message: "Use attributeValue(for:) instead.")
    func valueForStringLiteral(_ string: String?) -> AttributeValue? {
        return attributeValue(for: string)
    }
    
    static func valueForStringLiteral(_ stringLiteral: String?, type: AferoAttributeDataType) -> AttributeValue? {
        
        AfLogVerbose(String(format: "dataType: %@ will return value for '%@'", type.debugDescription, stringLiteral ?? "<none>"))
        
        
        guard let stringLiteral = stringLiteral else { return nil }
        return AttributeValue(type: type, value: stringLiteral)
    }
}

public extension AferoAttributeDescriptor {
    
    public var isWritable: Bool { return operations.contains(.Write) }
}

// MARK: - AferoAttributeValueState -

/// Represents the current value state of an Afero attribute—its value, when it
/// last changed, and any request id. It does not contain interpretation info.

@objcMembers public class AferoAttributeValueState: NSObject, NSCopying, Comparable, Codable, AferoJSONCoding {
    
    public override var debugDescription: String {
        return "<AferoAttributeValueState> value:\(stringValue) data:\(data) updatedTimestampMs:\(updatedTimestampMs) requestid:\(String(describing: requestId))"

    }
    
    /// The string value of this instance.
    let stringValue: String
    
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
        self.stringValue = value
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
        return other.stringValue == stringValue && other.data == data && other.updatedTimestampMs == updatedTimestampMs && other.requestId == requestId
    }
    
    public override var hashValue: Int {
        return stringValue.hashValue
    }
    
    // MARK: NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return AferoAttributeValueState(value: stringValue, data: data, updatedTimestampMs: updatedTimestampMs, requestId: requestId)
    }
    
    // MARK: Comparable
    
    /// Compares by updatedTimestamp only. For comparing by value, etc,
    /// convert the `value` to a meaningful type first.
    
    public static func <(lhs: AferoAttributeValueState, rhs: AferoAttributeValueState) -> Bool {
        return lhs.updatedTimestamp < rhs.updatedTimestamp
    }
    
    // MARK: AferoJSONCoding
    
    enum CodingKeys: String, CodingKey {
        case stringValue = "value"
        case data
        case updatedTimestampMs = "updatedTimestamp"
        case requestId = "reqId"
        
        var hashValue: Int { return rawValue.hashValue }
    }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .stringValue: stringValue,
            .updatedTimestampMs: updatedTimestampMs,
        ]
        
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
        
        guard let value = jsonDict[CodingKeys.stringValue.rawValue] as? String,
            let updatedTimestampMs = jsonDict[CodingKeys.updatedTimestampMs.rawValue] as? NSNumber else {
                return nil
        }

        let data = jsonDict[CodingKeys.data.rawValue] as? String
        let requestId = jsonDict[CodingKeys.requestId.rawValue] as? Int
        
        self.init(value: value, data: data, updatedTimestampMs: updatedTimestampMs.int64Value, requestId: requestId)
    }
    
}

// MARK: - AferoAttribute -

/// Represents an Afero attribute on an Afero peripheral device.

@objcMembers public class AferoAttribute: NSObject, NSCopying, Codable, AferoJSONCoding {
    
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
    
    dynamic public var hasPendingValueState: Bool {
        return pendingValueState != nil
    }
    
    dynamic public var displayValueState: AferoAttributeValueState? {
        return pendingValueState ?? currentValueState
    }
    
    // MARK: Codable
    
    enum CodingKeys: String, CodingKey {
        case descriptor
        case currentValueState
        case pendingValueState
    }
    
    // MARK: AferoJSONCoding
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [CodingKeys: Any] = [
            .descriptor: descriptor.JSONDict!
        ]
        
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
        
        guard let descriptor: AferoAttributeDescriptor = |<(json[CodingKeys.descriptor.stringValue] as? [String: Any]) else {
            return nil
        }
        
        let currentValueState: AferoAttributeValueState? = |<(json[CodingKeys.currentValueState.stringValue] as? [String: Any])
        let pendingValueState: AferoAttributeValueState? = |<(json[CodingKeys.pendingValueState.stringValue] as? [String: Any])
        
        self.init(descriptor: descriptor, currentValueState: currentValueState, pendingValueState: pendingValueState)
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
    
    convenience init(descriptors: [AferoAttributeDescriptor]) throws {
        let attributes = descriptors.map {
            return AferoAttribute(descriptor: $0)
        }
        try self.init(attributes: attributes)
    }

    // MARK: Model
    
    /// Primary storage for attributes, keyed by id.
    private var attributeRegistry: [Int: AferoAttribute] = [:]
    
    /// An index of keys to attribute ids.
    private var attributeKeyMap: [String: Int] = [:]
    
    private func emitWillChangeNotifications() {
        willChangeValue(for: \.attributes)
        willChangeValue(for: \.attributeKeys)
        willChangeValue(for: \.attributeIds)
    }
    
    private func emitDidChangeNotifications() {
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
    
    func register<T: Sequence>(attributes: T) throws where T.Element == AferoAttribute {
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
        
        guard attributeRegistry[attribute.descriptor.id] == nil else {
            afLogError("Duplicate attribute id: \(attribute.descriptor.id) (attribute ids must be unique)")
            throw AferoAttributeCollectionError.duplicateAttributeId
        }
        
        if let maybeKey = attribute.descriptor.key {
            guard attributeKeyMap[maybeKey] == nil else {
                afLogError("Duplicate attribute key: \(maybeKey) (attribute keys must be unique)")
                throw AferoAttributeCollectionError.duplicateKey
            }
            key = maybeKey
        }
        
        if notifyObservers { emitWillChangeNotifications() }
        defer { if notifyObservers { emitDidChangeNotifications() } }
        attributeRegistry[attribute.descriptor.id] = attribute
        if let key = key {
            attributeKeyMap[key] = attribute.descriptor.id
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
        if let key = attribute.descriptor.key {
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

