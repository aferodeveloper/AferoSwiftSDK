//
//  DisplayRulesTests.swift
//  iTokui
//
//  Created by Justin Middleton on 5/28/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation
@testable import Afero
import Quick
import Nimble

class PerContextDisplayRulesSpec: QuickSpec {
    
    override func spec() {
        describe("When applying to a 'context'") {
            
            let rules2Json: [[String: Any]]! = (try! self.fixture(named: "displayRulesTest2"))!
            
            it("Should do some awesome stuff.") {
                
                let defaults: [String: Any] = ["default_hi": "default_there"]
                
                let process: (AttributeMap?)->[String: Any] = DisplayRulesProcessor.MakeProcessor(
                    defaults,
                    rules: rules2Json,
                    operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
                    integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue }
                )
                
                let atts = AttributeMap([
                    100: 99,
                    200: 16,
                    300: "Hi Joe!",
                    400: 100,
                    ])
                
                let result = process(atts)
                
                expect(result["default_hi"] as? String) == "default_there"   // From defaults
                expect(result["barColor"] as? String) == "#FFFF00"           // Because 200 is 16...35
                expect(result["hint"] as? String) == "Sufficient Charge"     // Because 100 is 16...99
                expect(result["sounds"] as? [String]) == ["quack", "moof", "I fart in your general direction."] // Because 200 is 16...35
            }
        }
    }
}

class PerAttributeDisplayRulesSpec: QuickSpec {
    
    override func spec() {
        
        let rules1Json: [[String: Any]]! = (try! self.fixture(named: "displayRulesTest1"))!

        describe("When applying to an integer attribute") {

            let defaults: [String: Any] = ["hi": "there"]
            let intProcessor = DisplayRulesProcessor.MakeProcessor(
                defaults,
                rules: rules1Json,
                operandXform: { (oper: String) -> Int in return oper.intValue! },
                integerOptionalXform: { (oper: Int) -> Int? in return oper }
            )
            
            it("Should populate barColor and hintColor for ALL values") {
                for i in -20...500 {
                    let result = intProcessor(i)
                    expect(result["hint"]).toNot(beNil())
                    expect(result["barColor"]).toNot(beNil())
                    expect(result["hi"] as? String) == "there"
                }
            }
            
            it("Values 16 through 35, inclusive, should have a sounds key; outside of this range, should be empty") {
                for i in -20...500 {
                    let result = intProcessor(i)
                    expect(result["hint"]).toNot(beNil())
                    expect(result["barColor"]).toNot(beNil())
                    expect(result["hi"] as? String) == "there"

                    
                    if (i >= 16) && (i <= 35) {
                        expect(result["sounds"] as? [String]).toNot(beNil())
                        if let sounds = result["sounds"] as? [String] {
                            expect(sounds.count) == 3
                        }
                    } else {
                        expect(result["sounds"]).to(beNil())
                    }
                }
                
            }
            
            it("Should properly handle 22.") {
                let result = intProcessor(22)
                
                expect(result["also"] as? String) == "2-bit set and betwen 3 and 12 (inclusive), or between 20 and 30(inclusive)"
                expect(result["hint"] as? String) == "Sufficient Charge"
                expect(result["barColor"] as? String) == "#FFFF00"
            }

        }
        
        describe("When applying to an float attribute") {
            
            let defaults = ["hi": "there"]
            let floatProcessor = DisplayRulesProcessor.MakeProcessor(
                defaults,
                rules: rules1Json,
                operandXform: { (oper: String) -> Double in return (oper as NSString).doubleValue },
                integerOptionalXform: { (oper: Double) -> Int? in return Int(oper) }
            )
            
            it("Should populate barColor and hintColor for ALL values") {
                for i in stride(from: -20.0, to: 150.0, by: 0.75) {
                    let result = floatProcessor(i)
                    expect(result["hint"]).toNot(beNil())
                    expect(result["barColor"]).toNot(beNil())
                    expect(result["hi"] as? String) == "there"
                }
            }
            
            it("Values 16 through 35, inclusive, should have a sounds key; outside of this range, should be empty") {
                for i in stride(from: -20.0, to: 150.0, by: 0.75) {
                    let result = floatProcessor(i)
                    
                    expect(result["hint"]).toNot(beNil())
                    expect(result["barColor"]).toNot(beNil())
                    expect(result["hi"] as? String) == "there"

                    
                    if (i >= 16) && (i <= 35) {
                        expect(result["sounds"] as? [String]).toNot(beNil())
                        if let sounds = result["sounds"] as? [String] {
                            expect(sounds.count) == 3
                        }
                    } else {
                        expect(result["sounds"]).to(beNil())
                    }
                }
                
            }
            
            it("Should properly handle 22.") {
                let result = floatProcessor(22.0)
                
                expect(result["also"] as? String) == "2-bit set and betwen 3 and 12 (inclusive), or between 20 and 30(inclusive)"
                expect(result["hint"] as? String) == "Sufficient Charge"
                expect(result["barColor"] as? String) == "#FFFF00"
                expect(result["hi"] as? String) == "there"

            }
            
        }

    }
}
