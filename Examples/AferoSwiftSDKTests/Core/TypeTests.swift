//
//  TypeTests.swift
//  iTokui
//
//  Created by Justin Middleton on 5/31/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import UIKit
import Quick
import Nimble
@testable import Afero

class QNumberSpec: QuickSpec {

    override func spec() {
        
        describe("When handling Q values") {
            
            it("should handle Q1516es") {
                
                let f = 0.2625
                let q: Int32 = doubleToQ(f, n: 16)
                
                expect(q) == 17203
                
                let f2 = qToDouble(q, n: 16)
                
                expect(f2).to(beCloseTo(f, within: 0.00005))
            }
            
            it("should roundtrip through arrays") {
                
                let bytes: [UInt8] = [
                    0x33,
                    0x43,
                    0x00,
                    0x00,
                ]
                
                let d = qToDouble(bytes, n: 16, t: Int32.self)
                expect(d).to(beCloseTo(0.2625, within: 0.00005))
            }
        }
        
    }
}

// MARK: String

class AttributeValueStringSpec: QuickSpec {
    
    override func spec() {
        
        describe("When initializing from a hex string") {
            
            it("Should return an AttributeValue.UTFS8 when passed a string context") {
                
                // TODO check invalide UTF8 encodings return nil.
                
                let stringValue = "Kiban"
                let value = AttributeValue.utf8S(stringValue)
                expect(value.byteArray) == [ 0x4B, 0x69, 0x62, 0x61, 0x6E ]
                expect(value) == AttributeValue.utf8S("Kiban")
                expect("Kiban") == value.suited()
            }
        }
    }
}

// MARK: Boolean

class AttributeValueBoolSpec: QuickSpec {

    override func spec() {
        
        describe("When initializing from a value string") {

            it("Should return an AttributeValue.Boolean when passed a Boolean context.") {
                
                if let value = AttributeValue(type: .boolean, value: "true") {
                    expect(value.byteArray) == [ 0x01 ]
                    expect(value) == AttributeValue.boolean(true)
                } else {
                    fail("Expected value to not be nil")
                }
                
                if let value = AttributeValue(type: .boolean, value: "false") {
                    
                    expect(value.byteArray) == [ 0x00 ]
                    expect(value) == AttributeValue.boolean(false)
                    
                } else {
                    fail("Expected value to not be nil")
                }
            }
        }
        
    }
}

// MARK: 8-Bit Ints

class AttributeValueIntSpec: QuickSpec {

    override func spec() {
        
        describe("When initializing with explicit types") {
            
            describe("as an Int8") {
                
                it("Should return an AttributeValue.SignedInt8 when passed an Int8 (signed) context.") {
                    
                    guard let value0 = AttributeValue(type: .sInt8, value: "0") else {
                        fail("Expected value to not be nil")
                        return
                    }
                    
                    expect(value0.byteArray) == [ 0x00 ]
                    expect(value0) == AttributeValue.signedInt8(0)
                    expect(Int(0)) == value0.suited()
                    
                    guard let value1 = AttributeValue(type: .sInt8, value: "-1") else {
                        fail("Expected value to not be nil")
                        return
                    }
                    
                    expect(value1.byteArray) == [ 0xFF ]
                    expect(value1) == AttributeValue.signedInt8(-1)
                    expect(Int(-1)) == value1.suited()
                }
                
                it("Should correctly instantiate from Int8.max") {
                    
                    guard let value = AttributeValue(type: .sInt8, value: "\(Int8.max)") else {
                        fail("Failed to instantiate from Int8.max(\(Int8.max))")
                        return
                    }
                    
                    expect(value.int8Value) == Int8.max
                    expect(value.int16Value) == Int16(Int8.max)
                    expect(value.int32Value) == Int32(Int8.max)
                    expect(value.int64Value) == Int64(Int8.max)
                    expect(value.stringValue) == "\(Int8.max)"
                    expect(value.boolValue).to(beTrue())
                    expect(value.number) == NSDecimalNumber(value: Int8.max)
                }
                
                it("Should correctly instantiate from Int8.min") {
                    
                    guard let value = AttributeValue(type: .sInt8, value: "\(Int8.min)") else {
                        fail("Failed to instantiate from Int8.max(\(Int8.min))")
                        return
                    }
                    
                    expect(value.int8Value) == Int8.min
                    expect(value.int16Value) == Int16(Int8.min)
                    expect(value.int32Value) == Int32(Int8.min)
                    expect(value.int64Value) == Int64(Int8.min)
                    expect(value.stringValue) == "\(Int8.min)"
                    expect(value.boolValue).to(beTrue())
                    expect(value.number) == NSDecimalNumber(value: Int8.min)
                }
                
                it("Should fail to instantiate from ((Int8.max + n), (Int8.min - n) ∀ n > 0))") {
                    expect(AttributeValue(type: .sInt8, value: "\(Int(Int8.max) + 1)")).to(beNil())
                    expect(AttributeValue(type: .sInt8, value: "\(Int(Int8.min) - 1)")).to(beNil())
                }
                
            }
            
        }

        describe("as an Int16") {
            
            it("Should return an AttributeValue.SignedInt16 when passed an Int16 (signed) context.") {
                
                guard let value0 = AttributeValue(type: .sInt16, value: "0") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value0.byteArray) == [ 0x00, 0x00 ]
                expect(value0) == AttributeValue.signedInt16(0)
                expect(Int(0)) == value0.suited()
                
                guard let value1 = AttributeValue(type: .sInt16, value: "-1") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value1.byteArray) == [ 0xFF, 0xFF ]
                expect(value1) == AttributeValue.signedInt16(-1)
                expect(Int(-1)) == value1.suited()
            }
            
            it("Should correctly instantiate from Int16.max") {
                
                guard let value = AttributeValue(type: .sInt16, value: "\(Int16.max)") else {
                    fail("Failed to instantiate from Int16.max(\(Int16.max))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value) == Int16.max
                expect(value.int32Value) == Int32(Int16.max)
                expect(value.int64Value) == Int64(Int16.max)
                expect(value.stringValue) == "\(Int16.max)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int16.max)
            }
            
            it("Should correctly instantiate from Int16.min") {
                
                guard let value = AttributeValue(type: .sInt16, value: "\(Int16.min)") else {
                    fail("Failed to instantiate from Int16.max(\(Int16.min))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value) == Int16.min
                expect(value.int32Value) == Int32(Int16.min)
                expect(value.int64Value) == Int64(Int16.min)
                expect(value.stringValue) == "\(Int16.min)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int16.min)
            }
            
            it("Should fail to instantiate from ((Int16.max + n), (Int16.min - n) ∀ n > 0))") {
                expect(AttributeValue(type: .sInt16, value: "\(Int(Int16.max) + 1)")).to(beNil())
                expect(AttributeValue(type: .sInt16, value: "\(Int(Int16.min) - 1)")).to(beNil())
            }
            
        }

        describe("as an Int32") {
            
            it("Should return an AttributeValue.SignedInt32 when passed an Int32 (signed) context.") {
                
                guard let value0 = AttributeValue(type: .sInt32, value: "0") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value0.byteArray) == [ 0x00, 0x00, 0x00, 0x00 ]
                expect(value0) == AttributeValue.signedInt32(0)
                expect(Int(0)) == value0.suited()
                
                guard let value1 = AttributeValue(type: .sInt32, value: "-1") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value1.byteArray) == [ 0xFF, 0xFF, 0xFF, 0xFF ]
                expect(value1) == AttributeValue.signedInt32(-1)
                expect(Int(-1)) == value1.suited()
            }
            
            it("Should correctly instantiate from Int32.max") {
                
                guard let value = AttributeValue(type: .sInt32, value: "\(Int32.max)") else {
                    fail("Failed to instantiate from Int32.max(\(Int32.max))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value).to(beNil())
                expect(value.int32Value) == Int32.max
                expect(value.int64Value) == Int64(Int32.max)
                expect(value.stringValue) == "\(Int32.max)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int32.max)
            }
            
            it("Should correctly instantiate from Int32.min") {
                
                guard let value = AttributeValue(type: .sInt32, value: "\(Int32.min)") else {
                    fail("Failed to instantiate from Int32.max(\(Int32.min))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value).to(beNil())
                expect(value.int32Value) == Int32.min
                expect(value.int64Value) == Int64(Int32.min)
                expect(value.stringValue) == "\(Int32.min)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int32.min)
            }
            
            it("Should fail to instantiate from ((Int32.max + n), (Int32.min - n) ∀ n > 0))") {
                expect(AttributeValue(type: .sInt32, value: "2147483648")).to(beNil())
                expect(AttributeValue(type: .sInt32, value: "-2147483649)")).to(beNil())
            }
            
        }

        describe("as an Int64") {
            
            it("Should return an AttributeValue.SignedInt64 when passed an Int64 (signed) context.") {
                
                guard let value0 = AttributeValue(type: .sInt64, value: "0") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value0.byteArray) == [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ]
                expect(value0) == AttributeValue.signedInt64(0)
                expect(Int(0)) == value0.suited()
                
                guard let value1 = AttributeValue(type: .sInt64, value: "-1") else {
                    fail("Expected value to not be nil")
                    return
                }
                
                expect(value1.byteArray) == [ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF ]
                expect(value1) == AttributeValue.signedInt64(-1)
                expect(Int(-1)) == value1.suited()
            }
            
            it("Should correctly instantiate from Int64.max") {
                
                guard let value = AttributeValue(type: .sInt64, value: "\(Int64.max)") else {
                    fail("Failed to instantiate from Int64.max(\(Int64.max))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value).to(beNil())
                expect(value.int32Value).to(beNil())
                expect(value.int64Value) == Int64.max
                expect(value.stringValue) == "\(Int64.max)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int64.max)
            }
            
            it("Should correctly instantiate from Int64.min") {
                
                guard let value = AttributeValue(type: .sInt64, value: "\(Int64.min)") else {
                    fail("Failed to instantiate from Int64.max(\(Int64.min))")
                    return
                }
                
                expect(value.int8Value).to(beNil())
                expect(value.int16Value).to(beNil())
                expect(value.int32Value).to(beNil())
                expect(value.int64Value) == Int64.min
                expect(value.stringValue) == "\(Int64.min)"
                expect(value.boolValue).to(beTrue())
                expect(value.number) == NSDecimalNumber(value: Int64.min)
            }
            
            it("Should fail to instantiate from ((Int64.max + n), (Int64.min - n) ∀ n > 0))") {
                expect(AttributeValue(type: .sInt64, value: "9223372036854775808")).to(beNil())
                expect(AttributeValue(type: .sInt64, value: "-9223372036854775809")).to(beNil())
            }
            
        }

    }
}


class AttributeValueGeneralSpec: QuickSpec {

    override func spec() {

        describe("When initializing with nil native optional types") {
            
            it("Should return nil if initialized from a nil value") {
                expect(AttributeValue(nil as [UInt8]?)).to(beNil())
                expect(AttributeValue(nil as Bool?)).to(beNil())
                expect(AttributeValue(nil as UInt8?)).to(beNil())
                expect(AttributeValue(nil as UInt16?)).to(beNil())
                expect(AttributeValue(nil as UInt32?)).to(beNil())
                expect(AttributeValue(nil as UInt?)).to(beNil())
                expect(AttributeValue(nil as Int8?)).to(beNil())
                expect(AttributeValue(nil as Int16?)).to(beNil())
                expect(AttributeValue(nil as Int32?)).to(beNil())
                expect(AttributeValue(nil as Int?)).to(beNil())
                expect(AttributeValue(nil as Float?)).to(beNil())
                expect(AttributeValue(nil as Double?)).to(beNil())
                expect(AttributeValue(nil as String?)).to(beNil())
            }

        }
    }
}

class AttributeValueFixedSpec: QuickSpec {

    override func spec() {
        
        describe("Q3132") {
            
            it("Should initialize with a double") {
                
                let d1: Double = 2.2
                let av1 = AttributeValue.q1516(d1)
                expect(av1) == AttributeValue.q1516(2.2)
                expect(av1.doubleValue) == d1
                
            }
            
            it("Should initialize with a string") {
                
                let av1 = AttributeValue(type: .q1516, value: "25.25")
                expect(av1) == AttributeValue.q1516(25.25)
                expect(av1?.stringValue) == "25.25"
            }
        }
        
        describe("Q1516") {

            it("Should initialize") {
                
                let d1: Double = 25.25
                let av1 = AttributeValue.q3132(d1)
                expect(av1) == AttributeValue.q3132(25.25)
                expect(av1.doubleValue) == d1
                
            }

            it("Should initialize with a string") {
                
                let av1 = AttributeValue(type: .q3132, value: "25.25")
                expect(av1) == AttributeValue.q3132(25.25)
                expect(av1?.stringValue) == "25.25"
            }

        }
    }
}


class AttributeValueComparisonSpec: QuickSpec {
    override func spec() {

        describe("When comparing bools") {
            
            it("Should check equality and relative value correctly.") {
                let f: AttributeValue = false
                let t: AttributeValue = true
                
                expect(f) == f
                expect(f) != t
                
                expect(t) == t
                expect(t) != f
                
                expect(f).to(beLessThan(t))
                expect(t).to(beGreaterThan(f))
            }
        }
        
        describe("When comparing ints") {
            
            it("Should check equality and relative value correctly.") {
                let minusOne: AttributeValue = -1
                let zero: AttributeValue = 0
                let one: AttributeValue = 1
                let two: AttributeValue = 2
                
                expect(minusOne) == minusOne
                expect(minusOne) != zero
                expect(minusOne) != one
                expect(minusOne) != two
                
                expect(minusOne).to(beLessThan(zero))
                expect(minusOne).to(beLessThan(one))
                expect(minusOne).to(beLessThan(two))
                
                expect(zero) == zero
                expect(zero) != minusOne
                expect(zero) != one
                expect(zero) != two
                
                expect(zero).to(beGreaterThan(minusOne))
                expect(zero).to(beLessThan(one))
                expect(zero).to(beLessThan(two))
                
                expect(one) == one
                expect(one) != two
                expect(one).to(beGreaterThan(minusOne))
                expect(one).to(beGreaterThan(zero))
                expect(one).to(beLessThan(two))
                
                expect(two) == two
                expect(two) != one
                
                expect(two).to(beGreaterThan(minusOne))
                expect(two).to(beGreaterThan(zero))
                expect(two).to(beGreaterThan(one))
            }
        }
        
        describe("When comparing floats") {
            
            it("Should check equality and relative value correctly.") {
                let minusOne: AttributeValue = AttributeValue(Float(-1.0))!
                let zero: AttributeValue = AttributeValue(Float(0.0))!
                let two_two: AttributeValue = AttributeValue(Float(2.2))!
                let two_two_oh_oh_oh: AttributeValue = AttributeValue(Float(2.20001))!
                
                expect(minusOne) == minusOne
                expect(minusOne) != zero
                expect(minusOne) != two_two_oh_oh_oh
                expect(minusOne) != two_two
                
                expect(minusOne).to(beLessThan(zero))
                expect(minusOne).to(beLessThan(two_two_oh_oh_oh))
                expect(minusOne).to(beLessThan(two_two))
                
                expect(zero) == zero
                expect(zero) != minusOne
                expect(zero) != two_two_oh_oh_oh
                expect(zero) != two_two
                
                expect(zero).to(beGreaterThan(minusOne))
                expect(zero).to(beLessThan(two_two_oh_oh_oh))
                expect(zero).to(beLessThan(two_two))
                
                expect(two_two_oh_oh_oh) == two_two_oh_oh_oh
                expect(two_two_oh_oh_oh) != two_two
                expect(two_two_oh_oh_oh).to(beGreaterThan(minusOne))
                expect(two_two_oh_oh_oh).to(beGreaterThan(zero))
                expect(two_two_oh_oh_oh).to(beGreaterThan(two_two))
                
                expect(two_two) == two_two
                expect(two_two) != two_two_oh_oh_oh
                
                expect(two_two).to(beGreaterThan(minusOne))
                expect(two_two).to(beGreaterThan(zero))
                expect(two_two).to(beLessThan(two_two_oh_oh_oh))
            }
        }
        
        describe("When comparing doubles") {

            it("Should check equality and relative value correctly.") {
                let minusOne: AttributeValue = -1.0
                let zero: AttributeValue = 0.0
                let two_two: AttributeValue = 2.2
                let two_two_oh_oh_oh: AttributeValue = 2.200001
                
                expect(minusOne) == minusOne
                expect(minusOne) != zero
                expect(minusOne) != two_two_oh_oh_oh
                expect(minusOne) != two_two
                
                expect(minusOne).to(beLessThan(zero))
                expect(minusOne).to(beLessThan(two_two_oh_oh_oh))
                expect(minusOne).to(beLessThan(two_two))
                
                expect(zero) == zero
                expect(zero) != minusOne
                expect(zero) != two_two_oh_oh_oh
                expect(zero) != two_two
                
                expect(zero).to(beGreaterThan(minusOne))
                expect(zero).to(beLessThan(two_two_oh_oh_oh))
                expect(zero).to(beLessThan(two_two))
                
                expect(two_two_oh_oh_oh) == two_two_oh_oh_oh
                expect(two_two_oh_oh_oh) != two_two
                expect(two_two_oh_oh_oh).to(beGreaterThan(minusOne))
                expect(two_two_oh_oh_oh).to(beGreaterThan(zero))
                expect(two_two_oh_oh_oh).to(beGreaterThan(two_two))
                
                expect(two_two) == two_two
                expect(two_two) != two_two_oh_oh_oh
                
                expect(two_two).to(beGreaterThan(minusOne))
                expect(two_two).to(beGreaterThan(zero))
                expect(two_two).to(beLessThan(two_two_oh_oh_oh))
            }
        }
        
        describe("When comparing strings") {
            
            it("Should check equality and relative value correctly.") {
                let apple: AttributeValue = "apple"
                let banana: AttributeValue = "banana"
                let orange: AttributeValue = "orange"
                
                expect(apple) == apple
                expect(apple) != banana
                expect(apple) != orange
                
                expect(apple).toNot(beLessThan(apple))
                expect(apple).to(beLessThan(banana))
                expect(apple).to(beLessThan(orange))
                
                expect(banana) == banana
                expect(banana) != apple
                expect(banana) != orange

                expect(banana).toNot(beLessThan(banana))
                expect(banana).to(beGreaterThan(apple))
                expect(banana).to(beLessThan(orange))

                expect(orange) == orange
                expect(orange) != apple
                expect(orange) != banana

                expect(orange).toNot(beLessThan(orange))
                expect(orange).to(beGreaterThan(apple))
                expect(orange).to(beGreaterThan(banana))
            }
        }
        
        describe("When comparing byte arrays") {
            
        }
    }
}
