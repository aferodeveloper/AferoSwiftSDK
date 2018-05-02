//
//  SemanticClass.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 4/26/18.
//

import Foundation
import CocoaLumberjack


@objcMembers class SemanticClassPropertyKey {
    static let UnitsPerSecond = "unitsPerSecond"
    static let UTS35FormatString = "UTS35FormatString"
    static let ISO8601Options = "ISO8601Options"
    static let TimeZoneIdentifer = "timeZoneIdentifier"
    static let TimeZoneAbbreviation = "timeZoneAbbreviation"
}

@objcMembers class SemanticClassIdentifier: NSString {
    static let ISO8601Date = "ISO8601Date"
    static let UTS35Date = "UTS35Date"
    static let UNIXEpochDate = "UNIXEpochSecondsDate"
    static let UNIXEpochSecondsDate = "UNIXEpochDate"
    static let UNIXEpochMillisecondsDate = "UNIXEpochMillisecondsDate"
}

@objc protocol AferoSemanticClassReferencing: class, NSObjectProtocol {
    func semanticClass(for identifier: String) -> AferoAttributeSemanticClassDescriptor?
}

infix operator <<-:  AdditionPrecedence
infix operator ← :  AdditionPrecedence

enum AferoSemanticClassError: LocalizedError, CustomNSError, Equatable {
    
    case unrecognizedSemanticClass(String)
    case duplicateSemanticClass(String)
    
    // MARK: <LocalizedError>
    
    var errorDescription: String? {
        switch self {
        case .unrecognizedSemanticClass(let name): return "\(type(of: self)).Unrecognized semantic class: '\(name)'"
        case .duplicateSemanticClass(let name): return "\(type(of: self)).Duplicate semantic class: '\(name)'"
        }
    }
    
    // MARK: <CustomNSError>
    
    var errorCode: Int {
        switch self {
        case .unrecognizedSemanticClass: return -1
        case .duplicateSemanticClass: return -2
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .unrecognizedSemanticClass(let name): return ["name": name]
        case .duplicateSemanticClass(let name): return ["name": name]
        }
    }
    
    static var errorDomain: String {
        return "\(self)"
    }
    
    // MARK: <Equatable>
    
    static func ==(lhs: AferoSemanticClassError, rhs: AferoSemanticClassError) -> Bool {
        switch (lhs, rhs) {
            
        case let (.unrecognizedSemanticClass(ln), .unrecognizedSemanticClass(rn)):
            return ln == rn
            
        case let (.duplicateSemanticClass(ln), .duplicateSemanticClass(rn)):
            return ln == rn
            
        default:
            return false
        }
    }
    
}

@objcMembers class AferoSemanticClassTable: NSObject, AferoSemanticClassReferencing {
    
    private var identifierToClassMap: [String: AferoAttributeSemanticClassDescriptor] =  [:]
    
    @discardableResult
    func register(semanticClass: AferoAttributeSemanticClassDescriptor) throws -> AferoSemanticClassTable {
        
        try semanticClass.isa.forEach {
            guard identifierToClassMap[$0] != nil else {
                throw AferoSemanticClassError.unrecognizedSemanticClass($0)
            }
        }
        
        guard identifierToClassMap[semanticClass.identifier] == nil else {
            throw AferoSemanticClassError.duplicateSemanticClass(semanticClass.identifier)
        }
        
        let mySemanticClass = semanticClass.builder()
            .set(classTable: self)
            .build()
        
        identifierToClassMap[semanticClass.identifier] = mySemanticClass
        
        // Register the value transformer if necessary
        
        if
            ValueTransformer.init(forName: mySemanticClass.valueTransformerName) == nil,
            let cls = mySemanticClass.valueTransformerClass as? AferoSemanticValueTransformer.Type,
            let xformer = cls.init(properties: mySemanticClass.properties) as? ValueTransformer {
            
            ValueTransformer.setValueTransformer(xformer, forName: mySemanticClass.valueTransformerName)
            
        }
        
        return self
    }
    
    @discardableResult
    static func <<- (lhs: AferoSemanticClassTable, rhs: AferoAttributeSemanticClassDescriptor) throws -> AferoSemanticClassTable {
        return try lhs.register(semanticClass: rhs)
    }
    
    @discardableResult
    static func ← (lhs: AferoSemanticClassTable, rhs: AferoAttributeSemanticClassDescriptor) throws -> AferoSemanticClassTable {
        return try lhs <<- rhs
    }
    
    var semanticClasses: LazyMapCollection<[String : AferoAttributeSemanticClassDescriptor], AferoAttributeSemanticClassDescriptor> {
        let ret = identifierToClassMap.values.lazy
        return ret
    }
    
    // MARK: <AferoSemanticClassReferencing>
    
    func semanticClass(for identifier: String) -> AferoAttributeSemanticClassDescriptor? {
        return identifierToClassMap[identifier]
    }
    
}

/// Represents properties for a semantic claass representation, and provides a property
/// inheritance mechanism.

@objcMembers class AferoAttributeSemanticClassDescriptor: NSObject {
    
    public let identifier: String
    public let isa: [String]
    public let semanticDescription: String?
    
    lazy fileprivate var _isa: [AferoAttributeSemanticClassDescriptor] = {
        return self.isa.compactMap { self.classTable?.semanticClass(for: $0) }
    }()
    
    let properties: [String: NSObject]
    
    weak private(set) var classTable: AferoSemanticClassReferencing?
    
    init(identifier: String, isa: [String]? = nil, properties: [String: NSObject]? = nil, classTable: AferoSemanticClassReferencing? = nil, semanticDescription: String? = nil) {
        self.identifier = identifier
        self.classTable = classTable
        self.isa = isa ?? []
        self.properties = properties ?? [:]
        self.semanticDescription = semanticDescription
    }
    
    private let _parentPropertyCache: NSCache<NSString, NSObject> = NSCache()
    
    func property<T>(for key: String) -> T? where T: NSObject {
        
        if let maybeRet = _parentPropertyCache.object(forKey: key as NSString) {
            guard let ret = maybeRet as? T else {
                DDLogWarn("A key \(key) exists for semantic class \(identifier), but not of type \(T.self)", tag: "AferoAttributeSemanticClass")
                return nil
            }
            return ret
        }
        
        if let ret = properties[key] as? T {
            return ret
        }
        
        for parent in _isa {
            
            if let ret = parent.property(for: key) as? T {
                _parentPropertyCache.setObject(ret, forKey: key as NSString)
                return ret
            }
            
        }
        
        _parentPropertyCache.setObject(NSNull(), forKey: key as NSString)
        return nil

    }
    
    // MARK: <AferoJSONCoding>
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case isa
        case properties
    }
    
    var JSONDict: AferoJSONCodedType? {
        
        let ret: [CodingKeys: Any] = [
            .identifier: identifier,
            .isa: isa,
            .properties: properties,
        ]
        return ret.stringKeyed
    }
    
    required convenience init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            return nil
        }
        
        guard let identifier = jsonDict[CodingKeys.identifier.stringValue] as? String else {
            return nil
        }
        
        self.init(
            identifier: identifier,
            isa: jsonDict[CodingKeys.isa.stringValue] as? [String],
            properties: jsonDict[CodingKeys.properties.stringValue] as? [String: NSObject]
        )
        
    }
    
}

@objc extension AferoAttributeSemanticClassDescriptor {
    
    @nonobjc func builder() -> Builder { return Builder(semanticClass: self) }
    
    class Builder {
        
        private(set) var identifier: String
        private(set) var isa: [String]?
        private(set) var properties: [String: NSObject]?
        private(set) var classTable: AferoSemanticClassReferencing?
        
        init(identifier: String, isa: [String]? = nil, properties: [String: NSObject]? = nil, classTable: AferoSemanticClassReferencing? = nil) {
            self.identifier = identifier
            self.isa = isa
            self.properties = properties
            self.classTable = classTable
        }
        
        convenience init(semanticClass: AferoAttributeSemanticClassDescriptor) {
            self.init(
                identifier: semanticClass.identifier,
                isa: semanticClass.isa,
                properties: semanticClass.properties,
                classTable: semanticClass.classTable
            )
        }
        
        func set(identifier: String) -> Builder {
            self.identifier = identifier
            return self
        }
        
        func set(isa: [String]?) -> Builder {
            self.isa = isa
            return self
        }
        
        func add(isa: String?) -> Builder {
            guard let isa = isa else { return self }
            var newIsa = self.isa ?? []
            newIsa.append(isa)
            self.isa = newIsa
            return self
        }
        
        func set(properties: [String: NSObject]?) -> Builder {
            self.properties = properties
            return self
        }
        
        func set(property: NSObject?, for key: String) -> Builder {
            var newProps = properties ?? [:]
            newProps[key] = property
            self.properties = newProps
            return self
        }
        
        func set(classTable: AferoSemanticClassReferencing?) -> Builder {
            self.classTable = classTable
            return self
        }
        
        func build() -> AferoAttributeSemanticClassDescriptor {
            return AferoAttributeSemanticClassDescriptor(identifier: identifier, isa: isa, properties: properties, classTable: classTable)
        }
        
    }
}

@objc extension AferoAttributeSemanticClassDescriptor: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return builder().build()
    }
}

@objc protocol AferoSemanticValueTransformer: class {
    init?(properties: [String: Any])
}

/// A ValueTransformer that transforms between strings and `Date` objects.
///
/// AferoFixedFormatDateTransformer is used to transform between Afero attribute values
/// specifing a timestamp/date of some kind, and a `Date` object.
/// Format strings are specified using [Unicode Technical Standard #35 v21](http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)

@objcMembers class UTS35DateValueTransformer: ValueTransformer, AferoSemanticValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSDate.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    let dateFormatter: DateFormatter = DateFormatter()
    
    init(dateFormat: String) {
        super.init()
        dateFormatter.dateFormat = dateFormat
    }
    
    required convenience init?(properties: [String : Any]) {
        guard let formatString = properties[SemanticClassPropertyKey.UTS35FormatString] as? String else {
            return nil
        }
        self.init(dateFormat: formatString)
    }
    
    /// Transforms a string representation of an Afero attribute value
    /// to a `Date` as per `dateFormat`, if possible.
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value else { return nil }
        return dateFormatter.date(from: String(describing: value))
    }
    
    /// Transforms a `Date` to its string representation, if possible.
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let date = value as? Date else { return nil }
        return dateFormatter.string(from: date)
    }
    
}

/// A ValueTransformer that transforms between ISO86501 strings and `Date` objects.

@available(iOS, introduced: 10.0)
@objcMembers class ISO8601DateValueTransformer: ValueTransformer, AferoSemanticValueTransformer {
    
    override class func transformedValueClass() -> AnyClass {
        return NSDate.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    let dateFormatter = ISO8601DateFormatter()
    
    init(options: ISO8601DateFormatter.Options = [], timeZone: TimeZone? = nil) {
        dateFormatter.formatOptions = options
        dateFormatter.timeZone = timeZone
        super.init()
    }
    
    required convenience init?(properties: [String : Any]) {
        
        var options: ISO8601DateFormatter.Options = []
        var timeZone: TimeZone? = nil
        
        if let maybeOptions = properties[SemanticClassPropertyKey.ISO8601Options] as? NSNumber {
            options = ISO8601DateFormatter.Options(rawValue: maybeOptions.uintValue)
        } else if let maybeOptions = properties[SemanticClassPropertyKey.ISO8601Options] as? Int {
            options = ISO8601DateFormatter.Options(rawValue: UInt(maybeOptions))
        } else if let maybeOptions = properties[SemanticClassPropertyKey.ISO8601Options] as? UInt {
            options = ISO8601DateFormatter.Options(rawValue: maybeOptions)
        }
        
        if let timeZoneIdentifier = properties[SemanticClassPropertyKey.TimeZoneIdentifer] as? String {
            timeZone = TimeZone(identifier: timeZoneIdentifier)
        } else if let timeZoneAbbreviation = properties[SemanticClassPropertyKey.TimeZoneAbbreviation] as? String {
            timeZone = TimeZone(abbreviation: timeZoneAbbreviation)
        }
        
        self.init(options: options, timeZone: timeZone)
    }
    
    /// Transforms a string representation of an Afero attribute value
    /// to a `Date` as per `dateFormat`, if possible.
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let value = value as? String else { return nil }
        return dateFormatter.date(from: value)
    }
    
    /// Transforms a `Date` to its string representation, if possible.
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let date = value as? Date else { return nil }
        return dateFormatter.string(from: date)
    }
    
}

/// A ValueTransformer that transforms between UNIX epoch time and `Date` objects.
///
/// AferoFixedFormatDateTransformer is used to transform between Afero attribute values
/// specifing a timestamp/date of some kind, and a `Date` object.
/// Format strings are specified using [Unicode Technical Standard #35 v21](http://www.unicode.org/reports/tr35/tr35-31/tr35-dates.html#Date_Format_Patterns)

@objcMembers class UNIXEpochDateValueTransformer: ValueTransformer, AferoSemanticValueTransformer {
    
    let unitsPerSecond: TimeInterval
    
    init(unitsPerSecond: TimeInterval) {
        self.unitsPerSecond = unitsPerSecond
        super.init()
    }
    
    required convenience init?(properties: [String : Any]) {
        
        let unitsPerSecond = ((properties[SemanticClassPropertyKey.UnitsPerSecond] as? NSNumber) ?? NSNumber(value: 1.0))?.doubleValue ?? 0
        
        guard unitsPerSecond > 0 else {
            return nil
        }
        
        self.init(unitsPerSecond: unitsPerSecond)
    }
    
    override convenience init() {
        self.init(unitsPerSecond: 1.0)
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSDate.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    /// Transforms a string representation of an Afero attribute value
    /// to a `Date` as per `dateFormat`, if possible.
    
    override func transformedValue(_ value: Any?) -> Any? {
        
        guard let value = value else { return nil }
        
        let interval: TimeInterval
        
        if let maybeNumber = value as? NSNumber {
            interval = TimeInterval(maybeNumber.int64Value) / unitsPerSecond
        } else if let maybeLong = value as? Int64 {
            interval = TimeInterval(maybeLong) / unitsPerSecond
        } else if let maybeInt = value as? Int {
            interval = TimeInterval(maybeInt) / unitsPerSecond
        } else {
            assert(false, "Expected NSNumber, Int64, or Int value.")
            return nil
        }
        
        let ret = NSDate(timeIntervalSince1970: interval)
        return ret
        
    }
    
    /// Transforms a `Date` to its string representation, if possible.
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let date = value as? NSDate else { return nil }
        return NSNumber(value: date.timeIntervalSince1970 * unitsPerSecond)
    }
    
}

extension AferoAttributeSemanticClassDescriptor {
    
    var valueTransformerName: NSValueTransformerName {
        return NSValueTransformerName(rawValue: identifier + "ValueTransformer")
    }

    var valueTransformer: ValueTransformer? {
        return ValueTransformer(forName: valueTransformerName)
    }
    
    var valueTransformerClass: AnyClass? {
        
        let name = "Afero.\(valueTransformerName.rawValue)"
        if let ret = NSClassFromString(name) {
            return ret
        }
        
        let ret: AnyClass? = _isa
            .compactMap { $0.valueTransformerClass }
            .lazy
            .first

        return ret
    }
    
}

extension AferoSemanticClassReferencing {
    
    func transformer(forSemanticIdentifier semanticIdentifier: String) -> ValueTransformer? {
        guard let semanticClass = self.semanticClass(for: semanticIdentifier) else { return nil }
        return semanticClass.valueTransformer
    }
    
    func semanticValue(forNativeValue nativeValue: Any?, withSemanticClass semanticClass: AferoAttributeSemanticClassDescriptor) -> Any? {
        return semanticClass.valueTransformer?.transformedValue(nativeValue)
    }
    
    func semanticValue(forNativeValue nativeValue: Any?, withSemanticIdentifier semanticIdentifier: String) -> Any? {
        return transformer(forSemanticIdentifier: semanticIdentifier)?.transformedValue(nativeValue)
    }
    
    func nativeValue(forSemanticValue semanticValue: Any?, withSemanticClass semanticClass: AferoAttributeSemanticClassDescriptor) -> Any? {
        return semanticClass.valueTransformer?.reverseTransformedValue(semanticValue)
    }
    
    func nativeValue(forSemanticValue semanticValue: Any?, withSemanticIdentifier semanticIdentifier: String) -> Any? {
        return transformer(forSemanticIdentifier: semanticIdentifier)?.reverseTransformedValue(semanticValue)
    }
    
}

