//
//  AttributeCollectionTests.swift
//  AferoTests
//
//  Created by Justin Middleton on 1/10/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation

import Quick
import Nimble

@testable import Afero

class AferoAttributeDataTypeSpec: QuickSpec {
    
    override func spec() {
        
        describe("initializing") {
            
            it("should initialize with known string values") {
                expect(AferoAttributeDataType(name: AferoAttributeDataType.boolean.stringValue)) == AferoAttributeDataType.boolean
                expect(AferoAttributeDataType(name: AferoAttributeDataType.sInt8.stringValue)) == AferoAttributeDataType.sInt8
                expect(AferoAttributeDataType(name: AferoAttributeDataType.sInt16.stringValue)) == AferoAttributeDataType.sInt16
                expect(AferoAttributeDataType(name: AferoAttributeDataType.sInt32.stringValue)) == AferoAttributeDataType.sInt32
                expect(AferoAttributeDataType(name: AferoAttributeDataType.sInt64.stringValue)) == AferoAttributeDataType.sInt64
                expect(AferoAttributeDataType(name: AferoAttributeDataType.q1516.stringValue)) == AferoAttributeDataType.q1516
                expect(AferoAttributeDataType(name: AferoAttributeDataType.q3132.stringValue)) == AferoAttributeDataType.q3132
                expect(AferoAttributeDataType(name: AferoAttributeDataType.utf8S.stringValue)) == AferoAttributeDataType.utf8S
                expect(AferoAttributeDataType(name: AferoAttributeDataType.bytes.stringValue)) == AferoAttributeDataType.bytes
            }
            
            it("should honor deprecated names") {
                expect(AferoAttributeDataType(name: "fixed_16_16")) == AferoAttributeDataType.q1516
                expect(AferoAttributeDataType(name: "fixed_32_32")) == AferoAttributeDataType.q3132
            }
            
            it("should return 'unknown' for everything else") {
                expect(AferoAttributeDataType(name: "unknown")) == AferoAttributeDataType.unknown
                expect(AferoAttributeDataType(name: "foo")) == AferoAttributeDataType.unknown
            }
            
        }
        
        describe("sizing") {
            
            expect(AferoAttributeDataType.boolean.size) == MemoryLayout<Bool>.size
            expect(AferoAttributeDataType.sInt8.size) == MemoryLayout<Int8>.size
            expect(AferoAttributeDataType.sInt16.size) == MemoryLayout<Int16>.size
            expect(AferoAttributeDataType.sInt32.size) == MemoryLayout<Int32>.size
            expect(AferoAttributeDataType.sInt64.size) == MemoryLayout<Int64>.size
            expect(AferoAttributeDataType.q1516.size) == MemoryLayout<Int32>.size
            expect(AferoAttributeDataType.q3132.size) == MemoryLayout<Int64>.size

            expect(AferoAttributeDataType.bytes.size).to(beNil())
            expect(AferoAttributeDataType.utf8S.size).to(beNil())
            expect(AferoAttributeDataType.unknown.size).to(beNil())

        }
        
    }
    
}

class AferoAttributeOperationsSpec: QuickSpec {
    
    override func spec() {
        
        describe("initializing") {
            
            it("should initialize from operations") {
                expect(AferoAttributeOperations(.read)) == AferoAttributeOperations.Read
                expect(AferoAttributeOperations(.write)) == AferoAttributeOperations.Write
            }
            
            it("should initialize from raw values") {
                expect(AferoAttributeOperations(rawValue: AferoAttributeOperation.read.rawValue)) == AferoAttributeOperations.Read
                expect(AferoAttributeOperations(rawValue: AferoAttributeOperation.write.rawValue)) == AferoAttributeOperations.Write
                expect(AferoAttributeOperations(rawValue: AferoAttributeOperation.read.rawValue | AferoAttributeOperation.write.rawValue)) == [.Read, .Write]
                expect(AferoAttributeOperations(rawValue: 0)) == []
            }
            
            it("should initialize from option arrays") {
                let allOperations: AferoAttributeOperations = [.Read, .Write]
                expect(allOperations.contains(.Read)).to(beTrue())
                expect(allOperations.contains(.Write)).to(beTrue())
            }
            
            it("should contain expected values") {
                expect(AferoAttributeOperations.Read.contains(.Read)).to(beTrue())
                expect(AferoAttributeOperations.Read.contains(.Write)).to(beFalse())
                
                expect(AferoAttributeOperations.Write.contains(.Write)).to(beTrue())
                expect(AferoAttributeOperations.Write.contains(.Read)).to(beFalse())
            }
            
        }
        
        describe("equating") {

            let r1 = AferoAttributeOperations.Read.copy() as! AferoAttributeOperations
            let w1 = AferoAttributeOperations.Write.copy() as! AferoAttributeOperations
            let a1: AferoAttributeOperations = [.Read, .Write]
            let n1: AferoAttributeOperations = []

            it("should properly report simple comparisons.") {
                
                expect(AferoAttributeOperations.Read) == AferoAttributeOperations.Read
                expect(AferoAttributeOperations.Read) != AferoAttributeOperations.Write
                
                expect(AferoAttributeOperations.Write) == AferoAttributeOperations.Write
                expect(AferoAttributeOperations.Write) != AferoAttributeOperations.Read
            }
            
            it("should properly compare copies") {
                let r2 = r1.copy() as! AferoAttributeOperations
                expect(r2).toNot(be(r1))
                expect(r2) == r1
                
                let w2 = w1.copy() as! AferoAttributeOperations
                expect(w2).toNot(be(w1))
                expect(w2) == w1
            }
            
            it("should equate if two instances contain the same options.") {
                let readWriteWith7 = AferoAttributeOperations(rawValue: 7)
                expect(readWriteWith7) == a1
                expect(readWriteWith7) != w1
                expect(readWriteWith7) != r1
                expect(readWriteWith7) != n1

                let writeOnlyWith6 = AferoAttributeOperations(rawValue: 6)
                expect(writeOnlyWith6) == w1
                expect(writeOnlyWith6) != r1
                expect(writeOnlyWith6) != a1
                expect(writeOnlyWith6) != n1

                let readOnlyWith5 = AferoAttributeOperations(rawValue: 5)
                expect(readOnlyWith5) == r1
                expect(readOnlyWith5) != w1
                expect(readOnlyWith5) != a1
                expect(readOnlyWith5) != n1

                let nullSetWith8 = AferoAttributeOperations(rawValue: 8)
                expect(nullSetWith8) != r1
                expect(nullSetWith8) != w1
                expect(nullSetWith8) != a1
                expect(nullSetWith8) == n1
            }
            
        }
            
        describe("encoding and decoding using Codable") {
            
            it("should decode from json") {
                
                do {

                    let encoder = JSONEncoder()
                    let decoder = JSONDecoder()
                    
                    let decode: ([String]) throws -> AferoAttributeOperations? = {
                        stringArr in
                        let data = try encoder.encode(stringArr)
                        return try decoder.decode(AferoAttributeOperations.self, from: data)
                    }
                    
                    expect(try decode(["READ"])) == AferoAttributeOperations.Read
                    expect(try decode(["WRITE"])) == AferoAttributeOperations.Write
                    expect(try decode(["READ", "WRITE",])) == [.Read, .Write]
                    expect(try decode(["READ", "WRITE", "DELETE",])) == [.Read, .Write]
                    expect(try decode(["DELETE",])) == []
                    expect(try decode([])) == []

                } catch {
                    fail(error.localizedDescription)
                }
                
            }
        }
    }
}

class AferoAttributeDescriptorSpec: QuickSpec {
    
    override func spec() {

        let a = AferoAttributeDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
        let b = AferoAttributeDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
        let c = AferoAttributeDescriptor(id: 333, type: .sInt16, semanticType: "semantic333", key: "key333", defaultValue: "3", operations: [.Write])
        let d = AferoAttributeDescriptor(id: 444, type: .sInt32, semanticType: "semantic444", key: "key444", defaultValue: "4", operations: [])
        let e = AferoAttributeDescriptor(id: 555, type: .sInt64, semanticType: "semantic555", key: "key555", defaultValue: "5", operations: [.Read, .Write])
        let f = AferoAttributeDescriptor(id: 666, type: .q1516, semanticType: "semantic666", key: "key666", defaultValue: "6.6", operations: [.Write])
        let g = AferoAttributeDescriptor(id: 777, type: .q3132, semanticType: "semantic777", key: "key777", defaultValue: "7.7", operations: [.Read])
        let h = AferoAttributeDescriptor(id: 888, type: .utf8S, semanticType: "semantic888", key: "key888", defaultValue: "stringystring", operations: [])
        let i = AferoAttributeDescriptor(id: 999, type: .bytes, semanticType: nil, key: nil, defaultValue: nil, operations: [.Read, .Write])
        
        describe("coding") {
            
            it("should roundtrip") {
                do {
                    
                    let encoder = JSONEncoder()
                    let decoder = JSONDecoder()
                    
                    let roundtrip: (AferoAttributeDescriptor) throws -> AferoAttributeDescriptor = {
                        desc in
                        let data = try encoder.encode(desc)
                        return try decoder.decode(AferoAttributeDescriptor.self, from: data)
                    }
                    
                    expect(try roundtrip(a)) == a
                    expect(try roundtrip(b)) == b
                    expect(try roundtrip(c)) == c
                    expect(try roundtrip(d)) == d
                    expect(try roundtrip(e)) == e
                    expect(try roundtrip(f)) == f
                    expect(try roundtrip(g)) == g
                    expect(try roundtrip(h)) == h
                    expect(try roundtrip(i)) == i

                } catch {
                    fail(error.localizedDescription)
                }

            }
        }
        
        describe("copying and equating") {
            
            it("should equate as expected") {

                let a2 = a.copy() as! AferoAttributeDescriptor
                
                expect(a) == a2
                expect(a).toNot(beIdenticalTo(a2))
                
                expect(a) != b
                expect(a) != c
                expect(a) != d
                expect(a) != e
                expect(a) != g
                expect(a) != h
                expect(a) != i

                let b2 = b.copy() as! AferoAttributeDescriptor
                
                expect(b) == b2
                expect(b).toNot(beIdenticalTo(b2))
                
                expect(b) != a
                expect(b) != c
                expect(b) != d
                expect(b) != e
                expect(b) != f
                expect(b) != g
                expect(b) != h
                expect(b) != i

                let c2 = c.copy() as! AferoAttributeDescriptor
                
                expect(c) == c2
                expect(c).toNot(beIdenticalTo(c2))
                
                expect(c) != a
                expect(c) != b
                expect(c) != d
                expect(c) != e
                expect(c) != f
                expect(c) != g
                expect(c) != h
                expect(c) != i

                let d2 = d.copy() as! AferoAttributeDescriptor
                
                expect(d) == d2
                expect(d).toNot(beIdenticalTo(d2))
                
                expect(d) != a
                expect(d) != b
                expect(d) != c
                expect(d) != e
                expect(d) != f
                expect(d) != g
                expect(d) != h
                expect(d) != i

                let e2 = e.copy() as! AferoAttributeDescriptor
                
                expect(e) == e2
                expect(e).toNot(beIdenticalTo(e2))
                
                expect(e) != a
                expect(e) != b
                expect(e) != c
                expect(e) != d
                expect(e) != f
                expect(e) != g
                expect(e) != h
                expect(e) != i

                let f2 = f.copy() as! AferoAttributeDescriptor
                
                expect(f) == f2
                expect(f).toNot(beIdenticalTo(f2))
                
                expect(f) != a
                expect(f) != b
                expect(f) != c
                expect(f) != d
                expect(f) != e
                expect(f) != g
                expect(f) != h
                expect(f) != i

                let g2 = g.copy() as! AferoAttributeDescriptor
                
                expect(g) == g2
                expect(g).toNot(beIdenticalTo(g2))
                
                expect(g) != a
                expect(g) != b
                expect(g) != c
                expect(g) != d
                expect(g) != e
                expect(g) != f
                expect(g) != h
                expect(g) != i

                let h2 = h.copy() as! AferoAttributeDescriptor
                
                expect(h) == h2
                expect(h).toNot(beIdenticalTo(h2))
                
                expect(h) != a
                expect(h) != b
                expect(h) != c
                expect(h) != d
                expect(h) != e
                expect(h) != f
                expect(h) != g
                expect(h) != i

                let i2 = i.copy() as! AferoAttributeDescriptor
                
                expect(i) == i2
                expect(i).toNot(beIdenticalTo(i2))
                
                expect(i) != a
                expect(i) != b
                expect(i) != c
                expect(i) != d
                expect(i) != e
                expect(i) != f
                expect(i) != g
                expect(i) != h

            }
            
            
        }

        describe("initializing") {

            it("should initialize correctly") {
                
                expect(a.id) == 111
                expect(a.dataType) == AferoAttributeDataType.boolean
                expect(a.semanticType) == "semantic111"
                expect(a.key) == "key111"
                expect(a.defaultValue) == "true"
                expect(a.operations) == [.Read, .Write]

                expect(b.id) == 222
                expect(b.dataType) == AferoAttributeDataType.sInt8
                expect(b.semanticType) == "semantic222"
                expect(b.key) == "key222"
                expect(b.defaultValue) == "2"
                expect(b.operations) == [.Read]

                expect(c.id) == 333
                expect(c.dataType) == AferoAttributeDataType.sInt16
                expect(c.semanticType) == "semantic333"
                expect(c.key) == "key333"
                expect(c.defaultValue) == "3"
                expect(c.operations) == [.Write]

                expect(d.id) == 444
                expect(d.dataType) == AferoAttributeDataType.sInt32
                expect(d.semanticType) == "semantic444"
                expect(d.key) == "key444"
                expect(d.defaultValue) == "4"
                expect(d.operations) == []

                expect(e.id) == 555
                expect(e.dataType) == AferoAttributeDataType.sInt64
                expect(e.semanticType) == "semantic555"
                expect(e.key) == "key555"
                expect(e.defaultValue) == "5"
                expect(e.operations) == [.Write, .Read]

                expect(f.id) == 666
                expect(f.dataType) == AferoAttributeDataType.q1516
                expect(f.semanticType) == "semantic666"
                expect(f.key) == "key666"
                expect(f.defaultValue) == "6.6"
                expect(f.operations) == [.Write]

                expect(g.id) == 777
                expect(g.dataType) == AferoAttributeDataType.q3132
                expect(g.semanticType) == "semantic777"
                expect(g.key) == "key777"
                expect(g.defaultValue) == "7.7"
                expect(g.operations) == [.Read]

                expect(h.id) == 888
                expect(h.dataType) == AferoAttributeDataType.utf8S
                expect(h.semanticType) == "semantic888"
                expect(h.key) == "key888"
                expect(h.defaultValue) == "stringystring"
                expect(h.operations) == []

                expect(i.id) == 999
                expect(i.dataType) == AferoAttributeDataType.bytes
                expect(i.semanticType).to(beNil())
                expect(i.key).to(beNil())
                expect(i.defaultValue).to(beNil())
                expect(i.operations) == [.Write, .Read]

            }
        }

    }
}

class AferoAttributeValueStateSpec: QuickSpec {
    
    override func spec() {
        
        let a = AferoAttributeValueState(value: "1", data: "01", updatedTimestampMs: 0, requestId: 3)
        let a2 = a.copy() as! AferoAttributeValueState

        let b = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: nil)
        let b2 = b.copy() as! AferoAttributeValueState

        describe("initializing") {
            
            it("should initialize as expected.") {
                expect(a.value) == "1"
                expect(a.data) == "01"
                expect(a.updatedTimestampMs) == 0
                expect(a.updatedTimestamp) == Date.dateWithMillisSince1970(0)
                
                expect(b.value) == "2"
                expect(b.data) == "02"
                expect(b.updatedTimestampMs) == 1000
                expect(b.updatedTimestamp) == Date.dateWithMillisSince1970(1000)
                expect(b.requestId).to(beNil())
            }
        }
        
        describe("copying, equating, and comparing") {

            it("should copy and equate as expected") {
                expect(a2) == a
                expect(a2).toNot(beIdenticalTo(a))
                expect(a2) != b
                
                expect(b2) == b
                expect(b2).toNot(beIdenticalTo(b))
                expect(b2) != a
            }
            
            it("should compare as expected") {
                expect(a) < b
                expect(b2) > a
                expect(b).toNot(beLessThan(b2))
                expect(a).toNot(beLessThan(a2))
            }
            
        }
        
    }
}

class AferoAttributeSpec: QuickSpec {
    
    override func spec() {

        let adesc = AferoAttributeDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
        let astate = AferoAttributeValueState(value: "1", data: "01", updatedTimestampMs: 0, requestId: nil)
        let astatep = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: 4)
        
        let a = AferoAttribute(descriptor: adesc)
        let ac = a.copy() as! AferoAttribute

        let a2 = AferoAttribute(descriptor: adesc, currentValueState: astate)
        let ac2 = a2.copy() as! AferoAttribute

        let a3 = AferoAttribute(descriptor: adesc, currentValueState: astate, pendingValueState: astatep)
        let ac3 = a3.copy() as! AferoAttribute

        let bdesc = AferoAttributeDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
        let bstate = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: nil)
        let bstatep = AferoAttributeValueState(value: "3", data: "03", updatedTimestampMs: 2000, requestId: 9)
        let b = AferoAttribute(descriptor: bdesc)
        let b2 = AferoAttribute(descriptor: bdesc, currentValueState: bstate)
        let b3 = AferoAttribute(descriptor: bdesc, currentValueState: bstate, pendingValueState: bstatep)

        describe("initializing") {
            
            it("should initialize") {
                
                expect(a.descriptor) == adesc
                expect(a.currentValueState).to(beNil())
                expect(a.pendingValueState).to(beNil())
                
                expect(a2.descriptor) == adesc
                expect(a2.currentValueState) == astate
                expect(a2.pendingValueState).to(beNil())

                expect(a3.descriptor) == adesc
                expect(a3.currentValueState) == astate
                expect(a3.pendingValueState) == astatep

                expect(b.descriptor) == bdesc
                expect(b.currentValueState).to(beNil())
                expect(b.pendingValueState).to(beNil())
                
                expect(b2.descriptor) == bdesc
                expect(b2.currentValueState) == bstate
                expect(b2.pendingValueState).to(beNil())
                
                expect(b3.descriptor) == bdesc
                expect(b3.currentValueState) == bstate
                expect(b3.pendingValueState) == bstatep

            }
        }
        
        describe("copying and equating") {
            
            it("should copy") {
                expect(ac).toNot(beIdenticalTo(a))
                
                expect(ac.descriptor) == a.descriptor
                expect(ac.descriptor).toNot(beIdenticalTo(a.descriptor))
                expect(ac.currentValueState).to(beNil())
                expect(ac.pendingValueState).to(beNil())
                
                expect(ac2).toNot(beIdenticalTo(a2))
                
                expect(ac2.descriptor) == a2.descriptor
                expect(ac2.descriptor).toNot(beIdenticalTo(a2.descriptor))
                
                expect(ac2.currentValueState) == a2.currentValueState
                expect(ac2.currentValueState).toNot(beIdenticalTo(a2.currentValueState))
                
                expect(ac2.pendingValueState).to(beNil())

                expect(ac3) == a3
                expect(ac3).toNot(beIdenticalTo(a3))
                
                expect(ac3.descriptor) == a3.descriptor
                expect(ac3.descriptor).toNot(beIdenticalTo(a3.descriptor))
                
                expect(ac3.currentValueState) == a3.currentValueState
                expect(ac3.currentValueState).toNot(beIdenticalTo(a3.currentValueState))
                
                expect(ac3.pendingValueState) == a3.pendingValueState
                expect(ac3.pendingValueState).toNot(beIdenticalTo(a3.currentValueState))
            }
            
            it("should equate") {
                expect(a) == ac
                expect(a) != a2
                expect(a) != a3
                expect(a) != b
                expect(a) != b2
                expect(a) != b3
                
                expect(a2) == ac2
                expect(a2) != a
                expect(a2) != a3
                expect(a2) != b
                expect(a2) != b2
                expect(a2) != b3

                expect(a3) == ac3
                expect(a3) != a
                expect(a3) != a2
                expect(a3) != b
                expect(a3) != b2
                expect(a3) != b3
            }
            
        }
        
        describe("coding") {
            
            it("should roundtrip") {
                
                
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                
                let roundtrip: (AferoAttribute) throws -> AferoAttribute = {
                    desc in
                    let data = try encoder.encode(desc)
                    return try decoder.decode(AferoAttribute.self, from: data)
                }
                
                do {
                    expect(try roundtrip(a)) == ac
                    expect(try roundtrip(a2)) == ac2
                    expect(try roundtrip(a3)) == ac3
                } catch {
                    fail(error.localizedDescription)
                }
                

            }
        }
        
        describe("computed params") {
            
            it("should report hasPendingValueState") {
                expect(a.hasPendingValueState).to(beFalse())
                expect(a2.hasPendingValueState).to(beFalse())
                expect(a3.hasPendingValueState).to(beTrue())
            }
            
            it("should report displayValueState") {
                expect(a.displayValueState).to(beNil())
                expect(a2.displayValueState) == a2.currentValueState
                expect(a3.displayValueState) == a3.pendingValueState
            }
        }
        
        describe("KVO") {
            
            it("should report descriptor changes") {
                
                let newDesc = AferoAttributeDescriptor(id: 23, type: .bytes, semanticType: "foo", key: "moo", defaultValue: "42", operations: [.Write])
                var chgDesc: AferoAttributeDescriptor? = nil
                let la = a.copy() as! AferoAttribute
                
                let obs = la.observe(\.descriptor) {
                    obj, chg in
                    chgDesc = obj.descriptor
                }
                
                la.descriptor = newDesc
                
                expect(chgDesc).toEventually(equal(newDesc), timeout: 0.5, pollInterval: 0.1)
            }
            
            it("should report currentValueState changes") {

                let newState = AferoAttributeValueState(value: "9", data: "09", updatedTimestamp: Date(), requestId: 23)
                var chgState: AferoAttributeValueState? = nil
                let la = a.copy() as! AferoAttribute

                let obs = la.observe(\.currentValueState) {
                    obj, chg in
                    chgState = obj.currentValueState
                }
                
                la.currentValueState = newState
                
                expect(chgState).toEventually(equal(newState), timeout: 1.0, pollInterval: 0.1)

            }
            
            it("should report pendingValueState changes") {

                let newState = AferoAttributeValueState(value: "9", data: "09", updatedTimestamp: Date(), requestId: 23)
                var chgState: AferoAttributeValueState? = nil
                let la2 = a2.copy() as! AferoAttribute

                let obs = la2.observe(\.pendingValueState) {
                    obj, chg in
                    chgState = obj.pendingValueState
                }
                
                la2.pendingValueState = newState
                
                expect(chgState).toEventually(equal(newState), timeout: 1.0, pollInterval: 0.1)

            }
            
            it("should report hasPendingValueState changes") {

                let newState = AferoAttributeValueState(value: "9", data: "09", updatedTimestamp: Date(), requestId: 23)
                var chgState: Bool? = nil
                let la2 = a2.copy() as! AferoAttribute
                
                let obs = la2.observe(\.hasPendingValueState) {
                    obj, chg in
                    chgState = obj.hasPendingValueState
                }
                
                la2.pendingValueState = newState
                
                expect(chgState).toEventually(beTrue(), timeout: 1.0, pollInterval: 0.1)

            }
            
            it("should report displayValueState changes") {
                
                let newState = AferoAttributeValueState(value: "9", data: "09", updatedTimestamp: Date(), requestId: 23)
                var chgState: AferoAttributeValueState? = nil
                let la2 = a2.copy() as! AferoAttribute
                
                let obs = la2.observe(\.displayValueState) {
                    obj, chg in
                    chgState = obj.displayValueState
                }
                
                la2.pendingValueState = newState
                
                expect(chgState).toEventually(equal(newState), timeout: 1.0, pollInterval: 0.1)

            }
        }
        
    }
}
