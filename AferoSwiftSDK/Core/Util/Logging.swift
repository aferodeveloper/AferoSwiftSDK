//
//  Logging.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 1/17/18.
//

import Foundation
import CocoaLumberjack

@objc protocol AferoLoggingTagged {
    var afLogTag: String { get }
}

extension AferoLoggingTagged {
    
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
    var afLogTag: String { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }
}
