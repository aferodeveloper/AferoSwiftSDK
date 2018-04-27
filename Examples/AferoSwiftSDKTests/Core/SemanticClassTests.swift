//
//  SemanticClassTests.swift
//  AferoTests
//
//  Created by Justin Middleton on 4/27/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation

import Quick
import Nimble
@testable import Afero

class AferoSemanticClassTableSpec: QuickSpec {
    
    override func spec() {
        describe("initializing") {
            
            it("should initialize") {
                let table = AferoSemanticClassTable()
                expect(table.semanticClasses.count) == 0
            }
            
        }
        
        describe("registering classes") {
            
            var t: AferoSemanticClassTable!
            
            beforeEach {
                t = AferoSemanticClassTable()
            }
            
            it("should register root classes as expected") {

                expect(t.semanticClasses.count) == 0
                
                expect {
                    expect(try t ← AferoAttributeSemanticClassDescriptor(identifier: "foo")) === t
                    }.toNot(throwError())
                
                expect(t.semanticClasses.count) == 1
                
                let c = t.semanticClass(for: "foo")
                expect(c).toNot(beNil())
                expect(c?.identifier) == "foo"
                expect(c?.classTable) === t
            }
            
            it("should register specializing classes as expected") {

                expect(t.semanticClasses.count) == 0
                
                expect {
                    expect(try t ← AferoAttributeSemanticClassDescriptor(identifier: "foo") ← AferoAttributeSemanticClassDescriptor(identifier: "bar", isa: ["foo"])) === t
                    }.toNot(throwError())
                
                expect(t.semanticClasses.count) == 2

            }
            
            it("should throw if an a referenced parent attribute doesn't exist.") {
                expect(t.semanticClasses.count) == 0
                
                expect {
                    try t ← AferoAttributeSemanticClassDescriptor(identifier: "bar") ← AferoAttributeSemanticClassDescriptor(identifier: "foo", isa: ["foo"])
                    }.to(throwError(AferoSemanticClassError.unrecognizedSemanticClass("foo")))
                
                expect(t.semanticClasses.count) == 1
            }
            
        }
    }
}

class AferoSemanticClassSpec: QuickSpec {
    
    override func spec() {
        
        describe("initializing") {
            
            it("should initialize") {
                
            }
            
        }
        
        describe("JSON coding") {
            
            it("should roundtrip") {
                
            }
            
        }
        
        describe("inheritance") {
            
            it("should not inherit properties if a root class") {
                
            }
            
            it("should inherit properties if not a root class") {
                
            }
            
            it("should inherit properties from left-to-right if multiple parents") {
                
            }
            
            it("should override properties with equivalent keys of parent properties") {
                
            }
            
        }
    }
    
}

class AferoTimestampSemanticClassSpec: QuickSpec {
    
    override func spec() {
    }
}
