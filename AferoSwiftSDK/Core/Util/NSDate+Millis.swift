//
//  NSDate+Millis.swift
//  Pods
//
//  Created by Justin Middleton on 7/27/16.
//
//

import Foundation

public extension Date {
    
    static func dateWithMillisSince1970(_ millis: NSNumber) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(millis.int64Value / 1000))
    }
    
    var millisSince1970: NSNumber {
        let interval = timeIntervalSince1970
        let wholeValue = Int64(interval)
        let fracValue = interval - Float64(wholeValue)
        return NSNumber(value: (wholeValue * 1000) + Int64(fracValue * 1000) as Int64)
    }
    
}
