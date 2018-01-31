//
//  Logging.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 1/17/18.
//

import Foundation
import CocoaLumberjack

@objc protocol AferoLoggingTagged {
    static var AfLogTag: String { get }
    var afLogTag: String { get }
}

extension AferoLoggingTagged {
    
    static func AfLogDebug(_ msg: @autoclosure () -> String) {
        DDLogDebug(msg, tag: AfLogTag)
    }
    
    static func AfLogWarn(_ msg: @autoclosure () -> String) {
        DDLogWarn(msg, tag: AfLogTag)
    }
    
    static func AfLogInfo(_ msg: @autoclosure () -> String) {
        DDLogInfo(msg, tag: AfLogTag)
    }
    
    static func AfLogVerbose(_ msg: @autoclosure () -> String) {
        DDLogVerbose(msg, tag: AfLogTag)
    }
    
    static func AfLogError(_ msg: @autoclosure () -> String) {
        DDLogVerbose(msg, tag: AfLogTag)
    }
    

    func afLogDebug(_ msg: @autoclosure () -> String) {
        DDLogDebug(msg, tag: afLogTag)
    }

    func afLogWarn(_ msg: @autoclosure () -> String) {
        DDLogWarn(msg, tag: afLogTag)
    }
    
    func afLogInfo(_ msg: @autoclosure () -> String) {
        DDLogInfo(msg, tag: afLogTag)
    }
    
    func afLogVerbose(_ msg: @autoclosure () -> String) {
        DDLogVerbose(msg, tag: afLogTag)
    }
    
    func afLogError(_ msg: @autoclosure () -> String) {
        DDLogVerbose(msg, tag: afLogTag)
    }

}

@objc extension NSObject: AferoLoggingTagged {
    static var AfLogTag: String { return "\(self)" }
    var afLogTag: String { return "\(type(of: self).AfLogTag)@\(Unmanaged.passUnretained(self).toOpaque())" }
}
