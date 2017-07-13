//
//  DeviceRuleTests.swift
//  iTokui
//
//  Created by Justin Middleton on 5/11/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Afero


class DeviceRuleTimeSpec: QuickSpec {
    override func spec() {

        describe("When creating a DateTypes.Time object") {

            it("Default-initialized instances should have seconds zeroed.") {
                
                // The test I would like to run is that we're initialized with the current time,
                // but with seconds zeroed. Requires some chicanery (read: swizzling) to reliably
                // test, however, since we have to "lock down" the clock. Punting for now.
                
                let t = DateTypes.Time()
                expect(t.seconds) == 0
            }
            
            it("should have seconds zeroed when initializing from an NSDate.") {

                let calendar = Calendar.current
                
                let date = Date(timeIntervalSince1970: 31) // 31 seconds past Jan 1 1970 00:00:00 UTC
                let tz = calendar.timeZone
                let t = DateTypes.Time(date: date, timeZone: tz)
                
                let components = calendar.dateComponents(
                    [.hour, .minute, .second, .timeZone],
                    from: date
                )

                expect(components.second) == 31 // sanity check the test rig.
                
                expect(t.seconds) == 0
                expect(t.minute) == components.minute
                expect(t.hour) == components.hour
                expect(t.timeZone) == components.timeZone
            }
        }
    }
}

class DeviceRuleDecodeSpec: QuickSpec {

    override func spec() {
        
        describe("When decoding JSON") {
            
            let json = try? self.readJson("ruleTest1")! as! [AnyObject]
            let maybeRules: [DeviceRule]? = |<json

            if let rules = maybeRules {

                it("Should decode.") {

                    expect(rules.count) == 2
                    expect(rules[0].ruleId == nil).to(beFalse())
                    expect(rules[0].enabled).to(beTrue())
                }
                
                it("Should have the expected deviceFilterCriteria") {
                    
                    let rule = rules[0]
                    expect(rule.filterCriteria?.count ?? 0) == 1
                    let criterion: DeviceFilterCriterion = (rule.filterCriteria?.first!)!
                    
                    expect(criterion.attribute.id) == 123
                    expect(criterion.attribute.value.int64Value) == 3735928559
                    expect(criterion.operation) == DeviceFilterCriterion.Operation.equals
                    expect(criterion.deviceId) == "ABCD3456"
                    expect(criterion.trigger).to(beFalse())
                    
                }
                
                it("Should have the expected schedule") {
                    
                    let rule = rules[0]

                    guard let schedule = rule.schedule else {
                        fail("No schedule attached to rule.")
                        return
                    }
                    
                    expect(schedule.dayOfWeek) == [.monday, .tuesday, .saturday]
                    expect(schedule.time.timeZone) == TimeZone(identifier: "America/Los_Angeles")
                    expect(schedule.time.seconds) == 33
                    expect(schedule.time.minute) == 22
                    expect(schedule.time.hour) == 11
                }
                
                it("Should have the expected device actions") {
                    
                    let rule = rules[0]
                    
                    let deviceActions = rule.actions
                    expect(deviceActions.count) == 1
                    
                    let action = deviceActions[0]
                    expect(action.deviceId) == "NRBQ333"
                    expect(action.durationSeconds) == 34
                    expect(action.attributes.count) == 1
                    
                    let attribute = action.attributes[0]
                    expect(attribute.id) == 234
                    expect(attribute.value.int64Value) == 1933036286
                    
                }
            } else {
                fail("Expected [DeviceRule] from JSON parse, got nil.")
            }
        }
    }
}

class DeviceRuleEncodeSpec: QuickSpec {
    
    override func spec() {
        
        describe("When encoding JSON") {
            
            let usla = TimeZone(identifier: "America/Los_Angeles")
            let uschi = TimeZone(identifier: "America/Chicago")
            
            it("Should round-trip Attributes") {
                
                let attribute = AttributeInstance(id: 5, stringValue: "AABBCC")
                if let attribute2: AttributeInstance = |<attribute.JSONDict {
                    expect(attribute2) == attribute
                } else {
                    fail("attribute2 did not decode as expected.")
                }
                
            }
            
            it("Should round-trip actions.") {

                let attributes: [AttributeInstance] = [
                    AttributeInstance(id: 1, stringValue: "CCCC"),
                    AttributeInstance(id: 2, stringValue: "DDDD"),
                    ].flatMap { $0 }
                
                let action = DeviceRuleAction(deviceId: "I'm a device ID", attributes: attributes, durationSeconds: 9)
                if let copied: DeviceRuleAction = |<action.JSONDict {
                    expect(copied) == action
                } else {
                    fail("action did not copy as expected.")
                }
                
                let action2 = DeviceRuleAction(deviceId: "I'm a device ID", attributes: attributes, durationSeconds: nil)
                if let copied: DeviceRuleAction = |<action2.JSONDict {
                    expect(copied) == action2
                } else {
                    fail("action2 did not copy as expected.")
                }
                
                expect(action2) != action
            }
            
            it("Should round-trip times.") {
                
                let usla = TimeZone(identifier: "America/Los_Angeles")
                let time1 = DateTypes.Time(hour: 3, minute: 4, seconds: 5, timeZone: usla!)

                if let copied: DateTypes.Time = |<time1.JSONDict {
                    expect(copied) == time1
                } else {
                    fail("time1 did not copy as expected.")
                }
                
                let uschi = TimeZone(identifier: "America/Chicago")
                let time2 = DateTypes.Time(hour: 3, minute: 4, seconds: 5, timeZone: uschi!)

                if let copied: DateTypes.Time = |<time2.JSONDict {
                    expect(copied) == time2
                    expect(copied) != time1
                } else {
                    fail("time2 did not copy as expected.")
                }
                
                expect(time2) != time1
            }
            
            it("Should round-trip schedules.") {

                let time1 = DateTypes.Time(hour: 3, minute: 4, seconds: 5, timeZone: usla!)
                
                let schedule1 = DeviceRule.Schedule(dayOfWeek: [.monday, .tuesday], time: time1, scheduleId: "abcd")
                if let copied: DeviceRule.Schedule = |<schedule1.JSONDict {
                    expect(copied) == schedule1
                } else {
                    fail("schedule1 did not copy as expected")
                }

                let schedule2 = DeviceRule.Schedule(dayOfWeek: [.monday, .tuesday], time: time1, scheduleId: "efgh")
                if let copied: DeviceRule.Schedule = |<schedule1.JSONDict {
                    expect(copied) == schedule1
                    expect(copied) != schedule2 // scheduleId is different
                } else {
                    fail("schedule1 did not copy as expected")
                }
                
                let time3 = DateTypes.Time(hour: 3, minute: 4, seconds: 5, timeZone: uschi!)
                
                let schedule3 = DeviceRule.Schedule(dayOfWeek: [.monday, .tuesday], time: time3, scheduleId: "efgh")
                if let copied: DeviceRule.Schedule = |<schedule3.JSONDict {
                    expect(copied) == schedule3
                    expect(copied) != schedule2 // timeZone is different
                } else {
                    fail("schedule1 did not copy as expected")
                }
                
                let schedule4 = DeviceRule.Schedule(dayOfWeek: [.monday, .wednesday], time: time3, scheduleId: "efgh")
                if let copied: DeviceRule.Schedule = |<schedule4.JSONDict {
                    expect(copied) == schedule4
                    expect(copied) != schedule3 // dayOfWeek is different
                } else {
                    fail("schedule1 did not copy as expected")
                }

            }
            
            describe("With filter criteria") {
                
                it("Should round-trip") {

                    let attribute1 = AttributeInstance(id: 1, stringValue: "0011")
                    let crit1 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "bar", trigger: true)
                    
                    if let copied: DeviceFilterCriterion = |<crit1.JSONDict {
                        expect(copied) == crit1
                    } else {
                        fail("crit1 did not copy as expected")
                    }
                    
                    let crit2 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "bar", trigger: true)
                    expect(crit2) == crit1
                    
                    let crit3 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "bar", trigger: false)
                    if let copied: DeviceFilterCriterion = |<crit3.JSONDict {
                        expect(copied) == crit3
                        expect(copied) != crit2
                    } else {
                        fail("crit3 did not copy as expected")
                    }
                    
                    let crit4 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "car", trigger: true)
                    if let copied: DeviceFilterCriterion = |<crit4.JSONDict {
                        expect(copied) == crit4
                        expect(copied) != crit3
                        expect(copied) != crit2
                    } else {
                        fail("crit4 did not copy as expected")
                    }

                    let crit5 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "car", trigger: false)
                    if let copied: DeviceFilterCriterion = |<crit5.JSONDict {
                        expect(copied) == crit5
                        expect(copied) != crit4
                        expect(copied) != crit3
                        expect(copied) != crit2
                    } else {
                        fail("crit4 did not copy as expected")
                    }
                }
            }
            
            describe("With device rules") {

                let attribute1 = AttributeInstance(id: 1, stringValue: "0011")
                let attribute2 = AttributeInstance(id: 2, stringValue: "0022")
                let attribute3 = AttributeInstance(id: 3, stringValue: "0033")
                let attribute4 = AttributeInstance(id: 4, stringValue: "0044")

                let crit1 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "bar", trigger: true)
                let crit2 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "bar", trigger: false)
                let crit3 = DeviceFilterCriterion(attribute: attribute1, operation: .equals, deviceId: "car", trigger: true)

                let action1 = DeviceRuleAction(deviceId: "xxx", attributes: [attribute1], durationSeconds: 1)
                let action2 = DeviceRuleAction(deviceId: "yyy", attributes: [attribute2], durationSeconds: 2)
                let action3 = DeviceRuleAction(deviceId: "zzz", attributes: [attribute3, attribute4], durationSeconds: 3)
                
                let time1 = DateTypes.Time(hour: 3, minute: 4, seconds: 5, timeZone: usla!)
                let schedule1 = DeviceRule.Schedule(dayOfWeek: [.monday, .tuesday], time: time1, scheduleId: "abcd")

                let rule1 = DeviceRule(schedule: schedule1, actions: [action1], filterCriteria: [crit1], enabled: true, ruleId: "aaa")
                let rule2 = DeviceRule(schedule: schedule1, actions: [action2], filterCriteria: [crit1], enabled: true, ruleId: "aaa")
                let rule3 = DeviceRule(schedule: schedule1, actions: [action2, action3], filterCriteria: [crit1], enabled: true, ruleId: "aaa")
                let rule4 = DeviceRule(schedule: schedule1, actions: [action2, action3], filterCriteria: [crit1], enabled: false, ruleId: "aaa")
                let rule5 = DeviceRule(schedule: schedule1, actions: [action2, action3], filterCriteria: [crit1], enabled: false, ruleId: "bbb")
                let rule6 = DeviceRule(schedule: schedule1, actions: [action2, action3], filterCriteria: [crit2], enabled: false, ruleId: "bbb")
                let rule7 = DeviceRule(schedule: schedule1, actions: [action2, action3],
                                       filterCriteria: [crit2, crit3], enabled: false, ruleId: "bbb")
                
                it("Should test equality") {
                    expect(rule1) == rule1
                    expect(rule2) == rule2
                    expect(rule3) == rule3
                    expect(rule4) == rule4
                    expect(rule5) == rule5
                    expect(rule6) == rule6
                    expect(rule7) == rule7
                }

                it("Should round-trip") {
                
                    if let copied: DeviceRule = |<rule1.JSONDict {
                        expect(copied) == rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                    
                    if let copied: DeviceRule = |<rule2.JSONDict {
                        expect(copied) == rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }

                    if let copied: DeviceRule = |<rule3.JSONDict {
                        expect(copied) == rule3
                        expect(copied) != rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                    
                    if let copied: DeviceRule = |<rule4.JSONDict {
                        expect(copied) == rule4
                        expect(copied) != rule3
                        expect(copied) != rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                    
                    if let copied: DeviceRule = |<rule5.JSONDict {
                        expect(copied) == rule5
                        expect(copied) != rule4
                        expect(copied) != rule3
                        expect(copied) != rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                    
                    if let copied: DeviceRule = |<rule6.JSONDict {
                        expect(copied) == rule6
                        expect(copied) != rule5
                        expect(copied) != rule4
                        expect(copied) != rule3
                        expect(copied) != rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                    
                    if let copied: DeviceRule = |<rule7.JSONDict {
                        expect(copied) == rule7
                        expect(copied) != rule6
                        expect(copied) != rule5
                        expect(copied) != rule4
                        expect(copied) != rule3
                        expect(copied) != rule2
                        expect(copied) != rule1
                    } else {
                        fail("rule1 did not copy as expected")
                    }
                }
            }
        }
    }
}
