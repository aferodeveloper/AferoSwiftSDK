//
//  DeviceProfileTests.swift
//  iTokui
//
//  Created by Tony Myles on 2/16/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import Afero
import Quick
import Nimble



class PresentationSpec: QuickSpec {
    
    override func spec() {
        
        describe("When checking attribute operations") {
            
            let profile = DeviceProfile(attributes: [
                
                // Values that can be modified
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 202,   type: .sInt8,   operations: [.Read]),
                
                // OfflineSchedule attributes
                DeviceProfile.AttributeDescriptor(id: 59001, type: .boolean,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59002, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59004, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59007, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59036, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59037, type: .bytes,   operations: [.Read, .Write]),
                
                ])

            it("Should correctly show readable attributes") {
                expect(profile.hasPresentableReadableAttributes).to(beFalse())
                expect(profile.hasReadableAttributes).to(beTrue())
                expect(profile.readableAttributes.count) == 14
            }
            
            it("Should correclty show writable attributes") {
                expect(profile.hasPresentableWritableAttributes).to(beFalse())
                expect(profile.hasWritableAttributes).to(beTrue())
                expect(profile.writableAttributes.count) == 10
            }
            
        }
        
        describe("When contemplating coffee makers") {
        
            it("should deserialize correctly.") {
                if let coffeePresentation: DeviceProfile.Presentation = |<(try? self.readJson("coffeemaker")! as! [String: Any]) {
                    expect(coffeePresentation.gauge.foreground?.images.count) == 1
                    expect(coffeePresentation.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/devices/devices_coffee.png"
                    
                    expect(coffeePresentation.groups?.count) == 2
                    expect(coffeePresentation.groups?[1].label) == "Cups 1-4"
                    
                    expect(coffeePresentation.controls?.count) == 2
                    expect(coffeePresentation.controls?[0].id) == 100
                    expect(coffeePresentation.controls?[0].type) == "menuControl"
                    
                    expect(coffeePresentation.controls?[0].attributeMap?.count) == 1
                    expect(coffeePresentation.controls?[0].attributeMap?["value"]) == 201
                    
                    
                    expect(coffeePresentation.attributeOptions[201]?.valueOptions.count) == 2

                    let option0 = coffeePresentation.attributeOptions[201]?.valueOptions[0]
                    expect(option0?.match) == "0"
                    expect(option0?.apply["label"] as? String) == "Off"

                    let option1 = coffeePresentation.attributeOptions[201]?.valueOptions[1]
                    expect(option1?.match) == "1"
                    expect(option1?.apply["label"] as? String) == "On"

                    expect(coffeePresentation.attributeOptions[201]?.label) == "Brew"
                    expect(coffeePresentation.attributeOptions[201]?.flags) == DeviceProfile.Presentation.Flags.PrimaryOperation
                    
                    
                    let apply: [String: Any]? = coffeePresentation.attributeOptions[201]?.valueOptions[1].apply
                    
                    expect(apply).toNot(beNil())
                    expect(apply!["label"] as? String) == "On"
                    
                    
                } else {
                    fail("Could not read JSON fixture.")
                }
            }
            
        }
        
        describe("When contemplating a plain old fan") {
            
            let fanPresentation : DeviceProfile.Presentation! = |<(try? self.readJson("fan")!)

            xit("should deserialize correctly.") {
                
                expect(fanPresentation.gauge.background?.images.count) == 1
                expect(fanPresentation.gauge.background?.images[0].URI) == "http://tonyhacks.com/icons/3x/devices/devices_fan_grill.png"
                expect(fanPresentation.gauge.foreground?.images.count) == 1
                expect(fanPresentation.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/devices/devices_fan_blades.png"
                
                expect(fanPresentation.gauge.displayRules?.count) == 2
                expect(fanPresentation.gauge.displayRules?[0]["match"] as? String) == "0"

                let apply0 = fanPresentation.gauge.displayRules?[0]["apply"] as? [String: Any]
                expect(apply0).toNot(beNil())
                expect(apply0?["rotate"] as? String) == "forward"
                expect(apply0?["rotateBehavior"] as? String) == "oneshot"

                let apply1 = fanPresentation.gauge.displayRules?[1]["apply"] as? [String: Any]
                expect(apply1).toNot(beNil())
                expect(apply1?["rotate"] as? String) == "forward"
                expect(apply1?["rotateBehavior"] as? String) == "loop"

                expect(fanPresentation.groups?.count) == 1
                expect(fanPresentation.groups?[0].gauge.foreground?.images.count) == 1
                expect(fanPresentation.groups?[0].gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/control_power_on.png"
                
                expect(fanPresentation.controls?.count) == 1
                
            }
            
            it("should produce a displayRulesProcessor") {
                
                let process: AttributeProcessor = fanPresentation.gauge.displayRulesProcessor(["default": "value"])
                
                let attsOn = AttributeMap([
                    100: 1
                    ], primary: 100)
                let resultOn = process(attsOn)

                expect(resultOn.count) == 3
                expect(resultOn["rotate"] as? String) == "forward"
                expect(resultOn["rotateBehavior"] as? String) == "loop"

                let attsOff = AttributeMap([
                    100: 0
                    ], primary: 100)
                
                let resultOff = process(attsOff)
                expect(resultOff.count) == 3
                expect(resultOff["rotate"] as? String) == "forward"
                expect(resultOff["rotateBehavior"] as? String) == "oneshot"
                
            }
        }
        
        describe("When contemplating a massage chair") {
            
            let initial: [String: Any] = [
                "hi": "there",
                "intArray": [
                    1,
                    2,
                    3
                ],
                "anotherDict": [
                    1: "one",
                    2: "two",
                    3: "three"
                ]
            ]
            
            let chairPresentation : DeviceProfile.Presentation! = |<(try? self.readJson("massagechair")!)
            
            it("Should pick up primaryOperation") {
                expect(chairPresentation.primaryOperationOption).toNot(beNil())
                expect(chairPresentation.primaryOperationOption?.label) == "Power"
                expect(chairPresentation.primaryOperationOption?.valueOptions.count) == 2
            }
            
            it("should dereference controls correctly") {
                
                let massageGroup = chairPresentation.groups![1]
                
                let massageControlId0: ControlIdPresentable? = massageGroup[control: 0]
                expect(massageControlId0).toNot(beNil())
                expect(massageControlId0) == 100
                
                let massageControl0: ControlPresentable? = massageGroup[controlId: 100]
                expect(massageControl0).toNot(beNil())
                expect(massageControl0?.id) == 100
                expect(massageControl0?.type) == "menuControl"
                
                let massageControl0ValueAttributeId = massageControl0?.attributeMap?["value"]
                expect(massageControl0ValueAttributeId).toNot(beNil())

                let massageControl0ValueAttribute = chairPresentation.attributeOptions[massageControl0ValueAttributeId!]
                expect(massageControl0ValueAttribute).toNot(beNil())
                
                expect(massageControl0ValueAttribute?.valueOptions.count) == 7
                expect(massageControl0ValueAttribute?.label) == "Massage"
                expect(massageControl0ValueAttribute?.label) == "Massage"
                
                let heatGroup = chairPresentation.groups![2]

                let heatControlId0: ControlIdPresentable? = heatGroup[control: 0]
                expect(heatControlId0).toNot(beNil())
                expect(heatControlId0) == 101
                
                let heatControl0: ControlPresentable? = heatGroup[controlId: 101]
                expect(heatControl0).toNot(beNil())
                expect(heatControl0?.id) == 101
                expect(heatControl0?.type) == "menuControl"

            }
            
            it("should deserialize correctly") {
                expect(chairPresentation.gauge.foreground?.images.count) == 1
                expect(chairPresentation.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/devices/devices_massage_chair.png"
                
                expect(chairPresentation.groups?.count) == 5
                
                let powerGroup = chairPresentation.groups![0]
                expect(powerGroup.gauge.foreground?.images.count) == 1
                expect(powerGroup.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/control_power_on.png"
                expect(powerGroup.gauge.background).to(beNil())
                
                let massageGroup = chairPresentation.groups![1]
                expect(massageGroup.label) == "Massage"
                expect(massageGroup.controlCount) == 1

                let controlId0_0: ControlIdPresentable? = massageGroup[control: 0]
                expect(controlId0_0).toNot(beNil())
                expect(controlId0_0) == 100
                
                expect(massageGroup.gauge.foreground?.images.count) == 1
                expect(massageGroup.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/device_massage_chair_control_manual_on.png"
                expect(massageGroup.gauge.background).to(beNil())
                
                let heatGroup = chairPresentation.groups![2]
                expect(heatGroup.label) == "Heat"
                expect(heatGroup.controlIds?.count) == 1
                expect(heatGroup.controlIds?[0]) == 101
                expect(heatGroup.gauge.foreground?.images.count) == 1
                expect(heatGroup.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/device_massage_chair_control_heat_on.png"
                expect(heatGroup.gauge.background).to(beNil())

                let chairGroup = chairPresentation.groups![3]
                expect(chairGroup.label) == "Chair"
                expect(chairGroup.controlIds?.count) == 1
                expect(chairGroup.controlIds?[0]) == 102
                expect(chairGroup.gauge.foreground?.images.count) == 1
                expect(chairGroup.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/device_massage_chair_control_recline_on.png"
                expect(chairGroup.gauge.background).to(beNil())
                
                let ottomanGroup = chairPresentation.groups![4]
                expect(ottomanGroup.label) == "Ottoman"
                expect(ottomanGroup.controlIds?.count) == 1
                expect(ottomanGroup.controlIds?[0]) == 103
                expect(ottomanGroup.gauge.foreground?.images.count) == 1
                expect(ottomanGroup.gauge.foreground?.images[0].URI) == "http://tonyhacks.com/icons/3x/controls/device_massage_chair_control_footrest_on.png"
                expect(ottomanGroup.gauge.background).to(beNil())
                
                let controls = chairPresentation.controls
                expect(controls).toNot(beNil())
                expect(controls?.count) == 5

                // Style Control
                
                let menuControl200 = controls?[1]
                expect(menuControl200?.id) == 100
                expect(menuControl200?.type) == "menuControl"
                
                let menuControl200Attribute = chairPresentation.attributeOptions[menuControl200!.attributeMap!["value"]!]
                expect(menuControl200Attribute).toNot(beNil())
                expect(menuControl200Attribute!.valueOptions.count) == 7
                
                let menuControl200OptionOff = menuControl200Attribute!.valueOptions[0]
                expect(menuControl200OptionOff.match) == "0"
                expect(menuControl200OptionOff.apply.count) == 1
                expect(menuControl200OptionOff.apply["label"] as? String) == "Off"
                
                let menuControl200OptionSwedish = menuControl200Attribute!.valueOptions[1]
                expect(menuControl200OptionSwedish.match) == "1"
                expect(menuControl200OptionSwedish.apply.count) == 1
                expect(menuControl200OptionSwedish.apply["label"] as? String) == "Swedish"

                let menuControl200OptionDeep = menuControl200Attribute!.valueOptions[2]
                expect(menuControl200OptionDeep.match) == "2"
                expect(menuControl200OptionDeep.apply.count) == 1
                expect(menuControl200OptionDeep.apply["label"] as? String) == "Deep"
                
                let menuControl200OptionShiatsu = menuControl200Attribute!.valueOptions[3]
                expect(menuControl200OptionShiatsu.match) == "3"
                expect(menuControl200OptionShiatsu.apply.count) == 1
                expect(menuControl200OptionShiatsu.apply["label"] as? String) == "Shiatsu"
                
                let menuControl200OptionStretch = menuControl200Attribute!.valueOptions[4]
                expect(menuControl200OptionStretch.match) == "4"
                expect(menuControl200OptionStretch.apply.count) == 1
                expect(menuControl200OptionStretch.apply["label"] as? String) == "Stretch"
                
                let menuControl200OptionNeckShoulder = menuControl200Attribute!.valueOptions[5]
                expect(menuControl200OptionNeckShoulder.match) == "5"
                expect(menuControl200OptionNeckShoulder.apply.count) == 1
                expect(menuControl200OptionNeckShoulder.apply["label"] as? String) == "Neck/Shoulder"
                
                let menuControl200OptionLowerBack = menuControl200Attribute!.valueOptions[6]
                expect(menuControl200OptionLowerBack.match) == "6"
                expect(menuControl200OptionLowerBack.apply.count) == 1
                expect(menuControl200OptionLowerBack.apply["label"] as? String) == "Lower Back"
                
                // On/Off control
                
                let menuControl100 = controls?[0]
                expect(menuControl100?.id) == 99
                expect(menuControl100?.type) == "menuControl"
                
                let menuControl100Attribute = chairPresentation.attributeOptions[menuControl100!.attributeMap!["value"]!]
                expect(menuControl100Attribute).toNot(beNil())
                expect(menuControl100Attribute!.valueOptions.count) == 2
                
                
                let  menuControl100OptionOn = menuControl100Attribute!.valueOptions[0]
                expect(menuControl100OptionOn.match) == "0"
                expect(menuControl100OptionOn.apply.count) == 1
                expect(menuControl100OptionOn.apply["label"] as? String) == "Off"

                let menuControl100OptionOff = menuControl100Attribute!.valueOptions[1]
                expect(menuControl100OptionOff.match) == "1"
                expect(menuControl100OptionOff.apply.count) == 1
                expect(menuControl100OptionOff.apply["label"] as? String) == "On"
                
                // Up/Down control
                
                let menuControl101 = controls?[2]
                expect(menuControl101?.id) == 101
                expect(menuControl101?.type) == "menuControl"
                
                let menuControl101Attribute = chairPresentation.attributeOptions[menuControl101!.attributeMap!["value"]!]
                expect(menuControl101Attribute).toNot(beNil())
                expect(menuControl101Attribute!.valueOptions.count) == 2
                
                let menuControl101OptionUp = menuControl101Attribute!.valueOptions[0]
                expect(menuControl101OptionUp.match) == "0"
                expect(menuControl101OptionUp.apply.count) == 1
                expect(menuControl101OptionUp.apply["label"] as? String) == "Off"
                
                let menuControl101OptionDown = menuControl101Attribute!.valueOptions[1]
                expect(menuControl101OptionDown.match) == "1"
                expect(menuControl101OptionDown.apply.count) == 1
                expect(menuControl101OptionDown.apply["label"] as? String) == "On"
                
            }

            it("should produce a gauge displayRulesProcessor") {
                
                let attributes = AttributeMap(
                    [
                        100: "String",
                        200: 200,
                        300: false
                    ]
                )
                
                let process: AttributeProcessor = chairPresentation.gauge.displayRulesProcessor(initial)
                
                let result = process(attributes)
                
                expect(result.count) == 3
                expect(result["hi"] as? String) == "there"
                expect(result["intArray"] as? [Int]) == [1, 2, 3]
                
                let resultAnotherDict = result["anotherDict"] as? [Int: String]
                
                expect(resultAnotherDict).toNot(beNil())
                expect(resultAnotherDict?[1]) == "one"
                expect(resultAnotherDict?[2]) == "two"
                expect(resultAnotherDict?[3]) == "three"
                
            }
            
            it("should produce a gauge displayRulesProcessor") {
                
                let attributes = AttributeMap(
                    [
                        100: "String",
                        200: 200,
                        300: false
                    ]
                )
                
                let process: AttributeProcessor = chairPresentation.gauge.displayRulesProcessor(initial)
                
                let result = process(attributes)
                
                expect(result.count) == 3
                expect(result["hi"] as? String) == "there"
                expect(result["intArray"] as? [Int]) == [1, 2, 3]
                
                let resultAnotherDict = result["anotherDict"] as? [Int: String]
                
                expect(resultAnotherDict).toNot(beNil())
                expect(resultAnotherDict?[1]) == "one"
                expect(resultAnotherDict?[2]) == "two"
                expect(resultAnotherDict?[3]) == "three"
                
            }
            
            it("should produce a displayRulesProcesssor for the style control") {
                
                let attributes = AttributeMap(
                    [
                        100: "String",
                        200: 200,
                        300: false
                    ]
                )
                
                let process: AttributeProcessor? = chairPresentation.controls?[0].displayRulesProcessor(initial)
                expect(process).toNot(beNil())
                let result = process!(attributes)
                
                expect(result.count) == 3
                expect(result["hi"] as? String) == "there"
                expect(result["intArray"] as? [Int]) == [1, 2, 3]
                
                let resultAnotherDict = result["anotherDict"] as? [Int: String]
                
                expect(resultAnotherDict).toNot(beNil())
                expect(resultAnotherDict?[1]) == "one"
                expect(resultAnotherDict?[2]) == "two"
                expect(resultAnotherDict?[3]) == "three"
                
            }
        }
    }
}

class DeviceProfileTests: XCTestCase {

    var profile: DeviceProfile?
    
    override func setUp() {
        super.setUp()
        
        if let json = try? ResourceUtils.readJson("profileTest", bundle: Bundle(for: classForCoder)) {
            profile = |<json
        }

//        if let path = NSBundle(forClass: self.classForCoder).pathForResource("profileTest", ofType: "json") {
//            if let jsonData = NSData(contentsOfFile:path, options: .DataReadingMappedIfSafe) {
//                var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary
//
//                self.profile = |<(jsonResult as? [String: Any])
//            }
//        }
    }

    override func tearDown() {
        self.profile = nil
        super.tearDown()
    }

    func testProfile() {
        XCTAssert(self.profile != nil, "profile != nil")
        let profile = self.profile!

        XCTAssert(profile.id == "10d18297-ba51-438f-b387-45a1e88e2242", "profile.id == '10d18297-ba51-438f-b387-45a1e88e2242'")

        // services
        XCTAssert(profile.services.count == 3, "profile.services.count == 3")

        let service100: DeviceProfile.Service = profile.services[0]
        XCTAssert(service100.attributes.count == 3, "service100.attributes.count == 3")
        XCTAssert(service100.id == 100, "service100.id == 100")

        let service200: DeviceProfile.Service = profile.services[1]
        XCTAssert(service200.attributes.count == 1, "service200.attributes.count == 1")
        XCTAssert(service200.id == 200, "service200.id == 200")

        let service300: DeviceProfile.Service = profile.services[2]
        XCTAssert(service300.attributes.count == 10, "service300.attributes.count == 10")
        XCTAssert(service300.id == 300, "service300.id == 300")


        // attribute 100
        let attribute100: DeviceProfile.AttributeDescriptor = service100.attributes[0]
        XCTAssert(attribute100.id == 100, "attribute100.id == 100")
        XCTAssert(attribute100.dataType == DeviceProfile.AttributeDescriptor.DataType.uInt8, "attribute100.dataType == DeviceProfile.AttributeDescriptor.DataType.UInt8")

        // attribute 200
        let attribute200: DeviceProfile.AttributeDescriptor = service200.attributes[0]
        XCTAssert(attribute200.id == 200, "attribute200.id == 200")
        XCTAssert(attribute200.dataType == DeviceProfile.AttributeDescriptor.DataType.uInt8, "attribute200.dataType == DeviceProfile.AttributeDescriptor.DataType.UInt8")
        XCTAssert(attribute200.semanticType == "power", "attribute200.semanticType == 'power'")

        // test the dataTypes for all attributes in service300
        struct AttributeTest {
            var id: Int
            var dataType: DeviceProfile.AttributeDescriptor.DataType
        }
        var attributeTests: [AttributeTest] = [
                AttributeTest(id: 300, dataType: DeviceProfile.AttributeDescriptor.DataType.unknown),
                AttributeTest(id: 301, dataType: DeviceProfile.AttributeDescriptor.DataType.uInt8),
                AttributeTest(id: 302, dataType: DeviceProfile.AttributeDescriptor.DataType.uInt16),
                AttributeTest(id: 303, dataType: DeviceProfile.AttributeDescriptor.DataType.uInt32),
                AttributeTest(id: 304, dataType: DeviceProfile.AttributeDescriptor.DataType.sInt8),
                AttributeTest(id: 305, dataType: DeviceProfile.AttributeDescriptor.DataType.sInt16),
                AttributeTest(id: 306, dataType: DeviceProfile.AttributeDescriptor.DataType.sInt32),
                AttributeTest(id: 307, dataType: DeviceProfile.AttributeDescriptor.DataType.float32),
                AttributeTest(id: 308, dataType: DeviceProfile.AttributeDescriptor.DataType.float64),
                AttributeTest(id: 309, dataType: DeviceProfile.AttributeDescriptor.DataType.utf8S),
            ]
        var testIndex: Int = 0

        for attribute300 in service300.attributes {
            let attrTest = attributeTests[testIndex]
            testIndex += 1
            XCTAssert(attribute300.id == attrTest.id, "attribute\(attribute300.id).id == \(attrTest.id)")
            XCTAssert(attribute300.dataType == attrTest.dataType, "attribute\(attribute300.id).dataType(\(attribute300.dataType.rawValue)) == \(attrTest.dataType.rawValue)")
        }

    }
}

