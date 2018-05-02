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
            
            it("should throw if a referenced parent attribute doesn't exist.") {
                expect(t.semanticClasses.count) == 0
                
                expect {
                    try t ← AferoAttributeSemanticClassDescriptor(identifier: "bar") ← AferoAttributeSemanticClassDescriptor(identifier: "foo", isa: ["foo"])
                    }.to(throwError(AferoSemanticClassError.unrecognizedSemanticClass("foo")))
                
                expect(t.semanticClasses.count) == 1
            }
            
            it("should throw if registering a duplicate class.") {
                expect(t.semanticClasses.count) == 0
                
                expect {
                    try t
                        ← AferoAttributeSemanticClassDescriptor(identifier: "bar")
                        ← AferoAttributeSemanticClassDescriptor(identifier: "bar")
                    }.to(throwError(AferoSemanticClassError.duplicateSemanticClass("bar")))
                
                expect(t.semanticClasses.count) == 1
            }

            
        }
        
        describe("transforming values") {
            
            let registry = AferoSemanticClassTable()
            
            do {
                
                try registry ← AferoAttributeSemanticClassDescriptor(
                    identifier: SemanticClassIdentifier.ISO8601Date,
                    semanticDescription: "A date in ISO8601 format."
                )

                try registry ← AferoAttributeSemanticClassDescriptor(
                    identifier: SemanticClassIdentifier.UNIXEpochDate,
                    semanticDescription: "A date represented by seconds since 01 Jan 1970 00:00:00 UTC"
                )

                try registry ← AferoAttributeSemanticClassDescriptor(
                    identifier: SemanticClassIdentifier.UNIXEpochSecondsDate,
                    isa: [SemanticClassIdentifier.UNIXEpochDate],
                    properties: [
                        SemanticClassPropertyKey.UnitsPerSecond: NSNumber(value: 1.0)
                    ],
                    semanticDescription: "A date represented by seconds since 01 Jan 1970 00:00:00 UTC"
                )
                
                try registry ← AferoAttributeSemanticClassDescriptor(
                    identifier: SemanticClassIdentifier.UNIXEpochMillisecondsDate,
                    isa: [SemanticClassIdentifier.UNIXEpochSecondsDate],
                    properties: [
                        SemanticClassPropertyKey.UnitsPerSecond: NSNumber(value: 1000.0)
                    ],
                    semanticDescription: "A date represented by milliseconds since 01 Jan 1970 00:00:00 UTC"
                )
                
                try registry ← AferoAttributeSemanticClassDescriptor(
                    identifier: SemanticClassIdentifier.UTS35Date,
                    properties: [
                        SemanticClassPropertyKey.UTS35FormatString: "EEE, MMM d, ''yy" as NSString
                    ],
                    semanticDescription: "A date represented only by short day of week, short month, day, and two-digit year."
                )
                
            } catch {
                print(String(reflecting: error))
            }
            
            it("Should have registered all types") {
                expect(registry.semanticClass(for: SemanticClassIdentifier.UNIXEpochSecondsDate)).toNot(beNil())
                expect(registry.transformer(forSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate)).toNot(beNil())
                expect(registry.semanticClass(for: SemanticClassIdentifier.UNIXEpochMillisecondsDate)).toNot(beNil())
                expect(registry.transformer(forSemanticIdentifier: SemanticClassIdentifier.UNIXEpochMillisecondsDate)).toNot(beNil())
                expect(registry.semanticClass(for: SemanticClassIdentifier.UTS35Date)).toNot(beNil())
                expect(registry.transformer(forSemanticIdentifier: SemanticClassIdentifier.UTS35Date)).toNot(beNil())
                expect(registry.semanticClass(for: SemanticClassIdentifier.ISO8601Date)).toNot(beNil())
                expect(registry.transformer(forSemanticIdentifier: SemanticClassIdentifier.ISO8601Date)).toNot(beNil())
            }
            
            let iSecs: Int = 1525121467
            let nsnSecs = NSNumber(value: iSecs)
            let i32Secs = Int32(iSecs)
            let i64Secs = Int64(iSecs)
            let dsecs = Double(iSecs)
            
            let date = Date(timeIntervalSince1970: dsecs)
            
            it("Should transform an integer number of seconds into a date") {
                expect(registry.semanticValue(forNativeValue: iSecs, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: nsnSecs, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: i32Secs, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: i64Secs, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: dsecs, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochSecondsDate) as? Date) == date
            }
            
            it("Should transform a date into an integer number of seconds ") {
                expect(registry.nativeValue(forSemanticValue: date, withSemanticIdentifier:  SemanticClassIdentifier.UNIXEpochSecondsDate) as? NSNumber) == nsnSecs
            }
            
            let iMillis = i64Secs * 1000
            let nsnMillis = NSNumber(value: iMillis)
            let dMillis = nsnMillis.doubleValue
            
            it("Should transform an integer number of milliseconds into a date") {
                expect(registry.semanticValue(forNativeValue: iMillis, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochMillisecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: nsnMillis, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochMillisecondsDate) as? Date) == date
                expect(registry.semanticValue(forNativeValue: dMillis, withSemanticIdentifier: SemanticClassIdentifier.UNIXEpochMillisecondsDate) as? Date) == date
            }
            
            it("Should transform a date into an integer number of milliseconds ") {
                expect(registry.nativeValue(forSemanticValue: date, withSemanticIdentifier:  SemanticClassIdentifier.UNIXEpochMillisecondsDate) as? NSNumber) == nsnMillis
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

