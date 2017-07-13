//: Playground - noun: a place where people can play

import UIKit

// UTC to local

// Create date from components: weekday = 2 (Tuesday), hour = 4, minute = 20

var utcCalendar = Calendar.autoupdatingCurrent
utcCalendar.timeZone = TimeZone(abbreviation: "UTC")!
let utcFormatter = ISO8601DateFormatter()

var localCalendar = Calendar.autoupdatingCurrent
localCalendar.timeZone = TimeZone.autoupdatingCurrent
var localFormatter = DateFormatter()
localFormatter.locale = Locale(identifier: "en_US_POSIX")
localFormatter.dateStyle = .full


var jstCalendar = Calendar.autoupdatingCurrent
jstCalendar.timeZone = TimeZone(abbreviation: "JST")!
var jstFormatter = DateFormatter()
jstFormatter.locale = Locale(identifier: "ja_JP_POSIX")
jstFormatter.dateStyle = .full

extension DateComponents {
    
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
        
        let ret = toCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday, .hour, .minute, .second, .nanosecond, .timeZone], from: toDate)
        
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


let nowComponents = utcCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear,], from: Date())

var mondayComponents = nowComponents
mondayComponents.weekday = 2
mondayComponents.hour = 4
mondayComponents.minute = 20
mondayComponents.calendar = utcCalendar

mondayComponents.translateWeekly(to: TimeZone(abbreviation: "JST")!)?.translateWeekly(to: TimeZone.autoupdatingCurrent)



let mondayDate = utcCalendar.date(from: mondayComponents)!
let localComponents = localCalendar.dateComponents([.weekday], from: mondayDate)

utcFormatter.string(from: mondayDate)

let mondayLocalDate = localCalendar.date(from: mondayComponents)!
localFormatter.string(from: mondayLocalDate)


var lateComponents = DateComponents(calendar: utcCalendar, hour: 04, minute: 20, weekday: 3)
lateComponents.year = nowComponents.year
lateComponents.month = nowComponents.month
lateComponents.day = nowComponents.day

//typealias WeekdayHourMinuteSecond = (weekday: Int, hour: Int, minute: Int, second: Int, nanosecond: Int)
//
//func translate(weekday: Int, hour: Int = 0, minute: Int = 0, second: Int = 0, from fromTimeZone: TimeZone = TimeZone(abbreviation: "UTC")!, to toTimeZone: TimeZone = TimeZone.autoupdatingCurrent) -> WeekdayHourMinuteSecond {
//    
//    var fromCalendar = Calendar.autoupdatingCurrent
//    fromCalendar.timeZone = fromTimeZone
//    
//    var toCalendar = Calendar.autoupdatingCurrent
//    toCalendar.timeZone = toTimeZone
//    
//    return translate(weekday: weekday, hour: hour, minute: minute, second: second, from: fromCalendar, to: toCalendar)
//}
//
//func translate(weekday: Int, hour: Int = 0, minute: Int = 0, second: Int = 0, from fromCalendar: Calendar, to toCalendar: Calendar) -> WeekdayHourMinuteSecond {
//
//    var components = fromCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear,], from: Date())
//    components.weekday = weekday
//    components.hour = hour
//    components.minute = minute
//    components.second = second
//    components.timeZone = fromCalendar.timeZone
//
//    let toDate = toCalendar.date(from: components)
//    let ret = toCalendar.dateComponents([.weekday], from: toDate!)
//    return ret.weekday!
//}



/// Traveling from Japan to Greenwich, a Sunday at 2am JST is a Saturday




//weekdayFor(weekday: 1, hour: 2, minute: 3, second: 4, from: TimeZone(abbreviation: "JST")!, to: TimeZone(abbreviation: "UTC")!)

//let lateDate = utcCalendar.utcCalendar.date(from: lateComponents)
//let latedc = utcCalendar.dateCom

// First get common year components

//let nowDate = Date()
//let nowComponents = utcCalendar.dateComponents([.year, .month, .day, .hour, .minute, .timeZone], from: nowDate)
//
//var yesterdayComponents = nowComponents
//yesterdayComponents
//
//
//
//var pstCalendar = Calendar.autoupdatingCurrent
//pstCalendar.timeZone = TimeZone.autoupdatingCurrent
//

