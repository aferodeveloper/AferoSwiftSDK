//
//  DeviceTagTests.swift
//  AferoTests
//
//  Created by Justin Middleton on 11/15/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
@testable import Afero
import Quick
import Nimble

class DeviceTagSpec: QuickSpec {
    
    override func spec() {
        
        let t1 = DeviceTag(id: "id1", key: "key1")
        let t2 = DeviceTag(id: "id2", key: "key2", value: "value2", tagType: .account)
        let t2b = DeviceTag(id: "id2", key: "key2", tagType: .account)
        let t3 = DeviceTag(id: "id3", key: "key3", value: "value3", tagType: .account, localizationKey: "locKey3")
        let t3b = DeviceTag(id: "id3", key: "key3", value: "value3", tagType: .account)

        
        describe("Creating") {
            
            it("should instantiate properly.") {
                expect(t1.id) == "id1"
                expect(t1.key) == "key1"
                expect(t1.value).to(beNil())
                expect(t1.tagType) == DeviceTag.TagType.account
                expect(t1.localizationKey).to(beNil())

                expect(t2.id) == "id2"
                expect(t2.key) == "key2"
                expect(t2.value) == "value2"
                expect(t2.tagType) == DeviceTag.TagType.account
                expect(t2.localizationKey).to(beNil())

                expect(t3.id) == "id3"
                expect(t3.key) == "key3"
                expect(t3.value) == "value3"
                expect(t3.tagType) == DeviceTag.TagType.account
                expect(t3.localizationKey) == "locKey3"
            }
            
        }
        
        describe("Comparing") {
            
            it("should compare properly") {
                expect(t1) == t1
                expect(t1) != t2
                expect(t1) != t2b
                expect(t1) != t3
                expect(t1) != t3b

                expect(t2) != t1
                expect(t2) == t2
                expect(t2) != t2b
                expect(t2) != t3
                expect(t2) != t3b

                expect(t2b) != t1
                expect(t2b) != t2
                expect(t2b) == t2b
                expect(t2b) != t3
                expect(t2b) != t3b
                
                expect(t3) != t1
                expect(t3) != t2
                expect(t3) != t2b
                expect(t3) == t3
                expect(t3) != t3b

                expect(t3b) != t1
                expect(t3b) != t2
                expect(t3) != t2b
                expect(t3b) != t3
                expect(t3b) == t3b
                
            }
            
        }
    }
    
}
