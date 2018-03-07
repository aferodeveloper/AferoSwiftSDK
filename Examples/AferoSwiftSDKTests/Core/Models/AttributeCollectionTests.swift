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

        let a = AferoAttributeDataDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
        let b = AferoAttributeDataDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
        let c = AferoAttributeDataDescriptor(id: 333, type: .sInt16, semanticType: "semantic333", key: "key333", defaultValue: "3", operations: [.Write])
        let d = AferoAttributeDataDescriptor(id: 444, type: .sInt32, semanticType: "semantic444", key: "key444", defaultValue: "4", operations: [])
        let e = AferoAttributeDataDescriptor(id: 555, type: .sInt64, semanticType: "semantic555", key: "key555", defaultValue: "5", operations: [.Read, .Write])
        let f = AferoAttributeDataDescriptor(id: 666, type: .q1516, semanticType: "semantic666", key: "key666", defaultValue: "6.6", operations: [.Write])
        let g = AferoAttributeDataDescriptor(id: 777, type: .q3132, semanticType: "semantic777", key: "key777", defaultValue: "7.7", operations: [.Read])
        let h = AferoAttributeDataDescriptor(id: 888, type: .utf8S, semanticType: "semantic888", key: "key888", defaultValue: "stringystring", operations: [])
        let i = AferoAttributeDataDescriptor(id: 999, type: .bytes, semanticType: nil, key: nil, defaultValue: nil, operations: [.Read, .Write])
        
        describe("Codable") {
            
            it("should roundtrip") {
                do {
                    
                    let encoder = JSONEncoder()
                    let decoder = JSONDecoder()
                    
                    let roundtrip: (AferoAttributeDataDescriptor) throws -> AferoAttributeDataDescriptor = {
                        desc in
                        let data = try encoder.encode(desc)
                        return try decoder.decode(AferoAttributeDataDescriptor.self, from: data)
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
        
        describe("AferoJSONCoding") {
            it("should roundtrip") {
                expect(a) == |<a.JSONDict
                expect(b) == |<b.JSONDict
                expect(c) == |<c.JSONDict
                expect(d) == |<d.JSONDict
                expect(e) == |<e.JSONDict
                expect(f) == |<f.JSONDict
                expect(g) == |<g.JSONDict
                expect(h) == |<h.JSONDict
                expect(i) == |<i.JSONDict
            }
        }
        
        
        describe("copying and equating") {
            
            it("should equate as expected") {

                let a2 = a.copy() as! AferoAttributeDataDescriptor
                
                expect(a) == a2
                expect(a).toNot(beIdenticalTo(a2))
                
                expect(a) != b
                expect(a) != c
                expect(a) != d
                expect(a) != e
                expect(a) != g
                expect(a) != h
                expect(a) != i

                let b2 = b.copy() as! AferoAttributeDataDescriptor
                
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

                let c2 = c.copy() as! AferoAttributeDataDescriptor
                
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

                let d2 = d.copy() as! AferoAttributeDataDescriptor
                
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

                let e2 = e.copy() as! AferoAttributeDataDescriptor
                
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

                let f2 = f.copy() as! AferoAttributeDataDescriptor
                
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

                let g2 = g.copy() as! AferoAttributeDataDescriptor
                
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

                let h2 = h.copy() as! AferoAttributeDataDescriptor
                
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

                let i2 = i.copy() as! AferoAttributeDataDescriptor
                
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
                expect(a.stringValue) == "1"
                expect(a.data) == "01"
                expect(a.updatedTimestampMs) == 0
                expect(a.updatedTimestamp) == Date.dateWithMillisSince1970(0)
                
                expect(b.stringValue) == "2"
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
            
        }
        
        describe("Codable") {
            
            it("should roundtrip") {
                
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                
                let roundtrip: (AferoAttributeValueState) throws -> AferoAttributeValueState = {
                    desc in
                    let data = try encoder.encode(desc)
                    return try decoder.decode(AferoAttributeValueState.self, from: data)
                }
                
                do {
                    expect(try roundtrip(a)) == a2
                    expect(try roundtrip(b)) == b2
                } catch {
                    fail(error.localizedDescription)
                }

            }
            
        }
        
        describe("AferoJSONCoding") {
            
            it("should roundtrip") {
                
                expect(a2) == |<a.JSONDict
                expect(b2) == |<b.JSONDict
            }
            
        }
        
    }
}

class AferoAttributeSpec: QuickSpec {
    
    override func spec() {

        let adesc = AferoAttributeDataDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
        let astate = AferoAttributeValueState(value: "1", data: "01", updatedTimestampMs: 0, requestId: nil)
        let astatep = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: 4)
        
        let a = AferoAttribute(dataDescriptor: adesc)
        let ac = a.copy() as! AferoAttribute

        let a2 = AferoAttribute(dataDescriptor: adesc, currentValueState: astate)
        let ac2 = a2.copy() as! AferoAttribute

        let a3 = AferoAttribute(dataDescriptor: adesc, currentValueState: astate, pendingValueState: astatep)
        let ac3 = a3.copy() as! AferoAttribute

        let bdesc = AferoAttributeDataDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
        let bstate = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: nil)
        let bstatep = AferoAttributeValueState(value: "3", data: "03", updatedTimestampMs: 2000, requestId: 9)
        let b = AferoAttribute(dataDescriptor: bdesc)
        let b2 = AferoAttribute(dataDescriptor: bdesc, currentValueState: bstate)
        let b3 = AferoAttribute(dataDescriptor: bdesc, currentValueState: bstate, pendingValueState: bstatep)

        describe("initializing") {
            
            it("should initialize") {
                
                expect(a.dataDescriptor) == adesc
                expect(a.currentValueState).to(beNil())
                expect(a.pendingValueState).to(beNil())
                
                expect(a2.dataDescriptor) == adesc
                expect(a2.currentValueState) == astate
                expect(a2.pendingValueState).to(beNil())

                expect(a3.dataDescriptor) == adesc
                expect(a3.currentValueState) == astate
                expect(a3.pendingValueState) == astatep

                expect(b.dataDescriptor) == bdesc
                expect(b.currentValueState).to(beNil())
                expect(b.pendingValueState).to(beNil())
                
                expect(b2.dataDescriptor) == bdesc
                expect(b2.currentValueState) == bstate
                expect(b2.pendingValueState).to(beNil())
                
                expect(b3.dataDescriptor) == bdesc
                expect(b3.currentValueState) == bstate
                expect(b3.pendingValueState) == bstatep

            }
        }
        
        describe("copying and equating") {
            
            it("should copy") {
                expect(ac).toNot(beIdenticalTo(a))
                
                expect(ac.dataDescriptor) == a.dataDescriptor
                expect(ac.dataDescriptor).toNot(beIdenticalTo(a.dataDescriptor))
                expect(ac.currentValueState).to(beNil())
                expect(ac.pendingValueState).to(beNil())
                
                expect(ac2).toNot(beIdenticalTo(a2))
                
                expect(ac2.dataDescriptor) == a2.dataDescriptor
                expect(ac2.dataDescriptor).toNot(beIdenticalTo(a2.dataDescriptor))
                
                expect(ac2.currentValueState) == a2.currentValueState
                expect(ac2.currentValueState).toNot(beIdenticalTo(a2.currentValueState))
                
                expect(ac2.pendingValueState).to(beNil())

                expect(ac3) == a3
                expect(ac3).toNot(beIdenticalTo(a3))
                
                expect(ac3.dataDescriptor) == a3.dataDescriptor
                expect(ac3.dataDescriptor).toNot(beIdenticalTo(a3.dataDescriptor))
                
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
        
        describe("Codable") {
            
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
        
        describe("AferoJSONCoding") {
            it("should roundtrip") {
                
                expect(a) == |<ac.JSONDict
                expect(a2) == |<ac2.JSONDict
                expect(a3) == |<ac3.JSONDict
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
                
                let newDesc = AferoAttributeDataDescriptor(id: 23, type: .bytes, semanticType: "foo", key: "moo", defaultValue: "42", operations: [.Write])
                var chgDesc: AferoAttributeDataDescriptor? = nil
                let la = a.copy() as! AferoAttribute
                
                let obs = la.observe(\.dataDescriptor) {
                    obj, chg in
                    chgDesc = obj.dataDescriptor
                }
                
                la.dataDescriptor = newDesc
                
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

class AferoAttributeCollectionSpec: QuickSpec {

    override func spec() {
        
        let adesc = AferoAttributeDataDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
        let astate = AferoAttributeValueState(value: "1", data: "01", updatedTimestampMs: 0, requestId: nil)
        let astatep = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: 4)
//        let a = AferoAttribute(dataDescriptor: adesc)
//        let a2 = AferoAttribute(dataDescriptor: adesc, currentValueState: astate)
        let a3 = AferoAttribute(dataDescriptor: adesc, currentValueState: astate, pendingValueState: astatep)
        
        let bdesc = AferoAttributeDataDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
        let bstate = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: nil)
        let bstatep = AferoAttributeValueState(value: "3", data: "03", updatedTimestampMs: 2000, requestId: 9)
//        let b = AferoAttribute(dataDescriptor: bdesc)
//        let b2 = AferoAttribute(dataDescriptor: bdesc, currentValueState: bstate)
        let b3 = AferoAttribute(dataDescriptor: bdesc, currentValueState: bstate, pendingValueState: bstatep)

        describe("initializing") {
            
            it("should default-initialize") {
                let c = AferoAttributeCollection()
                expect(c.attributeIds) == []
            }
            
            it("should initialize with attributes") {
                do {
                    let c = try AferoAttributeCollection(attributes: [a3, b3])
                    expect(c.attributeIds) == [111, 222]
                } catch {
                    fail(error.localizedDescription)
                }
            }
            
            it("should initialize with descriptors") {
                do {
                    let c = try AferoAttributeCollection(descriptors: [adesc, bdesc])
                    expect(c.attributeIds) == [111, 222]
                } catch {
                    fail(error.localizedDescription)
                }
            }

            it("should throw during initialization with redundant attributes.") {
                expect {
                    try AferoAttributeCollection(attributes: [a3, a3])
                    }.to(throwError(AferoAttributeCollectionError.duplicateAttributeId))
            }

            it("should throw during initialization with redundant descriptors.") {
                expect {
                    try AferoAttributeCollection(descriptors: [adesc, adesc])
                    }.to(throwError(AferoAttributeCollectionError.duplicateAttributeId))
            }
            
        }
        
        describe("coding") {
            
            it("should roundtrip") {
                
                let encoder = JSONEncoder()
                let decoder = JSONDecoder()
                
                let roundtrip: (AferoAttributeCollection) throws -> AferoAttributeCollection = {
                    desc in
                    let data = try encoder.encode(desc)
                    return try decoder.decode(AferoAttributeCollection.self, from: data)
                }
                
                do {
                    
                    let c = try AferoAttributeCollection(attributes: [a3, b3])
                    let cc = try roundtrip(c)
                    
                    expect(cc).toNot(beIdenticalTo(c))
                    expect(cc.attributes) == c.attributes

                } catch {
                    fail(error.localizedDescription)
                }

            }
        }
        
        describe("attribute access") {
            
            it("return the expected attributes when asked") {
                
                do {
                    let c = try AferoAttributeCollection(attributes: [a3, b3])
                    expect(c.attributes) == [b3, a3]
                    expect(c.attributeIds) == [b3.dataDescriptor.id, a3.dataDescriptor.id]
                    expect(c.attributeKeys) == Set([b3.dataDescriptor.key, a3.dataDescriptor.key].flatMap { $0 })
                } catch {
                    fail(error.localizedDescription)
                }

            }
            
            it("should query attributes by key") {

                do {
                    let c = try AferoAttributeCollection(attributes: [a3, b3])
                    expect(c.attribute(forKey: a3.dataDescriptor.key)) == a3
                    expect(c.attribute(forKey: b3.dataDescriptor.key)) == b3
                    expect(c.attribute(forKey: "foo")).to(beNil())
                } catch {
                    fail(error.localizedDescription)
                }

            }
            
            it("should query attributes by id") {
                
                do {
                    let c = try AferoAttributeCollection(attributes: [a3, b3])
                    expect(c.attribute(forId: a3.dataDescriptor.id)) == a3
                    expect(c.attribute(forId: b3.dataDescriptor.id)) == b3
                    expect(c.attribute(forId: 666)).to(beNil())
                } catch {
                    fail(error.localizedDescription)
                }
                
            }

        }
        
        describe("Attribute state modification") {
            
//            describe("when updating descriptors") {
//
//                it("should update on recognized id") {
//
//                    do {
//                        let c = try AferoAttributeCollection(attributes: [a3, b3])
//                        let new a3Desc = AferoAttributeDescriptor(id: a3.dataDescriptor.id, type: AferoAttributeDataType.q3132, semanticType: "monkeybutt", key: <#T##String?#>, defaultValue: <#T##String?#>, operations: <#T##AferoAttributeOperations#>)
//                    } catch {
//                        fail(error.localizedDescription)
//                    }
//
//                }
//
//                it("should throw on unrecognized id") {
//
//                }
//
//                it("should throw if the new descriptor id doesn't match the old descriptor id.") {
//
//                }
//            }

            describe("when updating current value state") {
                
                it("should update on recognized id") {
                   
                    do {
                        let c = try AferoAttributeCollection(attributes: [a3, b3])
                        
                        var newAttribute: AferoAttribute?
                        var newCurrentValueState: AferoAttributeValueState?
                        var notificationCount: Int = 0
                        
                        let obs = try c.observeAttribute(
                            withId: a3.dataDescriptor.id,
                            on: \.currentValueState) {
                            attribute, chg in
                                notificationCount += 1
                                newAttribute = attribute
                                newCurrentValueState = attribute.currentValueState
                        }
                        
                        expect {
                            try c.setCurrent(value: "6", forAttributeWithId: 2323)
                        }.to(throwError(AferoAttributeCollectionError.unrecognizedAttributeId))
                        
                    } catch {
                        fail(error.localizedDescription)
                    }

                }
                
                it("should throw on unrecognized id") {

                    let c = try! AferoAttributeCollection(attributes: [a3, b3])
                    expect {
                        try c.setCurrent(value: "6", forAttributeWithId: 2323)
                        }.to(throwError(AferoAttributeCollectionError.unrecognizedAttributeId))
                    
                }
                
            }

            describe("when updating pending value state") {
                
                it("should update on recognized id") {

                    do {
                        let c = try! AferoAttributeCollection(attributes: [a3, b3])
                        
                        var newAttribute: AferoAttribute?
                        var newPendingValueState: AferoAttributeValueState?
                        var notificationCount: Int = 0
                        
                        let obs = try c.observeAttribute(
                            withId: b3.dataDescriptor.id,
                            on: \.pendingValueState) {
                                attribute, chg in
                                notificationCount += 1
                                newAttribute = attribute
                                newPendingValueState = attribute.pendingValueState
                        }
                        
                        try c.setPending(value: "6", forAttributeWithId: b3.dataDescriptor.id)
                        expect(newPendingValueState?.stringValue).toEventually(equal("6"), timeout: 1.0, pollInterval: 0.1)
                        expect(newAttribute).toEventually(equal(b3), timeout: 1.0, pollInterval: 0.1)
                    } catch {
                        fail(error.localizedDescription)
                    }

                }
                
                it("should throw on unrecognized id") {
                    
                    let c = try! AferoAttributeCollection(attributes: [a3, b3])
                    expect {
                        try c.setPending(value: "6", forAttributeWithId: 2323)
                        }.to(throwError(AferoAttributeCollectionError.unrecognizedAttributeId))
                    
                }

            }
            
        }

        describe("when updating intended value state") {
            
            it("should update on recognized id") {
                
                do {
                    let c = try! AferoAttributeCollection(attributes: [a3, b3])
                    
                    var newPendingValueState: AferoAttributeValueState?
                    var newIntendedValueState: AferoAttributeValueState?
                    var newDisplayValueState: AferoAttributeValueState?
                    var pendingNotificationCount: Int = 0
                    var intendedNotificationCount: Int = 0
                    var displayNotificationCount: Int = 0

                    let pendingObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.pendingValueState) {
                            attribute, chg in
                            pendingNotificationCount += 1
                            newPendingValueState = attribute.pendingValueState
                    }

                    let intendedObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.intendedValueState) {
                            attribute, chg in
                            intendedNotificationCount += 1
                            newIntendedValueState = attribute.intendedValueState
                    }

                    let displayObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.displayValueState) {
                            attribute, chg in
                            displayNotificationCount += 1
                            newDisplayValueState = attribute.displayValueState
                    }

                    try c.setIntended(value: "6", forAttributeWithId: b3.dataDescriptor.id)
                    expect(newPendingValueState == nil).toNotEventually(beFalse(), timeout: 1.0, pollInterval: 0.1)
                    expect(pendingNotificationCount).toNotEventually(beGreaterThan(0), timeout: 1.0, pollInterval: 0.1)
                    expect(newIntendedValueState?.stringValue).toEventually(equal("6"), timeout: 1.0, pollInterval: 0.1)
                    expect(intendedNotificationCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                    expect(newDisplayValueState?.stringValue).toEventually(equal("6"), timeout: 1.0, pollInterval: 0.1)
                    expect(displayNotificationCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                } catch {
                    fail(error.localizedDescription)
                }
                
            }
            
            it("should throw on unrecognized id") {
                
                let c = try! AferoAttributeCollection(attributes: [a3, b3])
                expect {
                    try c.setPending(value: "6", forAttributeWithId: 2323)
                    }.to(throwError(AferoAttributeCollectionError.unrecognizedAttributeId))
                
            }
            
        }
        
        fdescribe("Committing intended values") {

            let adesc = AferoAttributeDataDescriptor(id: 111, type: .boolean, semanticType: "semantic111", key: "key111", defaultValue: "true", operations: [.Read, .Write])
            let astate = AferoAttributeValueState(value: "1", data: "01", updatedTimestampMs: 0, requestId: nil)
            let a = AferoAttribute(dataDescriptor: adesc, currentValueState: astate)
            
            let bdesc = AferoAttributeDataDescriptor(id: 222, type: .sInt8, semanticType: "semantic222", key: "key222", defaultValue: "2", operations: [.Read])
            let bstate = AferoAttributeValueState(value: "2", data: "02", updatedTimestampMs: 1000, requestId: nil)
            let b = AferoAttribute(dataDescriptor: bdesc, currentValueState: bstate)

            let attributes = [a, b]
            
            var c: AferoAttributeCollection!
            
            var observedPendingValueStates: [Int: String]!
            var pendingValueObservers: [(Int, NSKeyValueObservation)]!
            
            var observedCurrentValueStates: [Int: String]!
            var currentValueObservers: [(Int, NSKeyValueObservation)]!

            var observedIntendedValueStates: [Int: String]!
            var intendedValueObservers: [(Int, NSKeyValueObservation)]!

            var observedDisplayValueStates: [Int: String]!
            var displayValueObservers: [(Int, NSKeyValueObservation)]!

            beforeEach {
                
                c =  try! AferoAttributeCollection(attributes: attributes)
                
                observedPendingValueStates = [:]
                pendingValueObservers = try! c.observeAttributes(withIds: attributes.map { $0.id }, on: \.pendingValueState, options: [.initial]) {
                    attribute, change in
                    observedPendingValueStates[attribute.id] = attribute.pendingValueState?.stringValue
                }
                
                observedCurrentValueStates = [:]
                currentValueObservers = try! c.observeAttributes(withIds: attributes.map { $0.id }, on: \.currentValueState, options: [.initial]) {
                    attribute, change in
                    observedCurrentValueStates[attribute.id] = attribute.currentValueState?.stringValue
                }
                
                observedIntendedValueStates = [:]
                intendedValueObservers = try! c.observeAttributes(withIds: attributes.map { $0.id }, on: \.intendedValueState, options: [.initial]) {
                    attribute, change in
                    observedIntendedValueStates[attribute.id] = attribute.intendedValueState?.stringValue
                }
                
                observedDisplayValueStates = [:]
                displayValueObservers = try! c.observeAttributes(withIds: attributes.map { $0.id }, on: \.displayValueState, options: [.initial]) {
                    attribute, change in
                    observedDisplayValueStates[attribute.id] = attribute.displayValueState?.stringValue
                }
                
            }

            it("should do nothing if attributes are committed but there's nothing 'intended'") {
                c.commitIntended()
                expect(observedDisplayValueStates) == [:]
                expect(observedCurrentValueStates) == [:]
                expect(observedIntendedValueStates) == [:]
                expect(observedDisplayValueStates) == [:]
                expect(c.pendingAttributes).to(beEmpty())
                expect(c.intendedAttributes).to(beEmpty())
                expect(Set(c.attributes.flatMap { $0.currentValueState})) == Set([a.currentValueState, b.currentValueState].flatMap { $0 })
            }
            
            it("should change pendingValueStates and intendedValueStates if there is something to commit.") {
                do {
                    try c.setIntended(value: "intended monkey", forAttributeWithId: a3.id)
                    c.commitIntended()
                    expect(observedIntendedValueStates).toEventually(beEmpty(), timeout: 1.0, pollInterval: 0.1)
                    expect(observedDisplayValueStates).toEventually(equal([a3.id: "intended monkey"]), timeout: 1.0, pollInterval: 0.1)
                    expect(observedPendingValueStates).toEventually(equal([a3.id: "intended monkey"]), timeout: 1.0, pollInterval: 0.1)
                    expect(observedCurrentValueStates.isEmpty).toNotEventually(beFalse(), timeout: 1.0, pollInterval: 0.1)
                } catch {
                    fail(String(reflecting: error))
                }
            }

            it("should call the attributeCommitHandler with the expected values, and not migrate to pending upon failure.") {
                do {
                    
                    var committedAttributes: [Int: String]!
                    
                    c.attributeCommitHandler = {
                        attributes, resultHandler in
                        committedAttributes = attributes.reduce([:]) {
                            curr, next in
                            var ret = curr!
                            ret[next.id] = next.value
                            return ret
                        }
                        var reqIdGen = (0..<Int.max).makeIterator()
                        resultHandler(committedAttributes.filter { $0.key != a3.id}.map {
                            (req: $0, resp: (success: true, reqId: reqIdGen.next()!, timestampMs: Date().millisSince1970))
                        })
                    }
                    
                    try c.setIntended(value: "intended monkey", forAttributeWithId: a3.id)
                    c.commitIntended()
                    expect(committedAttributes).toEventually(equal([a3.id: "intended monkey"]), timeout: 1.0, pollInterval: 0.1)
                    expect(observedIntendedValueStates).toNotEventually(beEmpty(), timeout: 1.0, pollInterval: 0.1)
                    expect(observedPendingValueStates.isEmpty).toNotEventually(beFalse(), timeout: 1.0, pollInterval: 0.1)
                    expect(observedCurrentValueStates.isEmpty).toNotEventually(beFalse(), timeout: 1.0, pollInterval: 0.1)
                    expect(observedDisplayValueStates).toEventually(equal([a3.id: "intended monkey"]), timeout: 1.0, pollInterval: 0.1)
                } catch {
                    fail(String(reflecting: error))
                }
            }
            
        }

        describe("Observing attributes") {
            
            it("should allow subscription to attributes by id") {

                let c = try! AferoAttributeCollection(attributes: [a3, b3])
                var pendingObs: NSKeyValueObservation?
                var currentObs: NSKeyValueObservation?
                var intendedObs: NSKeyValueObservation?
                
                expect {
                    pendingObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.pendingValueState) {
                            _, _ in
                    }
                }.toNot(throwError())
                expect(pendingObs).toNot(beNil())
                
                expect {
                    currentObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.currentValueState) {
                            _, _ in
                    }
                    }.toNot(throwError())
                expect(currentObs).toNot(beNil())

                expect {
                    currentObs = try c.observeAttribute(
                        withId: b3.dataDescriptor.id,
                        on: \.intendedValueState) {
                            _, _ in
                    }
                    }.toNot(throwError())
                expect(currentObs).toNot(beNil())

            }

            it("should throw when trying to subscribe to an unrecognized id") {

                let c = try! AferoAttributeCollection(attributes: [a3, b3])
                
                expect {
                    _ = try c.observeAttribute(
                        withId: 2323,
                        on: \.pendingValueState) {
                            _, _ in
                    }
                    }.to(throwError())
                
                expect {
                    _ = try c.observeAttribute(
                        withId: 2323,
                        on: \.currentValueState) {
                            _, _ in
                    }
                    }.to(throwError())

                expect {
                    _ = try c.observeAttribute(
                        withId: 2323,
                        on: \.intendedValueState) {
                            _, _ in
                    }
                    }.to(throwError())

            }

            it("should allow subscription to attributes by key") {

                let c = try! AferoAttributeCollection(attributes: [a3, b3])
                var pendingObs: NSKeyValueObservation?
                var currentObs: NSKeyValueObservation?
                
                expect {
                    pendingObs = try c.observeAttribute(
                        withKey: b3.dataDescriptor.key!,
                        on: \.pendingValueState) {
                            _, _ in
                    }
                    }.toNot(throwError())
                expect(pendingObs).toNot(beNil())
                
                expect {
                    currentObs = try c.observeAttribute(
                        withKey: b3.dataDescriptor.key!,
                        on: \.currentValueState) {
                            _, _ in
                    }
                    }.toNot(throwError())
                expect(currentObs).toNot(beNil())

                expect {
                    currentObs = try c.observeAttribute(
                        withKey: b3.dataDescriptor.key!,
                        on: \.intendedValueState) {
                            _, _ in
                    }
                    }.toNot(throwError())
                expect(currentObs).toNot(beNil())

            }

            it("should throw when trying to subscribe to an unrecognized key") {
                
                let c = try! AferoAttributeCollection(attributes: [a3, b3])
                
                expect {
                    _ = try c.observeAttribute(
                        withKey: "2323",
                        on: \.pendingValueState) {
                            _, _ in
                    }
                    }.to(throwError())
                
                expect {
                    _ = try c.observeAttribute(
                        withKey: "2323",
                        on: \.currentValueState) {
                            _, _ in
                    }
                    }.to(throwError())

                expect {
                    _ = try c.observeAttribute(
                        withKey: "2323",
                        on: \.intendedValueState) {
                            _, _ in
                    }
                    }.to(throwError())

            }
            
        }
        
        describe("post-instantiation attribute changes") {
            
            describe("registering atributes") {

                it("Should emit events when attributes are added individually") {
                    
                    do {
                        let c = AferoAttributeCollection()
                        
                        var newAttributes: Set<AferoAttribute>?
                        var attrNotifyCount = 0
                        
                        var newAttributeIds: Set<Int>?
                        var attrIdNotifyCount = 0
                        
                        var newAttributeKeys: Set<String>?
                        var attrKeyNotifyCount = 0
                        
                        let attrObs = c.observe(\.attributes) {
                            obj, chg in
                            newAttributes = obj.attributes
                            attrNotifyCount += 1
                        }
                        
                        let attrIdObs = c.observe(\.attributeIds) {
                            obj, chg in
                            newAttributeIds = obj.attributeIds
                            attrIdNotifyCount += 1
                        }
                        
                        let attrKeyObs = c.observe(\.attributeKeys) {
                            obj, chg in
                            newAttributeKeys = obj.attributeKeys
                            attrKeyNotifyCount += 1
                        }
                        
                        try c.register(attribute: a3)
                        try c.register(attribute: b3)
                        
                        expect(newAttributes).toEventually(equal([b3, a3]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toEventually(equal(2), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toNotEventually(beGreaterThan(2), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeIds).toEventually(equal([b3.dataDescriptor.id, a3.dataDescriptor.id]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toEventually(equal(2), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toNotEventually(beGreaterThan(2), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeKeys).toEventually(equal(Set([b3.dataDescriptor.key, a3.dataDescriptor.key].flatMap { $0 })), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toEventually(equal(2), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toNotEventually(beGreaterThan(2), timeout: 1.0, pollInterval: 0.2)
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }
                
                it("should emit events when attributes are added as a batch") {
                    
                    do {
                        let c = AferoAttributeCollection()
                        
                        var newAttributes: Set<AferoAttribute>?
                        var attrNotifyCount = 0
                        
                        var newAttributeIds: Set<Int>?
                        var attrIdNotifyCount = 0
                        
                        var newAttributeKeys: Set<String>?
                        var attrKeyNotifyCount = 0
                        
                        let attrObs = c.observe(\.attributes) {
                            obj, chg in
                            newAttributes = obj.attributes
                            attrNotifyCount += 1
                        }
                        
                        let attrIdObs = c.observe(\.attributeIds) {
                            obj, chg in
                            newAttributeIds = obj.attributeIds
                            attrIdNotifyCount += 1
                        }
                        
                        let attrKeyObs = c.observe(\.attributeKeys) {
                            obj, chg in
                            newAttributeKeys = obj.attributeKeys
                            attrKeyNotifyCount += 1
                        }
                        
                        try c.register(attributes: [a3, b3])
                        
                        expect(newAttributes).toEventually(equal([b3, a3]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeIds).toEventually(equal([b3.dataDescriptor.id, a3.dataDescriptor.id]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeKeys).toEventually(equal(Set([b3.dataDescriptor.key, a3.dataDescriptor.key].flatMap { $0 })), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }

            }
            
            describe("unregistering attributes") {
                
                it("should emit events when attributes are removed individually by id") {
                    
                    do {
                        
                        let c = try AferoAttributeCollection(attributes: [a3, b3])
                        
                        var newAttributes: Set<AferoAttribute>?
                        var attrNotifyCount = 0
                        
                        var newAttributeIds: Set<Int>?
                        var attrIdNotifyCount = 0
                        
                        var newAttributeKeys: Set<String>?
                        var attrKeyNotifyCount = 0
                        
                        let attrObs = c.observe(\.attributes) {
                            obj, chg in
                            newAttributes = obj.attributes
                            attrNotifyCount += 1
                        }
                        
                        let attrIdObs = c.observe(\.attributeIds) {
                            obj, chg in
                            newAttributeIds = obj.attributeIds
                            attrIdNotifyCount += 1
                        }
                        
                        let attrKeyObs = c.observe(\.attributeKeys) {
                            obj, chg in
                            newAttributeKeys = obj.attributeKeys
                            attrKeyNotifyCount += 1
                        }
                        
                        let ret = c.unregister(attributeId: a3.dataDescriptor.id)
                        expect(ret) == a3

                        expect(newAttributes).toEventually(equal([b3]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeIds).toEventually(equal([b3.dataDescriptor.id]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeKeys).toEventually(equal(Set([b3.dataDescriptor.key].flatMap { $0 })), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }
                
                it("should emit events when attributes are removed individually by key") {
                    
                    do {
                        
                        let c = try AferoAttributeCollection(attributes: [a3, b3])
                        
                        var newAttributes: Set<AferoAttribute>?
                        var attrNotifyCount = 0
                        
                        var newAttributeIds: Set<Int>?
                        var attrIdNotifyCount = 0
                        
                        var newAttributeKeys: Set<String>?
                        var attrKeyNotifyCount = 0
                        
                        let attrObs = c.observe(\.attributes) {
                            obj, chg in
                            newAttributes = obj.attributes
                            attrNotifyCount += 1
                        }
                        
                        let attrIdObs = c.observe(\.attributeIds) {
                            obj, chg in
                            newAttributeIds = obj.attributeIds
                            attrIdNotifyCount += 1
                        }
                        
                        let attrKeyObs = c.observe(\.attributeKeys) {
                            obj, chg in
                            newAttributeKeys = obj.attributeKeys
                            attrKeyNotifyCount += 1
                        }
                        
                        let ret = c.unregister(attributeKey: a3.dataDescriptor.key)
                        expect(ret) == a3
                        
                        expect(newAttributes).toEventually(equal([b3]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeIds).toEventually(equal([b3.dataDescriptor.id]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeKeys).toEventually(equal(Set([b3.dataDescriptor.key].flatMap { $0 })), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }

                
                it("should emit events when attributes are removed wholesale") {

                    do {
                        
                        let c = try AferoAttributeCollection(attributes: [a3, b3])
                        
                        var newAttributes: Set<AferoAttribute>?
                        var attrNotifyCount = 0
                        
                        var newAttributeIds: Set<Int>?
                        var attrIdNotifyCount = 0
                        
                        var newAttributeKeys: Set<String>?
                        var attrKeyNotifyCount = 0
                        
                        let attrObs = c.observe(\.attributes) {
                            obj, chg in
                            newAttributes = obj.attributes
                            attrNotifyCount += 1
                        }
                        
                        let attrIdObs = c.observe(\.attributeIds) {
                            obj, chg in
                            newAttributeIds = obj.attributeIds
                            attrIdNotifyCount += 1
                        }
                        
                        let attrKeyObs = c.observe(\.attributeKeys) {
                            obj, chg in
                            newAttributeKeys = obj.attributeKeys
                            attrKeyNotifyCount += 1
                        }
                        
                        let ret = c.unregisterAllAttributes()
                        
                        expect(Set(ret)) == [a3, b3]
                        
                        expect(newAttributes).toEventually(equal([]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeIds).toEventually(equal([]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrIdNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                        expect(newAttributeKeys).toEventually(equal([]), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toEventually(equal(1), timeout: 1.0, pollInterval: 0.1)
                        expect(attrKeyNotifyCount).toNotEventually(beGreaterThan(1), timeout: 1.0, pollInterval: 0.2)
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    

                }
                
            }
            
            describe("when configuring with a profile") {
                
                let modulo: DeviceProfile = (try! self.fixture(named: "modulo"))!
                let modulo2: DeviceProfile = (try! self.fixture(named: "modulo2"))!

                let bento: DeviceProfile = (try! self.fixture(named: "bento"))!

                it("Should configure with expected attributes") {
                    
                    
                    do {
                        
                        let acModulo = try! AferoAttributeCollection(profile: modulo)
                        let acModulo2 = try! AferoAttributeCollection(profile: modulo2)
                        let acBento = try! AferoAttributeCollection(profile: bento)

                        expect(acModulo.attributes.count) == modulo.attributes.count
                        modulo.attributeConfigs().forEach {
                            config in
                            expect(acModulo.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }

                        
                        expect(acModulo2.attributes.count) == modulo2.attributes.count
                        modulo2.attributeConfigs().forEach {
                            config in
                            expect(acModulo2.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acModulo2.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acModulo2.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }

                        expect(acBento.attributes.count) == bento.attributes.count
                        bento.attributeConfigs().forEach {
                            config in
                            expect(acBento.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acBento.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acBento.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }

                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }
                
                it("Should reconfigure with a nil") {
                    
                    do {
                        
                        let acModulo = try! AferoAttributeCollection(profile: modulo)
                        
                        expect(acModulo.attributes.count) == modulo.attributes.count
                        modulo.attributeConfigs().forEach {
                            config in
                            expect(acModulo.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }
                        
                        try acModulo.configure(with: nil)
                        expect(acModulo.attributes.count) == 0
                        
                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }
                
                it("Should reconfigure with a new profile") {
                    
                    do {
                        
                        let acModulo = try! AferoAttributeCollection(profile: modulo)

                        expect(acModulo.attributes.count) == modulo.attributes.count
                        modulo.attributeConfigs().forEach {
                            config in
                            expect(acModulo.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }
                        
                        try acModulo.configure(with: bento)
                        
                        expect(acModulo.attributes.count) == bento.attributes.count
                        bento.attributeConfigs().forEach {
                            config in
                            expect(acModulo.attribute(forId: config.dataDescriptor.id)?.dataDescriptor) == config.dataDescriptor
                            if config.presentationDescriptor == nil {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor).to(beNil())
                            } else {
                                expect(acModulo.attribute(forId: config.dataDescriptor.id)?.presentationDescriptor) == config.presentationDescriptor
                            }
                        }

                    } catch {
                        fail(error.localizedDescription)
                    }
                    
                }
                
            }
            
        }
    }
}
