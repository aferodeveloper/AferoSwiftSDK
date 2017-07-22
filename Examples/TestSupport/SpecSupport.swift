//
//  SpecSupport.swift
//  iTokui
//
//  Created by Justin Middleton on 5/11/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import XCTest
import Afero
import OHHTTPStubs

import HTTPStatusCodes

extension XCTestCase {

    @available(*, deprecated, message: "Use fixture(named:) throws -> Any? or fixture<T: AferoJSONCoding>(named:) throws -> T? or ResourceUtils.readJson(_:) throws -> Any? instead.")
    func readJson(_ name: String) throws -> Any? {
        return try fixture(named: name)
    }
    
    func fixture(named name: String) throws -> Any? {
        return try ResourceUtils.readJson(named: name, bundle: Bundle(for: self.classForCoder)) as Any?
    }

    func fixture(named name: String) throws -> [String: Any]? {
        guard let ret: Any = try fixture(named: name) else { return nil }
        return ret as? [String: Any]
    }

    func fixture(named name: String) throws -> [[String: Any]]? {
        guard let ret: Any = try fixture(named: name) else { return nil }
        return ret as? [[String: Any]]
    }

    /// Attempt to read JSON from a file named _name_ in the test bundle for the
    /// calling test, and return a thawed instance of the given `AferoJSONCoding`
    /// implementation.
    ///
    /// - parameter name: The name of the JSON fixture to read.
    /// - returns: A thawed `AferoJSONCoding` implementation instance, or nil
    ///            if marshalling failed.
    /// - throws: Any underling I/O errors.
    
    func fixture<T: AferoJSONCoding>(named name: String) throws -> T? {
        do {
            return try T(withJsonNamed: name, inBundleForInstance: self)
        } catch {
            throw error
        }
    }
    
}

extension OHHTTPStubsResponse {
    
    /// Initialize a stub response with any JSONCoding-compliant type.
    /// - parameter object: The object to use for the stub.
    /// - parameter statusCode: The statusCode for the response.
    /// - parameter httpHeaders: The HTTP headers to include with the response.
    
    public convenience init?(object: AferoJSONCoding, statusCode: Int32, headers httpHeaders: [AnyHashable : Any]?) {
        guard let jsonObject = object.JSONDict else { return nil }
        self.init(jsonObject: jsonObject, statusCode: statusCode, headers: httpHeaders)
    }
    
}

typealias AttributeProcessor = (AttributeMap?) -> [String: Any]

typealias AttributeDict = [Int: AttributeValue]

/**
Fixture for testing attribute display rules.
*/

struct AttributeMap: Hashable, SafeSubscriptable, CustomStringConvertible {
    
    var description: String {
        return atts.debugDescription
    }
    
    var hashValue: Int {
        return atts.values.reduce(0) { $0 ^ $1.hashValue}
    }
    
    typealias Key = Int
    typealias Value = AttributeValue
    
    let atts: AttributeDict
    let primary: Int
    
    init(_ attributes: AttributeDict, primary: Int? = nil) {
        atts = attributes
        self.primary = primary ?? 0
    }
    
    subscript(safe key: Int?) -> Value? {
        if let key = key {
            return atts[key]
        }
        let ret = atts[primary]
        return ret
    }
}

func ==(lhs: AttributeMap, rhs: AttributeMap) -> Bool {
    return lhs.atts == rhs.atts && lhs.primary == rhs.primary
}

// MARK: NSError Extensions

extension NSError {

    convenience init(domain: String, code: Int, userInfo: [AnyHashable: Any]? = nil, httpStatusCode: Int?, failingURL: String?, httpURLResponse: HTTPURLResponse?, httpResponseBody: Data?) {
        
        var localUserInfo: [AnyHashable: Any] = [:]
        
        if let httpStatusCode = httpStatusCode {
            localUserInfo["statusCode"] = httpStatusCode
        }
        
        if let failingURL = failingURL {
            localUserInfo[NSURLErrorFailingURLErrorKey] = failingURL
        }
        
        if let httpURLResponse = httpURLResponse {
            localUserInfo["com.alamofire.serialization.response.error.response"] = httpURLResponse
        }
        
        if let httpResponseBody = httpResponseBody {
            localUserInfo["com.alamofire.serialization.response.error.data"] = httpResponseBody
        }
        
        self.init(domain: domain, code: code, userInfo: userInfo)
        
    }
    
    convenience init?(domain: String, code: Int, httpStatusCode: Int?, failingURL: String?, httpURLResponse: HTTPURLResponse?, httpResponseObject: Any) {

        do {
            let data = try JSONSerialization.data(withJSONObject: httpResponseObject, options: [])
            self.init(domain: domain, code: code, httpStatusCode: httpStatusCode, failingURL: failingURL, httpURLResponse: httpURLResponse, httpResponseBody: data)
        } catch {
            NSLog("Unable to encode JSON obj: \(String(reflecting: error))")
            return nil
        }

    }

    convenience init?(domain: String, code: Int, httpStatusCode: Int?, failingURL: String?, httpURLResponse: HTTPURLResponse?, httpResponseObject: AferoJSONCoding) {
        
        guard let jsonDict = httpResponseObject.JSONDict else {
            return nil
        }
        
        self.init(domain: domain, code: code, httpStatusCode: httpStatusCode, failingURL: failingURL, httpURLResponse: httpURLResponse, httpResponseObject: jsonDict)
        
    }
    
}
