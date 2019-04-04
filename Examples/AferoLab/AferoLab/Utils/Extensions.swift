//
//  Extensions.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import HTTPStatusCodes
import CocoaLumberjack
import Afero

extension AFNetworkingAferoAPIClient {
    
    static let DefaultAFNetworkingAPIClientConfig = "APIClientConfig"
    
    static let `default`: AFNetworkingAferoAPIClient = AFNetworkingAferoAPIClient(withPlistNamed: DefaultAFNetworkingAPIClientConfig)
    
}

extension String {
    
    // MARK: Crypto/Hashing
    
    var md5String: String {
        let retData = data(using: .utf8, allowLossyConversion: false)
        let ret = retData!.md5String
        return ret
    }
    
    // MARK: Case and trimming
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var initialLowerCaseString: String {
        let first = prefix(1).lowercased()
        return first + dropFirst()
    }
    
    var initialCapitalizedString: String {
        let first = prefix(1).uppercased()
        return first + dropFirst()
    }
    
    func components(withPrefix prefix: String) -> (prefix: String, remainder: String)? {
        guard let range = range(of: prefix), range.lowerBound == startIndex else {
            return nil
        }
        return (prefix: prefix, remainder: String(self[range.upperBound..<endIndex]))
    }
    
    // MARK: Numeric conversions
    
    public var intValue: Int? {
        if (hasPrefix("0x")) {
            return Int(strtoull(self, nil, 16))
        }
        return Int(self)
    }

    // MARK: URL xforms
    
    public var hostAllowedEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
    }
    
    public var pathAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    }
    
    public var fragmentAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
    }
    
    public var passwordAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlPasswordAllowed)
    }
    
    public var queryAllowedURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
    
    public var alphanumericURLEncodedString: String? {
        return addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }
}

public extension HTTPStatusCode {
    
    var error: Error? {
        if isSuccess || isInformational { return nil }
        return NSError(domain: description, code: rawValue, localizedDescription: localizedReasonPhrase)
    }
    
}

public extension Error {
    
    public var httpResponseBody: Any? {
        return (self as NSError).httpResponseBody
    }
    
    public var httpUrlResponse: Foundation.HTTPURLResponse? {
        return (self as NSError).httpUrlResponse
    }
    
    public var httpStatusCode: Int? {
        return (self as NSError).httpStatusCode
    }
    
    public var failingURL: String? {
        return (self as NSError).failingURL
    }
    
    public var httpStatusCodeValue: HTTPStatusCode? {
        return (self as NSError).httpStatusCodeValue
    }
    
    var localizedFailureReason: String? {
        return (self as NSError).localizedFailureReason
    }
    
}

public extension NSError {
    
    public convenience init(domain: String, code: Int, userInfo: [String: Any]? = nil, localizedDescription: String) {
        var localUserInfo: [String: Any] = userInfo ?? [:]
        localUserInfo[NSLocalizedDescriptionKey] = localizedDescription
        self.init(domain: domain, code: code, userInfo: userInfo)
    }
    
    public var underlyingError: NSError? {
        return self.userInfo[NSUnderlyingErrorKey] as? NSError
    }
    
}

extension NSError {
    
    /**
     The responseObject (body) of the offending request. Will attempt to parse
     into JSON, but will come back as NSData on failure.
     */
    
    public var httpResponseBody: Any? {
        get {
            if let data = userInfo["com.alamofire.serialization.response.error.data"] as? Data {
                do {
                    return try JSONSerialization.jsonObject(with: data, options: [])
                } catch let error as NSError {
                    DDLogError("Unable to parser response body: \(error.localizedDescription)")
                } catch {
                    DDLogError("Unable to parse response body: \(error)")
                }
                return data
            }
            return nil
        }
    }
    
    public var httpUrlResponse: Foundation.HTTPURLResponse? {
        return userInfo["com.alamofire.serialization.response.error.response"] as? Foundation.HTTPURLResponse
    }
    
    public var httpStatusCode: Int? {
        return httpUrlResponse?.statusCode ?? (userInfo["statusCode"] as? Int)
    }
    
    public var failingURL: String? {
        return userInfo[NSURLErrorFailingURLErrorKey] as? String
    }
    
    public var httpStatusCodeValue: HTTPStatusCode? {
        guard let statusCode = httpStatusCode else { return nil }
        return HTTPStatusCode(rawValue: statusCode)
    }
    
}

public extension Dictionary {
    
    mutating func update(_ other: [Key: Value]) -> [Value] {
        return other.compactMap {
            self.updateValue($0.1, forKey: $0.0)
        }
    }
    
}

public extension Array where Element: Hashable {
    
    public func deltasProducing(_ other: [Element]) -> IndexDeltas {
        
        let deletions = NSMutableIndexSet()
        
        let otherSet = Set(other)
        enumerated().forEach {
            idx, elem in
            if !otherSet.contains(elem) {
                deletions.add(idx)
            }
        }
        
        let insertions = NSMutableIndexSet()
        
        let selfSet = Set(self)
        other.enumerated().forEach {
            idx, elem in
            if !selfSet.contains(elem) {
                insertions.add(idx)
            }
        }
        
        return IndexDeltas(deletions: deletions as IndexSet, insertions: insertions as IndexSet)
        
    }
    
}

public struct IndexDeltas {
    public var empty: Bool { return deletions.count == 0 && insertions.count == 0 }
    public var deletions: IndexSet
    public var insertions: IndexSet
}

public extension IndexSet {
    
    public func indexes() -> [Int] { return self.map { $0 } }
    
}

public extension Data {
    
    var prettyJSONValue: String? {
        do {
            let JSON: Any = try JSONSerialization.jsonObject(with: self, options: [])
            do {
                let JSONdata = try JSONSerialization.data(withJSONObject: JSON, options: .prettyPrinted)
                return JSONdata.stringValue
            } catch { }
        } catch { }
        
        return nil
    }
    
}

public extension Data {
    
    public var bytes: [UInt8] {
        var ret = [UInt8](repeating: 0, count: count)
        copyBytes(to: &ret, count: count)
        return ret
    }
    
    public var stringValue: String? {
        return String(data: self, encoding: .utf8)
    }
    
    public var md5String: String {
        return md5().hexEncoded
    }
    
}

public extension Data {
    
    public var hexEncoded: String {
        return bytes.map { String(format: "%02X", $0) }.joined(separator: "")
    }
    
    public init?(hexEncoded: String?) {
        
        guard var localHexEncoded = hexEncoded else { return nil }
        
        if localHexEncoded.count % 2 != 0 {
            localHexEncoded = "0" + localHexEncoded
        }
        
        var byteArray: [UInt8] = []
        
        var startIndex = localHexEncoded.startIndex
        
        while(startIndex < localHexEncoded.endIndex) {
            let endIndex = localHexEncoded.index(startIndex, offsetBy: 2)
            let byteString = String(localHexEncoded[startIndex..<endIndex])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            byteArray.append(num)
            startIndex = endIndex
        }
        
        #if compiler(>=5)
        self.init(byteArray)
        #endif
        #if compiler(<5)
        self.init(bytes: byteArray)
        #endif
    }
    
}

infix operator ∈
infix operator ∉

/// Sequence membership shorthand. Example:
///
/// `if "a" ∈ "Fatty boom boom"

public func ∈<T: Equatable, S: Sequence> (lhs: T?, rhs: S?) -> Bool
    where S.Iterator.Element == T {
        
        guard
            let lhs = lhs,
            let rhs = rhs else {
                return false
        }
        return rhs.contains { $0 == lhs }
}

public func ∉<T: Equatable, S: Sequence> (lhs: T?, rhs: S?) -> Bool
    where S.Iterator.Element == T {
        return !(lhs ∈ rhs)
}

public extension Locale {
    
    public var uses12HrTime: Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: self)!
        
        // "HH" in 24 hr time (en_US)
        // "h a" in 12-hr time (en_US)
        return dateFormat.contains("a")
    }
    
}

public typealias LocalizedTimeComponents = (time: String, period: String, timeZoneAbbreviation: String)

public extension Date {
    
    public var localizedTimeComponents: LocalizedTimeComponents {
        
        var timeFormat = "HH:mm"
        var periodFormat = ""
        
        if Locale.current.uses12HrTime {
            timeFormat = "h:mm"
            periodFormat = "a"
        }
        
        // TODO: Allocating formatters is relatively expensive. Once we find ourselves
        // doing it frequently, we should move these to a registry. It's made trickier
        // by the fact that they're not threadsafe (sad trombone)
        
        let timeFormatter = DateFormatter()
        
        timeFormatter.dateFormat = timeFormat
        let timeString = timeFormatter.string(from: self)
        
        timeFormatter.dateFormat = periodFormat
        let periodString = timeFormatter.string(from: self)
        
        let timeZoneString = Calendar.current.timeZone.abbreviation() ?? ""
        
        return (time: timeString, period: periodString, timeZoneAbbreviation: timeZoneString)
    }
    
    var dayOfYearString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: self)
    }
    
}

public extension TimeZone {
    public static var UTC: TimeZone { return TimeZone(abbreviation: "UTC")! }
}

extension DateComponents {
    
    public var dayOfWeek: DateTypes.DayOfWeek? {
        
        get {
            guard let weekday = weekday else { return nil }
            return DateTypes.DayOfWeek(dayNumber: weekday)
        }
        
        set { weekday = newValue?.dayNumber }
    }
    
    /// Compute a DateComponents object suitable for weekly calculations.
    static func weekly(calendar: Calendar = .autoupdatingCurrent, timeZone: TimeZone? = nil) -> DateComponents {
        let myTimeZone = timeZone ?? calendar.timeZone
        var ret = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .timeZone, .calendar], from: Date())
        ret.calendar = calendar
        ret.hour = 0
        ret.minute = 0
        ret.second = 0
        ret.nanosecond = 0
        ret.dayOfWeek = .sunday
        ret.timeZone = myTimeZone
        return ret
    }
    
    /// Translate the receiver as a "weekly" components instance to a `DateComponents` instance
    /// in a different calendar, optionally with a reference date.
    ///
    /// By default:
    /// * The calendar used will be the calendar associated with the receiver. If not provided,
    ///   it will come from the `to:` param, which defaults to `.autoupdatingCurrent.
    /// * The `referenceDate` used will be the date computed from the receiver using
    ///   the calendar derived above, or the explicitly stated `referenceDate` if nil,
    ///   and finally `Date()` if both of the former are nil.
    /// * `.yearForWeekOfYear` and `.weekOfYear` will be taken from the computed referenceDate.
    /// * `weekday` will default to `1` if nil on the receiver.
    /// * `hour`, `minute`, `second`, and `nanosecond` will default to `0` if nil on the receiver.
    /// * `timeZone` will come from the receiver's `timeZone`, or the computed calendar's `timeZone`.
    ///
    /// - parameter from: The calendar whence to convert, if unspecified by the receiver.
    /// - parameter to: The calendar to which to convert
    /// - parameter with: The reference `Date` to use for the conversion
    
    func translateWeekly(from fromCalendar: Calendar? = nil, to toCalendar: Calendar, with referenceDate: Date = Date()) -> DateComponents? {
        
        let localFromCalendar = calendar ?? fromCalendar ?? Calendar.autoupdatingCurrent
        let localReferenceDate = localFromCalendar.date(from: self) ?? referenceDate
        
        var nowComponents = localFromCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear,], from: localReferenceDate)
        
        nowComponents.year              = nil
        nowComponents.yearForWeekOfYear = yearForWeekOfYear ?? nowComponents.yearForWeekOfYear
        nowComponents.weekOfYear        = weekOfYear ?? nowComponents.weekOfYear
        nowComponents.weekday           = weekday ?? 1
        nowComponents.hour              = hour ?? 0
        nowComponents.minute            = minute ?? 0
        nowComponents.second            = second ?? 0
        nowComponents.nanosecond        = nanosecond ?? 0
        nowComponents.calendar          = localFromCalendar
        nowComponents.timeZone          = timeZone ?? localFromCalendar.timeZone
        
        guard let toDate = toCalendar.date(from: nowComponents) else {
            print("Unable to translate \(self) from \(localFromCalendar) to \(toCalendar): returned date is nil")
            return nil
        }
        
        var ret = toCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday, .hour, .minute, .second, .nanosecond, .timeZone], from: toDate)
        ret.calendar = toCalendar
        
        return ret
    }
    
    func translateWeekly(from fromTimeZone: TimeZone = TimeZone(abbreviation: "UTC")!, to toTimeZone: TimeZone = .autoupdatingCurrent, with referenceDate: Date = Date()) -> DateComponents? {
        
        var fromCalendar = calendar ?? .autoupdatingCurrent
        let fromTimeZone = timeZone ?? calendar?.timeZone ?? fromTimeZone
        fromCalendar.timeZone = fromTimeZone
        
        var toCalendar = Calendar.autoupdatingCurrent
        toCalendar.timeZone = toTimeZone
        
        return translateWeekly(from: fromCalendar, to: toCalendar, with: referenceDate)
    }
}

public extension Timer {
    
    //    // Usage:
    //    var count = 0
    //    NSTimer.schedule(repeatInterval: 1) { timer in
    //    println(++count)
    //    if count >= 10 {
    //    timer.invalidate()
    //    }
    //    }
    //
    //    NSTimer.schedule(delay: 5) { timer in
    //    println("5 seconds")
    //    }
    
    /**
     Brazenly lifted from https://gist.github.com/natecook1000/b0285b518576b22c4dc8.
     Creates and schedules a one-time `NSTimer` instance.
     
     - parameter delay: The delay before execution.
     - parameter handler: A closure to execute after `delay`.
     
     - returns: The newly-created `NSTimer` instance.
     */
    public class func schedule(_ delay: TimeInterval, handler: @escaping (Timer?) -> Void) -> Timer? {
        let fireDate = delay + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, 0, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
        return timer
    }
    
    /**
     Brazenly lifted from https://gist.github.com/natecook1000/b0285b518576b22c4dc8.
     Creates and schedules a repeating `NSTimer` instance.
     
     - parameter repeatInterval: The interval between each execution of `handler`. Note that individual calls may be delayed; subsequent calls to `handler` will be based on the time the `NSTimer` was created.
     - parameter handler: A closure to execute after `delay`.
     
     - returns: The newly-created `NSTimer` instance.
     */
    public class func schedule(repeatInterval interval: TimeInterval, handler: @escaping (Timer?) -> Void) -> Timer? {
        let fireDate = interval + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, interval, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
        return timer
    }
    
}

extension ClosedRange {
    
    func clamp(value : Bound) -> Bound {
        return lowerBound > value ? lowerBound
            : upperBound < value ? upperBound
            : value
    }
}

extension CountableClosedRange {
    
    func clamp(value : Bound) -> Bound {
        return lowerBound > value ? lowerBound
            : upperBound < value ? upperBound
            : value
    }
}
