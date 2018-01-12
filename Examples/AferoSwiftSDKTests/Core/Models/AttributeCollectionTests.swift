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

//class AferoAttributeDescriptorSpec: QuickSpec {
//    
//    override func spec() {
//
//        describe("initializing") {
//            it("should initialize correctly") {
//                let a = AferoAttributeDescriptor(id: 5, )
//                
//            }
//        }
//
//    }
//}

