//
//  AferoLogFormatter.swift
//  Pods
//
//  Created by Justin Middleton on 7/28/16.
//
//

import Foundation
import CocoaLumberjack

open class AferoADBLogFormatter: NSObject, DDLogFormatter {
    
    lazy fileprivate var dateFormatter: DateFormatter = {
        let ret = DateFormatter()
        ret.dateFormat = "yyyy-MM-dd HH:mm:ss:SSSZ"
        return ret
    }()
    
    open func priorityForLogFlag(_ flag: DDLogFlag) -> String {
        switch flag {
        case DDLogFlag.error :    return "E"
        case DDLogFlag.warning :  return "W"
        case DDLogFlag.info :     return "I"
        case DDLogFlag.verbose :  return "V"
        case DDLogFlag.debug :    return "D"
        default:                  return "<unknown>"
        }
    }
    
    @objc open func format(message: DDLogMessage) -> String? {
        
        let levelString: String
        
        switch message.flag {
        case DDLogFlag.error   : levelString = "E"
        case DDLogFlag.warning : levelString = "W"
        case DDLogFlag.info    : levelString = "I"
        case DDLogFlag.verbose : levelString = "V"
        case DDLogFlag.debug   : levelString = "D"
        default                : levelString = "<unknown>"
        }
        
        let queueLabel = message.queueLabel
        let fileName   = message.fileName
        let function   = message.function ?? "_"
        let line       = message.line
        
        let tag        = (message.tag as? String) ?? "_"
        let msg        = message.message
        
        return "\(queueLabel)/\(fileName):\(function):\(line) \(levelString)/\(tag): \(msg)"
    }
    
}

/// Formats log messages in an ADB-like fashion, omitting timestamps (they're added by ASL).

open class AferoASLADBLogFormatter: AferoADBLogFormatter { }

/// Formats log messages in an ADB-like fashion, with timestamps prepended.

open class AferoTTYADBLogFormatter: AferoADBLogFormatter {
    
    @objc override open func format(message: DDLogMessage) -> String {
        let dateString = dateFormatter.string(from: message.timestamp)
        let messageString: String = super.format(message: message) ?? "<none>"
        return "\(dateString) \(messageString)"
    }
    
}
