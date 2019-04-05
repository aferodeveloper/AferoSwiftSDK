//
//  Extensions.swift
//  iTokui
//
//  Created by Steve Hales on 11/15/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import CocoaLumberjack
import HTTPStatusCodes
import CryptoSwift

public extension HTTPStatusCode {
    
    var error: Error? {
        if isSuccess || isInformational { return nil }
        return NSError(domain: description, code: rawValue, localizedDescription: localizedReasonPhrase)
    }
    
}

public extension Error {

 var httpResponseBody: Any? {
        return (self as NSError).httpResponseBody
    }
    
 var httpUrlResponse: Foundation.HTTPURLResponse? {
        return (self as NSError).httpUrlResponse
    }
    
 var httpStatusCode: Int? {
        return (self as NSError).httpStatusCode
    }
    
 var failingURL: String? {
        return (self as NSError).failingURL
    }
    
 var httpStatusCodeValue: HTTPStatusCode? {
        return (self as NSError).httpStatusCodeValue
    }
}

public extension NSError {
    
    /**
     The responseObject (body) of the offending request. Will attempt to parse
     into JSON, but will come back as NSData on failure.
     */
    
 var httpResponseBody: Any? {
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
    
 var httpUrlResponse: Foundation.HTTPURLResponse? {
        return userInfo["com.alamofire.serialization.response.error.response"] as? Foundation.HTTPURLResponse
    }
    
 var httpStatusCode: Int? {
        return httpUrlResponse?.statusCode ?? (userInfo["statusCode"] as? Int)
    }
    
 var failingURL: String? {
        return userInfo[NSURLErrorFailingURLErrorKey] as? String
    }
    
 var httpStatusCodeValue: HTTPStatusCode? {
        guard let statusCode = httpStatusCode else { return nil }
        return HTTPStatusCode(rawValue: statusCode)
    }
    
}

public extension Locale {
    
 var uses12HrTime: Bool {
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: self)!
        
        // "HH" in 24 hr time (en_US)
        // "h a" in 12-hr time (en_US)
        return dateFormat.contains("a")
    }
    
}

public typealias LocalizedTimeComponents = (time: String, period: String, timeZoneAbbreviation: String)

public extension Date {
    
 var localizedTimeComponents: LocalizedTimeComponents {
        
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
 static var UTC: TimeZone { return TimeZone(abbreviation: "UTC")! }
}

extension DateComponents {

    public var dayOfWeek: DateTypes.DayOfWeek? {
        
        get {
            guard let weekday = weekday else { return nil }
            return DateTypes.DayOfWeek(dayNumber: weekday)
        }
        
        set { weekday = newValue?.dayNumber }
    }
    
    /// Compute a DateComponents object suitable for daily (hh:mm:ss) calculations.
    /// - parameter calendar: The calendar to use. Defaults to `.autoupdatingCurrent`.
    /// - parameter timeZone: The timeZone to use; if present, overrides any timeZone in `calendar`. Defaults to `nil`.
    /// - parameter dayOfWeek: The `DateTypes.DayOfWeek` to use. Defaults to `.sunday`.
    /// - parameter hour: The hour to use. Defaults to `0`.
    /// - parameter minute: The minute to use. Defaults to `0`.
    /// - parameter second: The second to use. Defaults to `0`.
    /// - parameter nanosecond: The nanosecond to use. Defaults to `0`.
    
    public static func daily(calendar: Calendar? = nil, timeZone: TimeZone? = nil, hour: Int = 0, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) -> DateComponents {
        
        let myCalendar = calendar ?? .current
        var ret = myCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .timeZone, .calendar], from: Date())
        
        let myTimeZone = timeZone ?? myCalendar.timeZone
        
        ret.calendar = myCalendar
        ret.timeZone = myTimeZone
        
        ret.hour = hour
        ret.minute = minute
        ret.second = second
        ret.nanosecond = nanosecond
        
        return ret
    }
    
    
    /// Compute a DateComponents object suitable for weekly calculations.
    /// - parameter calendar: The calendar to use. Defaults to `.autoupdatingCurrent`.
    /// - parameter timeZone: The timeZone to use; if present, overrides any timeZone in `calendar`. Defaults to `nil`.
    /// - parameter dayOfWeek: The `DateTypes.DayOfWeek` to use. Defaults to `.sunday`.
    /// - parameter hour: The hour to use. Defaults to `0`.
    /// - parameter minute: The minute to use. Defaults to `0`.
    /// - parameter second: The second to use. Defaults to `0`.
    /// - parameter nanosecond: The nanosecond to use. Defaults to `0`.
    
    public static func weekly(calendar: Calendar? = nil, timeZone: TimeZone? = nil, dayOfWeek: DateTypes.DayOfWeek = .sunday, hour: Int = 0, minute: Int = 0, second: Int = 0, nanosecond: Int = 0) -> DateComponents {
        
        let myCalendar = calendar ?? .current
        var ret = myCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .timeZone, .calendar], from: Date())
        
        let myTimeZone = timeZone ?? myCalendar.timeZone
        
        ret.timeZone = myTimeZone
        
        ret.dayOfWeek = dayOfWeek
        ret.hour = hour
        ret.minute = minute
        ret.second = second
        ret.nanosecond = nanosecond
        
        return ret
    }


}

public extension Date {
    
 static func from(iso8601String: String?) -> Date? {
        guard let iso8601String = iso8601String else { return nil }
        return DateFormatter.ISO8601Formatter.date(from: iso8601String)
    }
    
 var iso8601String: String {
        return DateFormatter.ISO8601Formatter.string(from: self)
    }
    
}

public protocol DateFormatting {
    func string(from date: Date) -> String
    func date(from: String) -> Date?
}

extension DateFormatter: DateFormatting { }

@available(iOS 10.0, macOS 10.12, *)
extension ISO8601DateFormatter: DateFormatting { }

public extension DateFormatter {

    /// iOS 9 Backward-compatible getter for a formatter
    /// that will handle ISO8601 encoding/decoding
    
 static var ISO8601Formatter: DateFormatting {

        if #available(iOS 10, macOS 10.12, *) {
            return ISO8601DateFormatter()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            return formatter
        }
    }
    
    static var weekdayFormatter: DateFormatter {
        let ret = DateFormatter()
        ret.locale = .autoupdatingCurrent
        ret.calendar = .autoupdatingCurrent
        return ret
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
 class func schedule(_ delay: TimeInterval, handler: @escaping (Timer?) -> Void) -> Timer? {
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
 class func schedule(repeatInterval interval: TimeInterval, handler: @escaping (Timer?) -> Void) -> Timer? {
        let fireDate = interval + CFAbsoluteTimeGetCurrent()
        let timer = CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, fireDate, interval, 0, 0, handler)
        CFRunLoopAddTimer(CFRunLoopGetCurrent(), timer, CFRunLoopMode.commonModes)
        return timer
    }
    
}

extension String {
    
    var intValue: Int? {
        if (hasPrefix("0x")) {
            return Int(strtoull(self, nil, 16))
        }
        return Int(self)
    }
    
}

// Lifted from http://airspeedvelocity.net/2014/07/18/on-dictionaries-and-initializers/

extension Dictionary {
    
    init(_ array: [Element]?) {
        var d: [Key:Value] = [:]
        if let array = array {
            for pair in array {
                d.updateValue(pair.1, forKey: pair.0)
            }
        }
        self = d
    }
    
    init<S: Sequence>(_ seq: S) where S.Iterator.Element == Element {
        self.init()
        for (k, v) in seq {
            self.updateValue(v, forKey: k)
        }
    }
    
    init<S: Sequence>(_ seq: S, xform: (S.Iterator.Element) -> (Element?)) {
        self.init()
        for elem in seq {
            if let (k, v) = xform(elem) {
                self.updateValue(v, forKey: k)
            }
        }
    }
}


extension Dictionary {
    
    mutating func update(_ other: [Key: Value]) -> [Value] {
        return other.map {
            return self.updateValue($0.1, forKey: $0.0)
            }.filter { $0 != nil }.map { $0! }
    }
    
}


extension Array {
    
    subscript(safe index: UInt?) -> Element? {
        if let index = index {
            return Int(index) >= 0 ? self[Int(index)] : nil
        }
        return nil
    }
    
    subscript(safe index: Int?) -> Element? {
        if let index = index {
            if (0 <= index) && (index < count) {
                return self[index]
            }
        }
        return nil
    }
}

//
//public extension Array {
//    
//    public func idx(_ prop: Float) -> Int {
//        return Int(round(Float(self.count - 1) * prop.clamp(0.0, max: 1.0)))
//    }
//    
//    /// Index an array by a Float representing the "proportion" of the array, such that
//    /// `0.0` maps to `self[0]`, and `1.0` maps to `self[count - 1]`. Indexes will be clamped
//    /// to `0.0 ≤ i ≤ 1.0`.
//    
//    subscript(prop: Float) -> Element? {
//        get {
//            if count == 0 { return nil }
//            return self[idx(prop)]
//        }
//        set {
//            guard let newValue = newValue else { return }
//            self[idx(prop)] = newValue
//        }
//    }
//    
//    public func proportion(_ predicate: (Element) throws -> Bool) -> Float? {
//        
//        guard let idx = try? self.index(where: predicate) else { return nil }
//        
//        let denom = count - 1
//        if denom == 0 { return 0.0 }
//        
//        return Float(idx ?? 0) / Float(denom)
//    }
//    
//}

public struct ArrayDeltas {
    public var empty: Bool { return deletions.count == 0 && insertions.count == 0 }
    public var deletions: IndexSet
    public var insertions: IndexSet
}

public extension Array where Element: Hashable {
    
 func deltasToProduce(_ other: [Element]) -> ArrayDeltas {
        
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
        
        return ArrayDeltas(deletions: deletions as IndexSet, insertions: insertions as IndexSet)
        
    }
    
}

public extension IndexSet {
    
 func indexes() -> [Int] {
        var ret: [Int] = [];
        self.forEach { ret.append($0) }
        return ret;
    }
    
}

extension DispatchTime {
    static let zero = DispatchTime(uptimeNanoseconds: 0)
}

// MARK: - ByteArray handling

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

 var stringValue: String? {
        return String(data: self, encoding: .utf8)
    }
    
 var md5String: String {
        return md5().hexEncoded
    }
    
}

public extension Data {

 var hexEncoded: String {
        return bytes.map { String(format: "%02X", $0) }.joined(separator: "")
    }
    
 init?(hexEncoded: String?) {
        
        guard var localHexEncoded = hexEncoded else { return nil }
        
        if localHexEncoded.count % 2 != 0 {
            localHexEncoded = "0" + localHexEncoded
        }
        
        var byteArray: [UInt8] = []
        
        var startIndex = localHexEncoded.startIndex
        
        while(startIndex < localHexEncoded.endIndex) {
            let endIndex = localHexEncoded.index(startIndex, offsetBy: 2)
            let byteString = localHexEncoded[startIndex..<endIndex]
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            byteArray.append(num)
            startIndex = endIndex
        }

    #if compiler(<5)
        self.init(bytes: byteArray)
    #endif
    #if compiler(>=5)
        self.init(byteArray)
    #endif
    }
    
}

public protocol DataConvertible {
    init?(data: Data?)
    var data: Data { get }
}

public extension DataConvertible {
    
 init?(data: Data?) {

    guard let data = data else { return nil }
    guard data.count == MemoryLayout<Self>.size else { return nil }

    #if compiler(<5)
        self = data.withUnsafeBytes { $0.pointee }
    #endif
    
    #if compiler(>=5)
    self = data.withUnsafeBytes { bytes in
        let buffer: UnsafePointer<Self> = bytes.baseAddress!.assumingMemoryBound(to: Self.self)
        return buffer.pointee
    }
    #endif
    }
    
 var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

 init?(byteArray: ArraySlice<UInt8>) {
        self.init(byteArray: Array(byteArray))
    }
    
 init?(byteArray: [UInt8]) {
    #if compiler(<5)
    self.init(data: Data(bytes: byteArray))
    #endif
    
    #if compiler(>=5)
    self.init(data: Data(byteArray))
    #endif
    }
    
 var bytes: [UInt8] {
        return data.bytes
    }
    
}

public extension DataConvertible {
    
 init?(hexEncoded: String) {
        self.init(data: Data(hexEncoded: hexEncoded))
    }
    
 var hexEncoded: String {
        return data.hexEncoded
    }
    
}

extension Bool: DataConvertible { }

extension Int: DataConvertible { }
extension Int8: DataConvertible { }
extension Int16: DataConvertible { }
extension Int32: DataConvertible { }
extension Int64: DataConvertible { }
extension UInt: DataConvertible { }
extension UInt8: DataConvertible { }
extension UInt16: DataConvertible { }
extension UInt32: DataConvertible { }
extension UInt64: DataConvertible { }

extension Float32: DataConvertible { }
extension Float64: DataConvertible { }

#if targetEnvironment(simulator)
extension Float80: DataConvertible { }
#endif

extension String: DataConvertible {
    
    public init?(data: Data?) {
        guard let data = data else { return nil }
        self.init(data: data, encoding: .utf8)
    }
    
    public var data: Data {
        return self.data(using: .utf8)!
    }
    
}

public extension CharacterSet {
    
 static var hexadecimalCharacters: CharacterSet {
        return CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
    }
    
}

public extension String {
    
 var characterSet: CharacterSet {
        return CharacterSet(charactersIn: self)
    }
}


extension UIViewController {
    public var titleImage: UIImage? {
        get { return (navigationItem.titleView as? UIImageView)?.image }
        set {
            guard let newValue = newValue else {
                navigationItem.titleView = nil
                return
            }
            navigationItem.titleView = UIImageView(image: newValue)
        }
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

/// Append `lhs` to `rhs` in-place.
/// - parameter lhs: A collection of `T`s which will receive the new element.
/// - parameter rhs: An element to append to `lhs`
public func <<<C: RangeReplaceableCollection, T>(lhs: inout C, rhs: T)
    where C.Iterator.Element == T {
    lhs.append(rhs)
}

/// Append the contents of `lhs` to `rhs` in-place.
/// - parameter lhs: A collection of `T`s which will receive the new elements.
/// - parameter lhs: A sequence of `T`s whose contents will be appended to `lhs`
public func <<<C: RangeReplaceableCollection, T: Sequence>(lhs: inout C, rhs: T)
    where C.Iterator.Element == T.Iterator.Element {
    lhs.append(contentsOf: rhs)
}

/// Append `lhs` to `rhs` in-place.
/// - parameter lhs: An element to append to `rhs`
/// - parameter rhs: A collection of `T`s which will receive the new element.
public func >><C: RangeReplaceableCollection, T>(lhs: T, rhs: inout C)
    where C.Iterator.Element == T {
    rhs.append(lhs)
}

/// Append the contents of `lhs` to `rhs` in-place.
/// - parameter lhs: A sequence of `T`s whose contents will be appended to `rhs`
/// - parameter rhs: A collection of `T`s which will receive the new elements.
public func >><C: RangeReplaceableCollection, T: Sequence>(lhs: T, rhs: inout C)
    where C.Iterator.Element == T.Iterator.Element {
    rhs.append(contentsOf: lhs)
}


