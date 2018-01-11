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
            
            let allOperations: AferoAttributeOperations = [.Read, .Write]
            expect(allOperations.contains(.Read)).to(beTrue())
            expect(allOperations.contains(.Write)).to(beTrue())
            
            expect(AferoAttributeOperations.Read.contains(.Read)).to(beTrue())
            expect(AferoAttributeOperations.Read.contains(.Write)).to(beFalse())
            
            expect(AferoAttributeOperations.Write.contains(.Write)).to(beTrue())
            expect(AferoAttributeOperations.Write.contains(.Read)).to(beFalse())
        }
    }
}
