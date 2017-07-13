//
//  Errors.swift
//  iTokui
//
//  Created by Justin Middleton on 10/27/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation

extension String: Error { }

public extension NSError {
    
    public convenience init(domain: String, code: Int, userInfo: [String: Any]? = nil, localizedDescription: String, underlyingError: NSError? = nil) {
        var localUserInfo: [String: Any] = userInfo ?? [:]
        localUserInfo[NSLocalizedDescriptionKey] = localizedDescription
        if let underlyingError = underlyingError {
            localUserInfo[NSUnderlyingErrorKey] = underlyingError
        }
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    public var underlyingError: NSError? {
        return self.userInfo[NSUnderlyingErrorKey] as? NSError
    }
    
}

public extension Error {
    
    var localizedFailureReason: String? {
        return (self as NSError).localizedFailureReason
    }
}

