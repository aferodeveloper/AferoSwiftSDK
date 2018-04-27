//
//  SemanticClass.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 4/26/18.
//

import Foundation
import CocoaLumberjack

@objc protocol AferoSemanticClassReferencing: class, NSObjectProtocol {
    func semanticClass(for identifier: String) -> AferoAttributeSemanticClass?
}

infix operator <<-:  AdditionPrecedence
infix operator ← :  AdditionPrecedence

enum AferoSemanticClassError: LocalizedError, CustomNSError, Equatable {
    
    case unrecognizedSemanticClass(String)

    // MARK: <LocalizedError>
    
    var errorDescription: String? {
        switch self {
        case .unrecognizedSemanticClass(let name): return "\(type(of: self)).Unrecognized semantic class: '\(name)'"
        }
    }
    
    // MARK: <CustomNSError>
    
    var errorCode: Int {
        switch self {
        case .unrecognizedSemanticClass: return -1
        }
    }
    
    var errorUserInfo: [String : Any] {
        switch self {
        case .unrecognizedSemanticClass(let name): return ["name": name]
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
        }
    }
    
}

@objcMembers class AferoSemanticClassTable: NSObject, AferoSemanticClassReferencing {
    
    private var identifierToClassMap: [String: AferoAttributeSemanticClass] =  [:]
    
    @discardableResult
    func register(semanticClass: AferoAttributeSemanticClass) throws -> AferoSemanticClassTable {
        
        try semanticClass.isa.forEach {
            guard identifierToClassMap[$0] != nil else {
                throw AferoSemanticClassError.unrecognizedSemanticClass($0)
            }
        }
        
        identifierToClassMap[semanticClass.identifier] = semanticClass.builder()
            .set(classTable: self)
            .build()
        
        return self
    }
    
    @discardableResult
    static func <<- (lhs: AferoSemanticClassTable, rhs: AferoAttributeSemanticClass) throws -> AferoSemanticClassTable {
        return try lhs.register(semanticClass: rhs)
    }

    @discardableResult
    static func ← (lhs: AferoSemanticClassTable, rhs: AferoAttributeSemanticClass) throws -> AferoSemanticClassTable {
        return try lhs <<- rhs
    }

    var semanticClasses: LazyMapCollection<[String : AferoAttributeSemanticClass], AferoAttributeSemanticClass> {
        let ret = identifierToClassMap.values.lazy
        return ret
    }
    
    // MARK: <AferoSemanticClassReferencing>
    
    func semanticClass(for identifier: String) -> AferoAttributeSemanticClass? {
        return identifierToClassMap[identifier]
    }
    
}

/// Represents properties for a semantic claass representation, and provides a property
/// inheritance mechanism.

@objcMembers class AferoAttributeSemanticClass: NSObject, AferoJSONCoding {
    
    public let identifier: String
    public let isa: [String]
    
    lazy private var _isa: [AferoAttributeSemanticClass] = {
        return self.isa.compactMap { self.classTable?.semanticClass(for: $0) }
    }()
    
    let properties: [String: NSObject]
    
    weak var classTable: AferoSemanticClassReferencing?
    
    init(identifier: String, isa: [String]? = nil, properties: [String: NSObject]? = nil, classTable: AferoSemanticClassReferencing? = nil) {
        self.identifier = identifier
        self.classTable = classTable
        self.isa = isa ?? []
        self.properties = properties ?? [:]
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

@objc extension AferoAttributeSemanticClass {
    
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
        
        convenience init(semanticClass: AferoAttributeSemanticClass) {
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
        
        func build() -> AferoAttributeSemanticClass {
            return AferoAttributeSemanticClass(identifier: identifier, isa: isa, properties: properties, classTable: classTable)
        }
        
    }
}

@objc extension AferoAttributeSemanticClass: NSCopying {
    
    func copy(with zone: NSZone? = nil) -> Any {
        return builder().build()
    }
}
