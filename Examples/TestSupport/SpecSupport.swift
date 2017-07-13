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

import HTTPStatusCodes

extension XCTestCase {

    func readJson(_ file: String) throws -> AnyObject? {
        return try ResourceUtils.readJson(file, bundle: Bundle(for: self.classForCoder)) as AnyObject?
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
