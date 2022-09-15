//
//  OfflineScheduleTests.swift
//  iTokui
//
//  Created by Justin Middleton on 9/30/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero

/// Test for offline schedules as handled by afRAC. For more info,
/// see the [spec](http://wiki.afero.io/display/FIR/AfRac+Offline+Schedule+Design)

class OfflineScheduleSpec: QuickSpec {
    
    /* From the spec:
     
     # Offline Schedule Event
     
     The offline schedule event is a formatted byte array. The array contains a
     time specification followed by a list of attribute value specifications.
     Byte order for all multi-byte values is little-endian.
     
     ** Time Specification **
     
     Name          | Data Type          | Description
     ======================================================================================
     flags         | uint8_t            | 2<<0: repeats
     day of week   | uint8_t            | Day of the week where 0 = Monday and Sunday = 7.
     hour          | uint8_t            | Hour of the day that the event should occur on.
     minute        | uint8_t	            | Minute of the day that the event should occur on.

      */
    
    typealias DayOfWeek = OfflineSchedule.ScheduleEvent.TimeSpecification.DayOfWeek
    
    override func spec() {
        
        /*
         
         * midnight UTC -> UTC-1, should go back a day
         * 23:00 UTC -> UTC+1, should go forward a day
         * in all cases, should wrap around.
         
         */
        
        // UTC+1 (e.g. CET)
        let utcPlus1 = TimeZone(secondsFromGMT: 3600)!
        
        // UTC-1 (e.g. Azores)
        let utcMinus1 = TimeZone(secondsFromGMT: -3600)!
        
        // MARK: - Days of the Week -
        
        describe("When handling days of week") {
        
            // MARK: • Should have expected rawValues
            
            it("should have expected rawValues for days of week.") {
                expect(DayOfWeek.sunday.dayNumber) == 1
                expect(DayOfWeek.monday.dayNumber) == 2
                expect(DayOfWeek.tuesday.dayNumber) == 3
                expect(DayOfWeek.wednesday.dayNumber) == 4
                expect(DayOfWeek.thursday.dayNumber) == 5
                expect(DayOfWeek.friday.dayNumber) == 6
                expect(DayOfWeek.saturday.dayNumber) == 7
            }
        }
        
        // MARK: - Time specification flags -
    
        describe("when handling time specification flags") {
            
            // MARK: • Should encode repeats properly.
            
            it("should encode repeats properly") {

                let flagsNoRepeats = OfflineSchedule.ScheduleEvent.TimeSpecification.Flags(rawValue: 0)
                expect(flagsNoRepeats.contains(.repeats)).to(beFalse())
                expect(flagsNoRepeats.bytes) == [0x00]
                expect(flagsNoRepeats) == OfflineSchedule.ScheduleEvent.TimeSpecification.Flags.none
                
                let flagsNoRepeats2 = OfflineSchedule.ScheduleEvent.TimeSpecification.Flags.none
                expect(flagsNoRepeats2.contains(.repeats)).to(beFalse())
                expect(flagsNoRepeats2.bytes) == [0x00]

                let flagsRepeats = OfflineSchedule.ScheduleEvent.TimeSpecification.Flags(rawValue: 1)
                expect(flagsRepeats.contains(.repeats)).to(beTrue())
                expect(flagsRepeats.bytes) == [0x01]
                expect(flagsRepeats) == OfflineSchedule.ScheduleEvent.TimeSpecification.Flags.repeats

            }
            
        }
        
        // MARK: - Time specifications -
        
        describe("when handling time specifications") {
        
            // MARK: • Should initialize to expected defaults
            
            it("should initialize to expected defaults") {
                
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification()
                
                expect(schedule.repeats) == false
                expect(schedule.dayOfWeek) == DayOfWeek.sunday
                expect(schedule.hour) == 0
                expect(schedule.minute) == 0
                
            }
            
            
            it("should initialize to expected defaults for compact day format") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(daysOfWeek: [], hour: 12, minute: 35)
                expect(schedule.useCompactDayRepresentation) == false
                expect(schedule.repeats) == false
                expect(schedule.daysOfWeek) == []
                expect(schedule.hour) == 12
                expect(schedule.minute) == 35
            }
            
            it("should initialize to expected defaults") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(daysOfWeek: [.saturday, .tuesday], hour: 12, minute: 35)
                expect(schedule.useCompactDayRepresentation) == true
                expect(schedule.daysOfWeek) == [.saturday, .tuesday] // gives just first value
                expect(schedule.repeats) == false
                expect(schedule.hour) == 12
                expect(schedule.minute) == 35
            }
            
            
            it("should encode compact day representation") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(daysOfWeek: [.saturday, .tuesday], hour: 12, minute: 35)
                
                let encoded1 = schedule.bytes

                expect(encoded1[0]) == 2 // flags is [0x00, 0x00]
                expect(schedule.repeats).to(beFalse())
                expect(schedule.usesDeviceTimeZone).to(beTrue())
                
                expect(encoded1[1]) == UInt8(145) // 10010001
                expect(encoded1[2]) == 12 // hour
                expect(encoded1[3]) == 35 // min
            }
            
            it("should encode compact day representation repeating") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(daysOfWeek: [.sunday,.wednesday,.thursday ,.friday], hour: 9, minute: 15, flags: [.repeats, .usesDeviceTimeZone])
                
                let encoded1 = schedule.bytes

                expect(encoded1[0]) == 3 // flags is [0x00, 0x00]
                expect(schedule.repeats).to(beTrue())
                expect(schedule.usesDeviceTimeZone).to(beTrue())
                
                expect(encoded1[1]) == UInt8(206) // 11001110
                expect(encoded1[2]) == 9 // hour
                expect(encoded1[3]) == 15 // min
            }
            
            
            // MARK: • Should plug in custom values
            
            it("should plug in custom values") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: true, usesDeviceTimeZone: true)
                
                expect(schedule.repeats) == true
                expect(schedule.usesDeviceTimeZone) == true
                expect(schedule.flags.intersection([.repeats, .usesDeviceTimeZone])) == [.repeats, .usesDeviceTimeZone]
                expect(schedule.dayOfWeek) == DayOfWeek.wednesday
                expect(schedule.hour) == 16
                expect(schedule.minute) == 20
            }
            
            // MARK: • Should compare as expected
            
            it("should compare as expected") {
                
                let timeSpec1 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false, usesDeviceTimeZone: true)
                let timeSpec2 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .thursday, hour: 16, minute: 20, repeats: false, usesDeviceTimeZone: true)
                let timeSpec3 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 17, minute: 20, repeats: false, usesDeviceTimeZone: true)
                let timeSpec4 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 21, repeats: false, usesDeviceTimeZone: true)
                let timeSpec5 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: true, usesDeviceTimeZone: true)
                let timeSpec6 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false, usesDeviceTimeZone: false)
                
                expect(timeSpec1) == timeSpec1
                expect(timeSpec1) != timeSpec2
                expect(timeSpec1) != timeSpec3
                expect(timeSpec1) != timeSpec4
                expect(timeSpec1) != timeSpec5
                expect(timeSpec1) != timeSpec6
                
                expect(timeSpec2) != timeSpec1
                expect(timeSpec2) == timeSpec2
                expect(timeSpec2) != timeSpec3
                expect(timeSpec2) != timeSpec4
                expect(timeSpec2) != timeSpec5
                expect(timeSpec2) != timeSpec6
                
                expect(timeSpec3) != timeSpec1
                expect(timeSpec3) != timeSpec2
                expect(timeSpec3) == timeSpec3
                expect(timeSpec3) != timeSpec4
                expect(timeSpec3) != timeSpec5
                expect(timeSpec3) != timeSpec6
                
                expect(timeSpec4) != timeSpec1
                expect(timeSpec4) != timeSpec2
                expect(timeSpec4) != timeSpec3
                expect(timeSpec4) == timeSpec4
                expect(timeSpec4) != timeSpec5
                expect(timeSpec4) != timeSpec6
                
                expect(timeSpec5) != timeSpec1
                expect(timeSpec5) != timeSpec2
                expect(timeSpec5) != timeSpec3
                expect(timeSpec5) != timeSpec4
                expect(timeSpec5) == timeSpec5
                expect(timeSpec5) != timeSpec6
                
                expect(timeSpec6) != timeSpec1
                expect(timeSpec6) != timeSpec2
                expect(timeSpec6) != timeSpec3
                expect(timeSpec6) != timeSpec4
                expect(timeSpec6) != timeSpec5
                expect(timeSpec6) == timeSpec6
                
            }
            
            // MARK: • Should encode as expected
            
            it("should encode as expected") {

                let timeSpec1 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false, usesDeviceTimeZone: true)
                
                let encoded1 = timeSpec1.bytes
                
                expect(encoded1[0]) == 2 // flags is [0x00, 0x00]
                expect(timeSpec1.repeats).to(beFalse())
                expect(timeSpec1.usesDeviceTimeZone).to(beTrue())
                
                expect(encoded1[1]) == UInt8(DayOfWeek.wednesday.dayNumber)
                expect(encoded1[2]) == 16 // hour
                expect(encoded1[3]) == 20 // minute

                let timeSpec2 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: true, usesDeviceTimeZone: true)
                
                let encoded2 = timeSpec2.bytes
                
                expect(encoded2[0]) == 3 // flags is [0x00, 0x00]
                expect(timeSpec2.repeats).to(beTrue())
                expect(timeSpec2.usesDeviceTimeZone).to(beTrue())
                
                expect(encoded2[1]) == UInt8(DayOfWeek.wednesday.dayNumber)
                expect(encoded2[2]) == 16 // hour
                expect(encoded2[3]) == 20 // minute
                

            }
            
            // MARK: • Should roundtrip
            
            it("should roundtrip") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false, usesDeviceTimeZone: true)
                let schedule2 = OfflineSchedule.ScheduleEvent.TimeSpecification(bytes: schedule.bytes)
                expect(schedule) == schedule2
            }
            
            // MARK: • UTC → Local Conversions
            
            describe("When converting from UTC to Device Local time") {
                
                typealias TimeSpecification = OfflineSchedule.ScheduleEvent.TimeSpecification
                
                let sunday0000NoRepeatUTCSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .none)

                let sunday0000RepeatUTCSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .repeats)

                let sunday0000NoRepeatLTSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .usesDeviceTimeZone)
                
                let sunday0000RepeatLTSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: [.repeats, .usesDeviceTimeZone])

                let saturday2300NoRepeatUTCSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .none)
                
                let saturday2300RepeatUTCSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .repeats)

                let saturday2300NoRepeatLTSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .usesDeviceTimeZone)
                
                let saturday2300RepeatLTSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: [.repeats, .usesDeviceTimeZone])

                it("should not perform an conversion if already in local time.") {
                    
                    do {
                        try expect(sunday0000NoRepeatLTSpec.asDeviceLocalTimeSpecification(in: utcPlus1)) == sunday0000NoRepeatLTSpec
                        try expect(sunday0000RepeatLTSpec.asDeviceLocalTimeSpecification(in: utcPlus1)) == sunday0000RepeatLTSpec
                        try expect(saturday2300NoRepeatLTSpec.asDeviceLocalTimeSpecification(in: utcMinus1)) == saturday2300NoRepeatLTSpec
                        try expect(saturday2300RepeatLTSpec.asDeviceLocalTimeSpecification(in: .UTC)) == saturday2300RepeatLTSpec
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should only modify the .usesDeviceLocaltime if converting from UTC→UTC") {
                    do {
                        try expect(sunday0000NoRepeatUTCSpec.asDeviceLocalTimeSpecification(in: .UTC)) == sunday0000NoRepeatLTSpec
                        try expect(sunday0000RepeatUTCSpec.asDeviceLocalTimeSpecification(in: .UTC)) == sunday0000RepeatLTSpec
                        try expect(saturday2300NoRepeatUTCSpec.asDeviceLocalTimeSpecification(in: .UTC)) == saturday2300NoRepeatLTSpec
                        try expect(saturday2300RepeatUTCSpec.asDeviceLocalTimeSpecification(in: .UTC)) == saturday2300RepeatLTSpec
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should update dayOfWeek if crossing a day boundary.") {
          
                    do {
                        
                        let azot = try sunday0000RepeatUTCSpec.asDeviceLocalTimeSpecification(in: utcMinus1)
                        expect(azot.dayOfWeek) == DayOfWeek.saturday
                        expect(azot.hour) == 23
                        expect(azot.minute) == sunday0000RepeatUTCSpec.minute
                        expect(azot.flags).toNot(equal(sunday0000RepeatUTCSpec.flags))
                        expect(azot.flags) == sunday0000RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                        
                        try expect(sunday0000RepeatUTCSpec.asDeviceLocalTimeSpecification(in: utcPlus1).dayOfWeek) == sunday0000RepeatUTCSpec.dayOfWeek
                        
                        let cet = try saturday2300RepeatUTCSpec.asDeviceLocalTimeSpecification(in: utcPlus1)
                        expect(cet.dayOfWeek) == DayOfWeek.sunday
                        expect(cet.hour) == 0
                        expect(cet.minute) == saturday2300RepeatUTCSpec.minute
                        expect(cet.flags).toNot(equal(saturday2300RepeatUTCSpec.flags))
                        expect(cet.flags) == saturday2300RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                        
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should have made a change if in-place conversion returns true.") {

                    var azot = sunday0000RepeatUTCSpec

                    let converted = try? azot.convertToLocalTime(in: utcMinus1)
                    expect(converted).to(beTrue())
                    expect(azot.dayOfWeek) == DayOfWeek.saturday
                    expect(azot.hour) == 23
                    expect(azot.minute) == sunday0000RepeatUTCSpec.minute
                    expect(azot.flags).toNot(equal(sunday0000RepeatUTCSpec.flags))
                    expect(azot.flags) == sunday0000RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                    
                }
                
                it("should not have made a change if in-place conversion returns false.") {

                    var azot = sunday0000RepeatUTCSpec
                    let converted = try? azot.convertToLocalTime(in: utcMinus1)
                    expect(converted).to(beTrue())

                    var azot2 = azot
                    let converted2 = try? azot2.convertToLocalTime(in: utcMinus1)
                    expect(converted2).to(beFalse())
                    expect(azot2.dayOfWeek) == azot.dayOfWeek
                    expect(azot2.hour) == azot.hour
                    expect(azot2.minute) == azot.minute
                    expect(azot2.flags) == azot.flags
                }
                
            }
            
        }
        
        // MARK: - When handling ScheduleEvents -
        
        describe("When handling ScheduleEvents") {
        
            // MARK: • Should initialize as expected
            
            it("should initialize as expected") {
                let schedule = OfflineSchedule.ScheduleEvent()
                expect(schedule.timeSpecification) == OfflineSchedule.ScheduleEvent.TimeSpecification()
                expect(schedule.attributes) == [:]
            }
            
            // MARK: • Should persist new attribute instances
            
            it("should persist new attribute instances") {
                
                let value = AttributeValue.boolean(true)
                
                var schedule = OfflineSchedule.ScheduleEvent()
                
                schedule.attributes[25] = value
                
                expect(schedule.attributes.count) == 1
                expect(schedule.attributes[25]) == value
                
                let value2 = AttributeValue.boolean(false)
                schedule.attributes[26] = value2
                
                expect(schedule.attributes.count) == 2
                expect(schedule.attributes[26]) == value2
            }
            
            // MARK: • Should encode poperly
            
            it("should encode properly") {
                
                let value = AttributeValue.boolean(true)
                let instance = AttributeInstance(id: 25, value: value)
                
                var schedule = OfflineSchedule.ScheduleEvent(attributeSpecifications: [instance])
                schedule.attributes[1] = .boolean(false)
                
                expect(schedule.serialized.bytes) == [
                    0x02, // schedule: flags[0] (2 == [.usesDeviceTimeZone]
                    0x01, // schedule: day
                    0x00, // schedule: hour
                    0x00, // schedule: minute
                    0x01, // attribute 1: id[0]
                    0x00, // attribute 1: id[1]
                    0x00, // attribute 1: value.bytes (true)
                    0x19, // attribute 25: id[0]
                    0x00, // attribute 25: id[1]
                    0x01, // attribute 25: value.bytes (false)
                ]
                
            }
            
            // MARK: • Should decode properly
            
            it("should decode properly") {
                
                let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                    0x19: .boolean
                ]
                
                let encoded1: [UInt8] = [
                    0x00, // flags[0]
                    0x03, // schedule: day
                    0x17, // schedule: hour
                    0x14, // schedule: minute
                    0x19, // attribute: id[0]
                    0x00, // attribute: id[1]
                    0x01, // attribute: value.bytes (true)
                ]

                let encoded2: [UInt8] = [
                    0x03, // flags[0]
                    0x03, // schedule: day
                    0x17, // schedule: hour
                    0x14, // schedule: minute
                    0x19, // attribute: id[0]
                    0x00, // attribute: id[1]
                    0x01, // attribute: value.bytes (true)
                ]

                var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                
                expect {
                    parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded1, types: types)
                    }.toNot(throwError())
                
                expect(parseResult.consumed) == encoded1.count
                
                guard let scheduleEvent1 = parseResult.event else {
                    fail("Expected scheduleEvent to not be nil.")
                    return
                }
                
                expect(scheduleEvent1.repeats) == false
                expect(scheduleEvent1.usesDeviceTimeZone).to(beFalse())
                expect(scheduleEvent1.dayOfWeek) == DayOfWeek.tuesday
                expect(scheduleEvent1.hour) == 23
                expect(scheduleEvent1.minute) == 20
                expect(scheduleEvent1.attributes.count) == 1
                expect(scheduleEvent1.attributes[25]).toNot(beNil())
                expect(scheduleEvent1.attributes[25]!.boolValue) == true

                expect {
                    parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded2, types: types)
                    }.toNot(throwError())
                
                expect(parseResult.consumed) == encoded1.count
                
                guard let scheduleEvent2 = parseResult.event else {
                    fail("Expected scheduleEvent to not be nil.")
                    return
                }
                
                expect(scheduleEvent2.repeats).to(beTrue())
                expect(scheduleEvent2.usesDeviceTimeZone).to(beTrue())
                expect(scheduleEvent2.dayOfWeek) == DayOfWeek.tuesday
                expect(scheduleEvent2.hour) == 23
                expect(scheduleEvent2.minute) == 20
                expect(scheduleEvent2.attributes.count) == 1
                expect(scheduleEvent2.attributes[25]).toNot(beNil())
                expect(scheduleEvent2.attributes[25]!.boolValue) == true
                
            }
            
            describe("When converting from UTC to Device Local time") {
                
                typealias TimeSpecification = OfflineSchedule.ScheduleEvent.TimeSpecification
                
                /*
                 
                 * midnight UTC -> UTC-1, should go back a day
                 * 23:00 UTC -> UTC+1, should go forward a day
                 * in all cases, should wrap around.
                 
                 */
                
                // UTC+1 (e.g. CET)
                let utcPlus1 = TimeZone(secondsFromGMT: 3600)!
                
                // UTC-1 (e.g. Azores)
                let utcMinus1 = TimeZone(secondsFromGMT: -3600)!
                
//                let sunday0000NoRepeatUTCSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .none)
//                let sunday0000NoRepeatUTCEvent = OfflineSchedule.ScheduleEvent(timeSpecification: sunday0000NoRepeatUTCSpec, attributes: [0: false])
                
                let sunday0000RepeatUTCSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .repeats)
                let sunday0000RepeatUTCEvent = OfflineSchedule.ScheduleEvent(timeSpecification: sunday0000RepeatUTCSpec, attributes: [0: false])
                
                let sunday0000NoRepeatLTSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: .usesDeviceTimeZone)
                let sunday0000NoRepeatLTEvent = OfflineSchedule.ScheduleEvent(timeSpecification: sunday0000NoRepeatLTSpec, attributes: [0: false])
                
                let sunday0000RepeatLTSpec = TimeSpecification(dayOfWeek: .sunday, hour: 0, minute: 0, flags: [.repeats, .usesDeviceTimeZone])
                let sunday0000RepeatLTEvent = OfflineSchedule.ScheduleEvent(timeSpecification: sunday0000RepeatLTSpec, attributes: [0: false])
                
//                let saturday2300NoRepeatUTCSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .none)
//                let saturday2300NoRepeatUTCEvent = OfflineSchedule.ScheduleEvent(timeSpecification: saturday2300NoRepeatUTCSpec, attributes: [0: false])
                
                let saturday2300RepeatUTCSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .repeats)
                let saturday2300RepeatUTCEvent = OfflineSchedule.ScheduleEvent(timeSpecification: saturday2300RepeatUTCSpec, attributes: [0: false])
                
                let saturday2300NoRepeatLTSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: .usesDeviceTimeZone)
                let saturday2300NoRepeatLTEvent = OfflineSchedule.ScheduleEvent(timeSpecification: saturday2300NoRepeatLTSpec, attributes: [0: false])
                
                let saturday2300RepeatLTSpec = TimeSpecification(dayOfWeek: .saturday, hour: 23, minute: 0, flags: [.repeats, .usesDeviceTimeZone])
                let saturday2300RepeatLTEvent = OfflineSchedule.ScheduleEvent(timeSpecification: saturday2300RepeatLTSpec, attributes: [0: false])
                
                
                it("should not perform an conversion if already in local time.") {
                    
                    do {
                        try expect(sunday0000NoRepeatLTEvent.asDeviceLocalTimeEvent(in: utcPlus1)) == sunday0000NoRepeatLTEvent
                        try expect(sunday0000RepeatLTEvent.asDeviceLocalTimeEvent(in: utcPlus1)) == sunday0000RepeatLTEvent
                        try expect(saturday2300NoRepeatLTEvent.asDeviceLocalTimeEvent(in: utcMinus1)) == saturday2300NoRepeatLTEvent
                        try expect(saturday2300RepeatLTEvent.asDeviceLocalTimeEvent(in: .UTC)) == saturday2300RepeatLTEvent
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should only modify the .usesDeviceLocaltime if converting from UTC→UTC") {
                    do {
                        try expect(sunday0000NoRepeatLTEvent.asDeviceLocalTimeEvent(in: .UTC).timeSpecification) == sunday0000NoRepeatLTEvent.timeSpecification
                        try expect(sunday0000RepeatLTEvent.asDeviceLocalTimeEvent(in: .UTC).timeSpecification) == sunday0000RepeatLTEvent.timeSpecification
                        try expect(saturday2300NoRepeatLTEvent.asDeviceLocalTimeEvent(in: .UTC).timeSpecification) == saturday2300NoRepeatLTEvent.timeSpecification
                        try expect(saturday2300RepeatLTEvent.asDeviceLocalTimeEvent(in: .UTC).timeSpecification) == saturday2300RepeatLTEvent.timeSpecification
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should update dayOfWeek if crossing a day boundary.") {
                    
                    do {
                        
                        let azot = try sunday0000RepeatUTCEvent.asDeviceLocalTimeEvent(in: utcMinus1)
                        expect(azot.dayOfWeek) == DayOfWeek.saturday
                        expect(azot.hour) == 23
                        expect(azot.minute) == sunday0000RepeatUTCSpec.minute
                        expect(azot.flags).toNot(equal(sunday0000RepeatUTCSpec.flags))
                        expect(azot.flags) == sunday0000RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                        
                        try expect(sunday0000RepeatUTCEvent.asDeviceLocalTimeEvent(in: utcPlus1).dayOfWeek) == sunday0000RepeatUTCEvent.dayOfWeek
                        
                        let cet = try saturday2300RepeatUTCEvent.asDeviceLocalTimeEvent(in: utcPlus1)
                        expect(cet.dayOfWeek) == DayOfWeek.sunday
                        expect(cet.hour) == 0
                        expect(cet.minute) == saturday2300RepeatUTCSpec.minute
                        expect(cet.flags).toNot(equal(saturday2300RepeatUTCSpec.flags))
                        expect(cet.flags) == saturday2300RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                        
                    } catch {
                        fail(String(reflecting: error))
                    }
                }
                
                it("should have made a change if in-place conversion returns true.") {
                    
                    var azot = sunday0000RepeatUTCEvent
                    
                    let converted = try? azot.convertToLocalTime(in: utcMinus1)
                    expect(converted).to(beTrue())
                    expect(azot.dayOfWeek) == DayOfWeek.saturday
                    expect(azot.hour) == 23
                    expect(azot.minute) == sunday0000RepeatUTCSpec.minute
                    expect(azot.flags).toNot(equal(sunday0000RepeatUTCSpec.flags))
                    expect(azot.flags) == sunday0000RepeatUTCSpec.flags.union(.usesDeviceTimeZone)
                    
                }
                
                it("should not have made a change if in-place conversion returns false.") {
                    
                    var azot = sunday0000RepeatUTCEvent
                    let converted = try? azot.convertToLocalTime(in: utcMinus1)
                    expect(converted).to(beTrue())
                    
                    var azot2 = azot
                    let converted2 = try? azot2.convertToLocalTime(in: utcMinus1)
                    expect(converted2).to(beFalse())
                    expect(azot2.dayOfWeek) == azot.dayOfWeek
                    expect(azot2.hour) == azot.hour
                    expect(azot2.minute) == azot.minute
                    expect(azot2.flags) == azot.flags
                }
                
            }
        
            // MARK: - When handling bad data -
            
            describe("when handling bad data") {

                // MARK: • Should fail on too-small value section
                
                it("should fail on too-small-value section.") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: repeats
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                        0x01, // attribute: value.bytes (true)
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                    
                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

                // MARK: • Should barf on strings
                
                it("should barf on strings.") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: flags[0]
                        0x00, // schedule: flags[1]
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                        0x01, // attribute: value.bytes (true)
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .utf8S
                    ]
                    
                    expect {
                        ()->Void in
                        let _: (OfflineSchedule.ScheduleEvent?, Int) = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.to(throwError())
                }

                // MARK: • Should barf on raw bytes
                
                it("should barf on raw bytes.") {
                    
                    let encoded: [UInt8] = [
                        0x01, // schedule: flags[0]
                        0x00, // schedule: flags[1]
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                        0x01, // attribute: value.bytes (true)
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .bytes
                    ]
                    
                    expect {
                        ()->Void in
                        let _: (OfflineSchedule.ScheduleEvent?, Int) = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.to(throwError())
                }

                // MARK: • Should barf on missing id
                
                it("should barf on missing id.") {
                    
                    let encoded: [UInt8] = [
                        0x01, // schedule: flags[0]
                        0x00, // schedule: flags[1]
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                        0x01, // attribute: value.bytes (true)
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x1A: .boolean
                    ]
                    
                    expect {
                        ()->Void in
                        let _: (OfflineSchedule.ScheduleEvent?, Int) = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.to(throwError())
                }

                // MARK: • Should barf on bad timespec
                
                it("should barf on a bad timespec.") {
                    
                    let encoded: [UInt8] = [
                        0xFF, // schedule: flags[0]
                        0xFF, // schedule: flags[1]
                        0xFF, // schedule: day
                        0xFF, // schedule: hour
                        0xFF, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                        0x01, // attribute: value.bytes (true)
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x1A: .boolean
                    ]
                    
                    expect {
                        ()->Void in
                        let _: (OfflineSchedule.ScheduleEvent?, Int) = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.to(throwError())
                }

                // MARK: • Shold bail on smaller-than-minimum size
                
                it("should bail on smaller than minimum size.") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: repeats
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                        0x00, // attribute: id[1]
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                    
                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

                // MARK: • Should bail on truncated id
                
                it("should bail on truncated id") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: repeats
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                        0x19, // attribute: id[0]
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)

                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

                // MARK: • Should bail on missing id
                
                it("should bail on missing id altogether.") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: repeats
                        0x03, // schedule: day
                        0x17, // schedule: hour
                        0x14, // schedule: minute
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                    
                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

                // MARK: • Should bail on truncated timespec
                
                it("should bail on truncated timespec.") {
                    
                    let encoded: [UInt8] = [
                        0x00, // schedule: flags
                        0x03, // schedule: day
                        0x17, // schedule: hour
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                    
                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

                // MARK: • Should bail on empty array
                
                it("should bail on empty array.") {
                    
                    let encoded: [UInt8] = [
                    ]
                    
                    let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                        0x19: .sInt32
                    ]
                    
                    var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                    
                    expect {
                        parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                        }.toNot(throwError())
                    
                    expect(parseResult.consumed) == 0
                    expect(parseResult.event).to(beNil())
                }

            }
            
            // MARK: • Should be able to encode a stream of ScheduleEvents
            
            it("should be able to encode a stream of ScheduleEvents") {

                typealias ScheduleEvent = OfflineSchedule.ScheduleEvent
                typealias TimeSpec = ScheduleEvent.TimeSpecification
                
                let event = ScheduleEvent(timeSpecification: TimeSpec(), attributes: [
                    50: .boolean(false),
                    100: .signedInt32(5000),
                    20: .q1516(22.33),
                    70: .q3132(444.555),
                ])
                
                let (serialized, types) = event.serialized
                
                expect(types.count) == 4
                expect(types[50]) == .boolean
                expect(types[100]) == .sInt32
                expect(types[20]) == .q1516
                expect(types[70]) == .q3132
                
                var event2: OfflineSchedule.ScheduleEvent? = nil
                var consumed: Int = 0

                expect {
                    (event2, consumed) = try OfflineSchedule.ScheduleEvent.FromBytes(serialized, types: types)
                    }.toNot(throwError())
                
                expect(event2?.attributes[50]) == .boolean(false)
                expect(event2?.attributes[100]) == .signedInt32(5000)
                expect(event2?.attributes[20]!.doubleValue).to(beCloseTo(22.33, within: 0.001))
                expect(event2?.attributes[70]!.doubleValue).to(beCloseTo(444.555, within: 0.0001))
                
                expect(consumed) == serialized.count
            }

        }
        
        describe("when handling OfflineScheduleFlags") {
            
            it("should initialize and encode properly") {
                
                let flagsNoEnabled = OfflineSchedule.Flags(rawValue: 0)
                expect(flagsNoEnabled.contains(.enabled)).to(beFalse())
                expect(flagsNoEnabled.rawValue) == 0x00
                expect(flagsNoEnabled) == OfflineSchedule.Flags.none
                
                let flagsEnabled = OfflineSchedule.Flags(rawValue: 1)
                expect(flagsEnabled.contains(.enabled)).to(beTrue())
                expect(flagsEnabled.rawValue) == 0x01
                expect(flagsEnabled) == OfflineSchedule.Flags.enabled

            }
        }
        
        // MARK: - OfflineSchedule structs -
        
        describe("when handling an OfflineSchedule") {
            
            typealias ScheduleEvent = OfflineSchedule.ScheduleEvent
            typealias TimeSpec = ScheduleEvent.TimeSpecification
            
            var deviceModel: RecordingDeviceModel!
            var schedule: OfflineSchedule!

            let profile = DeviceProfile(attributes: [
                
                // Values that can be modified
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 204,   type: .sInt8,   operations: [.Read]),
                
                // OfflineSchedule attributes
                DeviceProfile.AttributeDescriptor(id: 59001, type: .bytes,   operations: [.Read, .Write]), // enabled / flags
                DeviceProfile.AttributeDescriptor(id: 59002, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59004, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59007, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59036, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59037, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59038, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59039, type: .bytes,   operations: [.Read, .Write]),
                
                ])
            
            let ts1 = ScheduleEvent.TimeSpecification(dayOfWeek: .sunday, hour: 1, minute: 4, repeats: true, usesDeviceTimeZone: true)
            let event1 = ScheduleEvent(timeSpecification: ts1, attributes: [
                50: .boolean(false),
                100: .signedInt32(5000),
                20: .q1516(22.33),
                70: .q3132(444.555),
                ])

            let ts2 = ScheduleEvent.TimeSpecification(dayOfWeek: .monday, hour: 2, minute: 1, repeats: true, usesDeviceTimeZone: true)
            let event2 = ScheduleEvent(timeSpecification: ts2, attributes: [
                90: .boolean(true),
                101: .signedInt64(-999),
                ])

            let ts3 = ScheduleEvent.TimeSpecification(dayOfWeek: .tuesday, hour: 3, minute: 1, repeats: true, usesDeviceTimeZone: false)
            let event3 = ScheduleEvent(timeSpecification: ts3, attributes: [
                201: .signedInt64(-1999),
                204: .signedInt8(-10),
                ])

            let ts4 = ScheduleEvent.TimeSpecification(dayOfWeek: .tuesday, hour: 4, minute: 1, repeats: true, usesDeviceTimeZone: false)
            let event4 = ScheduleEvent(timeSpecification: ts4, attributes: [
                201: .signedInt64(-1999),
                204: .signedInt8(-10),
                ])

            let ts5 = ScheduleEvent.TimeSpecification(dayOfWeek: .tuesday, hour: 5, minute: 1, repeats: true, usesDeviceTimeZone: false)
            let event5 = ScheduleEvent(timeSpecification: ts5, attributes: [
                201: .signedInt64(-1999),
                204: .signedInt8(-10),
                ])

            beforeEach {
                deviceModel = RecordingDeviceModel(deviceId: "foo", accountId: "moo", profile: profile)
                guard let maybeSchedule = OfflineSchedule(storage: deviceModel) else {
                    fatalError("Expected to initialize an offlineSchedule fixture.")
                }
                schedule = maybeSchedule
            }
            
            afterEach {
                _ = schedule.removeAllEvents()
            }
            
            // MARK: • Should default-initialize properly

            it("should default-initialize properly") {
                expect(schedule.enabled) == false
                expect(schedule.numberOfEvents) == 0
            }
            
            // MARK: • Should detect offline schedule availabilty properly.
            
            it("should detect offline schedule availability properly") {
                expect(deviceModel.supportsOfflineSchedules).to(beTrue())
                let profile2 = DeviceProfile(attributes: [
                    
                    // Values that can be modified
                    DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                    DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                    DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                    DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                    DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                    DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                    DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                    DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt8,   operations: [.Read]),
                    
                    DeviceProfile.AttributeDescriptor(id: 59001, type: .bytes,   operations: [.Read, .Write]), // enabled / flags
                    ])
                
                let deviceModel2 = RecordingDeviceModel(deviceId: "foo2", accountId: "moo2", profile: profile2)
                expect(deviceModel2.supportsOfflineSchedules).to(beFalse())
            }
            
            // MARK: • Should custom-initialize properly
            
            it("should set and clear attributes properly") {

                expect(schedule.enabled).to(beFalse())
                
                expect(schedule.events().count) == 0
                expect(schedule.numberOfEvents) == 0

                schedule.setEvent(event: event1, forAttributeId: 59002)
                expect(schedule.events().count) == 1
                expect(schedule.numberOfEvents) == 1
                expect(schedule.events().first) == event1
                
                expect(deviceModel.value(for: 59004)).to(beNil())
                schedule.setEvent(event: event2, forAttributeId: 59004)
                expect(schedule.events().count) == 2
                expect(schedule.numberOfEvents) == 2
                expect(schedule.events().last) == event2
                
                expect(deviceModel.value(for: 59007)).to(beNil())
                schedule.setEvent(event: event3, forAttributeId: 59007)
                expect(schedule.events().count) == 3
                expect(schedule.numberOfEvents) == 3
                expect(schedule.events().last) == event3
                
                _ = schedule.removeAllEvents()
                
                expect(schedule.events().count) == 0
                expect(schedule.numberOfEvents) == 0
                expect(schedule.events().last).to(beNil())
                expect(deviceModel.value(for: 59002)).to(beNil())
                expect(deviceModel.value(for: 59004)).to(beNil())
                expect(deviceModel.value(for: 59007)).to(beNil())

            }
            
            it("should report supported event counts properly") {
                expect(schedule.numberOfSupportedEvents) == 7
                expect(schedule.numberOfSupportedEventsPerDay) == 1
            }
            
            describe("when querying events") {
                
                beforeEach {
                    schedule.setEvent(event: event1, forAttributeId: 59002)
                    schedule.setEvent(event: event2, forAttributeId: 59004)
                    schedule.setEvent(event: event3, forAttributeId: 59007)
                }

                it("should filter events properly") {
                    let allEvents = schedule.events { _ in return true }
                    expect(allEvents) == schedule.events()
                    expect(allEvents.count) == 3
                    
                    expect(schedule.events { $0.dayOfWeek == .sunday }) == [event1]
                    expect(schedule.events { $0.dayOfWeek == .monday }) == [event2]
                    expect(schedule.events { $0.dayOfWeek == .tuesday }) == [event3]
                    
                    expect(schedule.events { $0.usesDeviceTimeZone }) == [event1, event2]
                    expect(schedule.events { !$0.usesDeviceTimeZone }) == [event3]

                    expect(schedule.events { $0.hour == 1 }) == [event1]
                    expect(schedule.events { $0.hour == 2 }) == [event2]
                    expect(schedule.events { $0.hour == 3 }) == [event3]

                    expect(schedule.events { $0.minute == 1 }) == [event2, event3]
                    expect(schedule.events { $0.minute == 4 }) == [event1]
                }
                
                it("should report the expected available and unavailable days.") {
                    expect(schedule.availableDays) == [.wednesday, .thursday, .friday, .saturday]
                    expect(schedule.unavailableDays) == [.sunday, .monday, .tuesday]
                }
                
                it("should report the expected day/event counts") {
                    let counts = schedule.dayEventCounts
                    expect(counts) == [.sunday: 1, .monday: 1, .tuesday: 1, .wednesday: 0, .thursday: 0, .friday: 0, .saturday: 0]
                }
                
                it("should report the expected events for days of week") {
                    
                    expect(schedule.events(forDayOfWeek: .sunday)) == [event1]
                    expect(schedule.events(forDayOfWeek: .monday)) == [event2]
                    expect(schedule.events(forDayOfWeek: .tuesday)) == [event3]
                    expect(schedule.events(forDayOfWeek: .wednesday)) == []
                    expect(schedule.events(forDayOfWeek: .thursday)) == []
                    expect(schedule.events(forDayOfWeek: .friday)) == []
                    expect(schedule.events(forDayOfWeek: .saturday)) == []
                    
                    expect(schedule.events(forDaysOfWeek: [.wednesday, .thursday, .friday, .saturday])) == []
                    expect(schedule.events(forDaysOfWeek: [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])) == [event1, event2, event3]
                    expect(schedule.events(forDaysOfWeek: [.sunday, .monday, .tuesday])) == [event1, event2, event3]
                    expect(schedule.events(forDaysOfWeek: [.sunday, .monday])) == [event1, event2]
                }
                
            }
            
            describe("when migrating UTC events to localTime") {
                
                beforeEach {
                    deviceModel.shouldAttemptAutomaticUTCMigration = false
                    _ = schedule.addScheduleEvents([event1, event2, event3, event4, event5], commit: true)
                }
                
                afterEach {
                    deviceModel.timeZoneState = .none
                }

                it("should report the appropriate number of UTC events") {
                    expect(schedule.utcEvents) == [event3, event4, event5]
                }
                
                it("shouldn't migrate anything if no timeZone is set on storage.") {
                    expect(schedule.utcEvents.count) == 3
                    var result: [OfflineSchedule.OfflineScheduleMigrationResult]? = nil
                    _ = schedule.migrateUTCEvents(maxCount: 1).then {
                        results in result = results
                    }
                    expect(result?.count).toEventually(equal(0), timeout: 5.0, pollInterval: 0.5)
                }
                
                it("should migrate only the max number of events per call") {
                    expect(schedule.utcEvents.count) == 3

                    deviceModel.timeZoneState = .some(timeZone: utcMinus1, isUserOverride: false)
                    var error: Error? = nil
                    var result: [OfflineSchedule.OfflineScheduleMigrationResult]? = nil
                    _ = schedule.migrateUTCEvents(maxCount: 1).then {
                        r -> Void in result = r
                        }.catch {
                            e in error = e
                    }
                    
                    expect(schedule.utcEvents.count).toEventually(equal(2))
                    expect(schedule.utcEvents.count).toNotEventually(beGreaterThan(2), timeout: 5.0, pollInterval: 0.5)
                    expect(result?.count).toEventually(equal(1), timeout: 5.0, pollInterval: 0.5)
                    expect(result?.count).toNotEventually(beGreaterThan(1), timeout: 5.0, pollInterval: 0.5)
                    expect(error == nil).toNotEventually(beFalse())
                }
                
                it("should migrate all even ts if number of UTC events is less than maxCount") {
                    expect(schedule.utcEvents.count) == 3
                    
                    deviceModel.timeZoneState = .some(timeZone: utcMinus1, isUserOverride: false)
                    var error: Error? = nil
                    var result: [OfflineSchedule.OfflineScheduleMigrationResult]? = nil
                    _ = schedule.migrateUTCEvents(maxCount: 4).then {
                        r -> Void in result = r
                        }.catch {
                            e in error = e
                    }
                    
                    expect(schedule.utcEvents.count).toEventually(equal(0))
                    expect(schedule.utcEvents.count).toNotEventually(beGreaterThan(0), timeout: 5.0, pollInterval: 0.5)
                    expect(result?.count).toEventually(equal(3), timeout: 5.0, pollInterval: 0.5)
                    expect(result?.count).toNotEventually(beGreaterThan(3), timeout: 5.0, pollInterval: 0.5)
                    expect(error == nil).toNotEventually(beFalse())
                }
                
                it("should perform a full migration at intervals.") {
                    expect(deviceModel.offlineSchedule()?.utcEvents.count).toEventually(equal(3), timeout: 5.0, pollInterval: 0.1)
                    deviceModel.timeZoneState = .some(timeZone: utcMinus1, isUserOverride: false)
                    expect(deviceModel.utcMigrationIsInProgress).to(beFalse())
                    var doneCount: Int = 0
                    _ = deviceModel.migrateUTCOfflineScheduleEvents(maxBatchSize: 1, waitBetweenBatches: 1).then {
                        ()->Void in
                        doneCount += 1
                    }
                    expect(deviceModel.utcMigrationIsInProgress).to(beTrue())
                    expect(doneCount).toEventually(equal(1), timeout: 5.0, pollInterval: 0.5)
                    expect(doneCount).toNotEventually(beGreaterThan(1), timeout: 5.0, pollInterval: 0.5)
                    expect(deviceModel.utcMigrationIsInProgress).toEventually(beFalse(), timeout: 5.0, pollInterval: 0.5)
                    expect(schedule.utcEvents.count).toEventually(equal(0), timeout: 5.0, pollInterval: 0.5)
                }
                
                it("shouldn't perform an automatic on timeZone change migration unless allowed.") {
                    expect(deviceModel.offlineSchedule()?.utcEvents.count).toEventually(equal(3), timeout: 5.0, pollInterval: 0.1)
                    expect(deviceModel.shouldAttemptAutomaticUTCMigration).to(beFalse())
                    expect(deviceModel.utcMigrationIsInProgress).to(beFalse())
                    deviceModel.timeZoneState = .some(timeZone: utcMinus1, isUserOverride: false)
                    expect(deviceModel.utcMigrationIsInProgress).to(beFalse())
                    expect(deviceModel.offlineSchedule()?.utcEvents.count).toNotEventually(beLessThan(3), timeout: 5.0, pollInterval: 0.5)
                }
                
                it("should perform an automatic on timeZone change migration if allowed.") {
                    
                    expect(deviceModel.offlineSchedule()?.utcEvents.count).toEventually(equal(3), timeout: 5.0, pollInterval: 0.1)
                    expect(deviceModel.utcMigrationIsInProgress).to(beFalse())
                    deviceModel.shouldAttemptAutomaticUTCMigration = true
                    expect(deviceModel.utcMigrationIsInProgress).to(beFalse())
                    deviceModel.timeZoneState = .some(timeZone: utcMinus1, isUserOverride: false)
                    expect(deviceModel.utcMigrationIsInProgress).to(beTrue())
                    
                    expect(deviceModel.utcMigrationIsInProgress).toEventually(beFalse(), timeout: 5.0, pollInterval: 0.5)
                    expect(schedule.utcEvents.count).toEventually(equal(0), timeout: 5.0, pollInterval: 0.5)
                }

                
            }
            
            // MARK: • Should commit only the events that were changed.
            
            it("should commit only the events that were changed") {
                
            }
            
            // TODO: • Should be able to initialize from attributes
            
            it("should be able to initialize from attributes") {
                
            }
            
            // TODO: • Should encode to attributes
            
            it("should encode to attributes") {
                
            }
            
            // TODO: • Should add an event
            
            it("should be able to add an event") {
                
            }
            
            // TODO: • Should remove an event
            
            it("Should be able to remove an event") {
                
            }
            
            // TODO: • Should toggle enabled flag
            
            it("Should be able to toggle enabled flag") {
                
            }
            
        }
        
        describe("when handling a device") {
            
            it("should indicate whether or not it's offline-schedulable") {
                
            }
            
            it("should persist offline schedule changes") {
                
            }

            it("should send events when its offline schedule changes") {
                
            }
            
            
        }
        
    }
}
