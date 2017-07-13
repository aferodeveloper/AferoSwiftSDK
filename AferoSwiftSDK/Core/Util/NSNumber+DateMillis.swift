//
//  NSNumber+DateMillis.swift
//  Pods
//
//  Created by Justin Middleton on 7/29/16.
//
//

import Foundation

public extension NSNumber {
    
    public var dateValueFromMillisSince1970: Date {
        return Date.dateWithMillisSince1970(self)
    }
}

