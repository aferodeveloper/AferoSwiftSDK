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
        
        // MARK: - Time specificstions -
        
        describe("when handling time specifications") {
        
            // MARK: • Should initialize to expected defaults
            
            it("should initialize to expected defaults") {
                
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification()
                
                expect(schedule.repeats) == false
                expect(schedule.utcDayOfWeek) == DayOfWeek.sunday
                expect(schedule.utcHour) == 0
                expect(schedule.utcMinute) == 0
            }
            
            // MARK: • Should plug in custom values
            
            it("should plug in custom values") {
                
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false)
                
                expect(schedule.repeats) == false
                expect(schedule.utcDayOfWeek) == DayOfWeek.wednesday
                expect(schedule.utcHour) == 16
                expect(schedule.utcMinute) == 20
                
            }
            
            // MARK: • Should encode as expected
            
            it("should encode as expected") {

                let timeSpec1 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false)
                
                let encoded1 = timeSpec1.bytes
                
                expect(encoded1[0]) == 0 // flags is [0x00, 0x00]
                expect(timeSpec1.repeats) == false
                
                expect(encoded1[1]) == UInt8(DayOfWeek.wednesday.dayNumber)
                expect(encoded1[2]) == 16 // hour
                expect(encoded1[3]) == 20 // minute

                let timeSpec2 = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: true)
                
                let encoded2 = timeSpec2.bytes
                
                expect(encoded2[0]) == 1 // flags is [0x00, 0x00]
                expect(timeSpec2.repeats) == true
                
                expect(encoded2[1]) == UInt8(DayOfWeek.wednesday.dayNumber)
                expect(encoded2[2]) == 16 // hour
                expect(encoded2[3]) == 20 // minute
                

            }
            
            // MARK: • Should roundtrip
            
            it("should roundtrip") {
                let schedule = OfflineSchedule.ScheduleEvent.TimeSpecification(dayOfWeek: .wednesday, hour: 16, minute: 20, repeats: false)
                let schedule2 = OfflineSchedule.ScheduleEvent.TimeSpecification(bytes: schedule.bytes)
                expect(schedule) == schedule2
                
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
                    0x00, // schedule: flags[0]
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
                
                let encoded: [UInt8] = [
                    0x00, // flags[0]
                    0x03, // schedule: day
                    0x17, // schedule: hour
                    0x14, // schedule: minute
                    0x19, // attribute: id[0]
                    0x00, // attribute: id[1]
                    0x01, // attribute: value.bytes (true)
                ]
                
                let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
                    0x19: .boolean
                ]

                var parseResult: (event: OfflineSchedule.ScheduleEvent?, consumed: Int) = (nil, 0)
                
                expect {
                    parseResult = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
                    }.toNot(throwError())
                
                expect(parseResult.consumed) == encoded.count
                
                guard let scheduleEvent = parseResult.event else {
                    fail("Expected scheduleEvent to not be nil.")
                    return
                }
                
                expect(scheduleEvent.repeats) == false
                expect(scheduleEvent.utcDayOfWeek) == DayOfWeek.tuesday
                expect(scheduleEvent.utcHour) == 23
                expect(scheduleEvent.utcMinute) == 20
                expect(scheduleEvent.attributes.count) == 1
                expect(scheduleEvent.attributes[25]).toNot(beNil())
                expect(scheduleEvent.attributes[25]!.boolValue) == true
                
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
                        0x00, // schedule: repeats
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
            
//            xit("should be able to decode a stream of ScheduleEvents") {
//                
//                let int32val: Int32 = 1234
//                let int32arr = toByteArray(int32val)!
//                
//                let q1516val: Double = 130.435
//                let q1516arr: [UInt8] = doubleToQ(q1516val, n: 16, t: Int32.self)
//
//                let encoded: [UInt8] = [
//                    
//                    // event 1 — Bool
//                    0x00, // schedule: repeats
//                    0x03, // schedule: day
//                    0x17, // schedule: hour
//                    0x14, // schedule: minute
//                    0x19, // attribute: id[0]
//                    0x00, // attribute: id[1] (0x1900 = 25)
//                    0x01, // attribute: value.bytes (true)
//
//                    // event 2 — Int32
//                    1, // schedule: repeats
//                    6, // schedule: day (friday)
//                    12, // schedule: hour
//                    32, // schedule: minute
//                    0xBE, // attribute: id[0]
//                    0xEF, // attribute: id[1] (0xBEEF = 61_374)
//                    int32arr[0], // attribute: value.bytes (true)
//                    int32arr[1], // attribute: value.bytes (true)
//                    int32arr[2], // attribute: value.bytes (true)
//                    int32arr[3], // attribute: value.bytes (true)
//
//                    // event 3 — .Q1516
//                    0, // schedule: repeats
//                    7, // schedule: day (saturday)
//                    10, // schedule: hour
//                    11, // schedule: minute
//                    0xFE, // attribute: id[0]
//                    0xCA, // attribute: id[1] (0xFECA = 51_966)
//                    q1516arr[0],
//                    q1516arr[1],
//                    q1516arr[2],
//                    q1516arr[3], // attribute: .Q1516 (57_005.74583)
//                    
//                    // residue
//                    0x01,
//                    0x02,
//                    0x03,
//                    0x04,
//
//                ]
//                
//                let types: [Int: DeviceProfile.AttributeDescriptor.DataType] = [
//                    25: .Boolean,
//                    61374: .SInt32,
//                    51966: .Q1516,
//                    47806: .UTF8S,
//                ]
//                
//                var results: OfflineSchedule.ScheduleEvent.ScheduleEventsFromBytes = ([], 0, [])
//                
//                expect {
//                    results = try OfflineSchedule.ScheduleEvent.FromBytes(encoded, types: types)
//                }.toNot(throwError())
//                
//                let scheduleEvents = results.events
//                
//                expect(results.residue.count) == 4
//                expect(results.consumed) == encoded.count - 4
//                expect(scheduleEvents.count) == 3
//                
//                let boolEvent = scheduleEvents[0]
//                expect(boolEvent.repeats) == false
//                expect(boolEvent.dayOfWeek) == DayOfWeek.Tuesday
//                expect(boolEvent.hour) == 23
//                expect(boolEvent.minute) == 20
//                expect(boolEvent.attributes.count) == 1
//                expect(boolEvent.attributes[25]).toNot(beNil())
//                expect(boolEvent.attributes[25]!.boolValue) == true
//
//                let i32Event = scheduleEvents[1]
//                expect(i32Event.repeats) == true
//                expect(i32Event.dayOfWeek) == DayOfWeek.Friday
//                expect(i32Event.hour) == 12
//                expect(i32Event.minute) == 32
//                expect(boolEvent.attributes.count) == 1
//                expect(i32Event.attributes[61_374]).toNot(beNil())
//                expect(i32Event.attributes[61_374]!.int32Value) == int32val
//
//                let q1516Event = scheduleEvents[2]
//                expect(q1516Event.repeats) == false
//                expect(q1516Event.dayOfWeek) == DayOfWeek.Saturday
//                expect(q1516Event.hour) == 10
//                expect(q1516Event.minute) == 11
//                expect(boolEvent.attributes.count) == 1
//                expect(q1516Event.attributes[51_966]).toNot(beNil())
//                expect(q1516Event.attributes[51_966]!.doubleValue).to(beCloseTo(q1516val, within: 0.0001))
//
//            }
            
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
        
//        describe("when handling OfflineScheduleFlags") {
//            
//            it("should initialize and encode properly") {
//                
//                let flagsNoEnabled = OfflineSchedule.Flags(rawValue: 0)
//                expect(flagsNoEnabled.contains(.enabled)).to(beFalse())
//                expect(flagsNoEnabled.bytes) == [0x00, 0x00]
//                expect(flagsNoEnabled) == OfflineSchedule.Flags.none
//                
//                let flagsNoEnabled2 = OfflineSchedule.Flags.none
//                expect(flagsNoEnabled2.contains(.enabled)).to(beFalse())
//                expect(flagsNoEnabled2.bytes) == [0x00, 0x00]
//                
//                let flagsEnabled = OfflineSchedule.Flags(rawValue: 1)
//                expect(flagsEnabled.contains(.enabled)).to(beTrue())
//                expect(flagsEnabled.bytes) == [0x01, 0x00]
//                expect(flagsEnabled) == OfflineSchedule.Flags.enabled
//
//            }
//        }
        
        // MARK: - OfflineSchedule structs -
        
        describe("when handling an OfflineSchedule") {
            
            typealias ScheduleEvent = OfflineSchedule.ScheduleEvent
            typealias TimeSpec = ScheduleEvent.TimeSpecification
            
            let profile = DeviceProfile(attributes: [
                
                // Values that can be modified
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt8,   operations: [.Read]),
                
                // OfflineSchedule attributes
                DeviceProfile.AttributeDescriptor(id: 59001, type: .bytes,   operations: [.Read, .Write]), // enabled / flags
                DeviceProfile.AttributeDescriptor(id: 59002, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59004, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59007, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59036, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59037, type: .bytes,   operations: [.Read, .Write]),
                
                ])
            
            let deviceModel = RecordingDeviceModel(deviceId: "foo", accountId: "moo", profile: profile)
            
            let ts1 = ScheduleEvent.TimeSpecification(dayOfWeek: .sunday, hour: 1, minute: 1, repeats: true)
            let event1 = ScheduleEvent(timeSpecification: ts1, attributes: [
                50: .boolean(false),
                100: .signedInt32(5000),
                20: .q1516(22.33),
                70: .q3132(444.555),
                ])

            let ts2 = ScheduleEvent.TimeSpecification(dayOfWeek: .monday, hour: 1, minute: 1, repeats: true)
            let event2 = ScheduleEvent(timeSpecification: ts2, attributes: [
                90: .boolean(true),
                101: .signedInt64(-999),
                ])

            let ts3 = ScheduleEvent.TimeSpecification(dayOfWeek: .tuesday, hour: 1, minute: 1, repeats: true)
            let event3 = ScheduleEvent(timeSpecification: ts3, attributes: [
                201: .signedInt64(-1999),
                204: .signedInt8(-10),
                ])
            
            // MARK: • Should default-initialize properly

            it("should default-initialize properly") {

                let maybeSchedule = OfflineSchedule(storage: deviceModel)
                expect(maybeSchedule).toNot(beNil())
                
                guard let schedule = maybeSchedule else {
                    fail("Schedule was nil; cannot continue.")
                    return
                }
                
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
            
            it("should custom-initialize properly") {

                let maybeSchedule = OfflineSchedule(storage: deviceModel)
                expect(maybeSchedule).toNot(beNil())
                
                guard let schedule = maybeSchedule else {
                    fail("Schedule was nil; cannot continue.")
                    return
                }
                
                expect(schedule.enabled).to(beFalse())
                
                expect(schedule.events().count) == 0
                schedule.setEvent(event: event1, forAttributeId: 59002)
                expect(schedule.events().count) == 1
                expect(schedule.events().first) == event1
                
                expect(deviceModel.valueForAttributeId(59004)).to(beNil())
                schedule.setEvent(event: event2, forAttributeId: 59004)
                expect(schedule.events().count) == 2
                expect(schedule.events().last) == event2

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
