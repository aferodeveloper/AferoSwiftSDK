//
//  DeviceStreamEventTests.swift
//  AferoSwiftConclave
//
//  Created by Justin Middleton on 5/22/17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero


/// Tests marshalling of Conclave Object Sync Proto v2 messages.
/// See https://docs.google.com/document/d/1Q7H5bPggDVllvb6OB0I6iaNr9D23XwdqdMAzAcDYaE0

class DeviceStreamEventTests: QuickSpec {
    
    override func spec() {
        
        // MARK: - DeviceStreamEvent.Peripheral.DeviceTag
        
        describe("DeviceStreamEvent.Peripheral.DeviceTag instances") {
            typealias Tag = DeviceStreamEvent.Peripheral.DeviceTag
            
            let t1 = Tag(id: "id1", value: "value1")
            let t2 = Tag(id: "id2", key: "key2", value: "value2", type: .account)
            let t2b = Tag(id: "id2", value: "value2", type: .account)
            let t3 = Tag(id: "id3", key: "key3", value: "value3", localizationKey: "locKey3", type: .account)
            let t3b = Tag(id: "id3", key: "key3", value: "value3", type: .account)
            
            
            describe("Creating") {
                
                it("should instantiate properly.") {
                    expect(t1.id) == "id1"
                    expect(t1.key).to(beNil())
                    expect(t1.value) == "value1"
                    expect(t1.type) == Tag.TagType.account
                    expect(t1.localizationKey).to(beNil())
                    
                    expect(t2.id) == "id2"
                    expect(t2.key) == "key2"
                    expect(t2.value) == "value2"
                    expect(t2.type) == Tag.TagType.account
                    expect(t2.localizationKey).to(beNil())
                    
                    expect(t3.id) == "id3"
                    expect(t3.key) == "key3"
                    expect(t3.value) == "value3"
                    expect(t3.type) == Tag.TagType.account
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

            it("should roundtrip JSON correclty") {
                let t1a: Tag? = |<t1.JSONDict
                expect(t1a).toNot(beNil())
                expect(t1a) == t1
                
                let t2a: Tag? = |<t2.JSONDict
                expect(t2a).toNot(beNil())
                expect(t2a) == t2
                
                let t2ba: Tag? = |<t2b.JSONDict
                expect(t2ba).toNot(beNil())
                expect(t2ba) == t2b
                
                let t3a: Tag? = |<t3.JSONDict
                expect(t3a).toNot(beNil())
                expect(t3a) == t3

                let t3ba: Tag? = |<t3b.JSONDict
                expect(t3ba).toNot(beNil())
                expect(t3ba) == t3b

            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.Status
        
        describe("DeviceStreamEvent.Peripheral.Status instances") {
            
            let s1 = DeviceStreamEvent.Peripheral.Status()
            
            let s2 = DeviceStreamEvent.Peripheral.Status(isAvailable: true)
            let s2f = DeviceStreamEvent.Peripheral.Status(isAvailable: false)
            
            let s3 = DeviceStreamEvent.Peripheral.Status(isVisible: true)
            let s3f = DeviceStreamEvent.Peripheral.Status(isVisible: false)
            
            let s4 = DeviceStreamEvent.Peripheral.Status(isDirty: true)
            let s4f = DeviceStreamEvent.Peripheral.Status(isDirty: false)
            
            let s5 = DeviceStreamEvent.Peripheral.Status(isConnectable: true)
            let s5f = DeviceStreamEvent.Peripheral.Status(isConnectable: false)
            
            let s6 = DeviceStreamEvent.Peripheral.Status(isConnected: true)
            let s6f = DeviceStreamEvent.Peripheral.Status(isConnected: false)
            
            let s7 = DeviceStreamEvent.Peripheral.Status(isRebooted: true)
            let s7f = DeviceStreamEvent.Peripheral.Status(isRebooted: false)
            
            let s8 = DeviceStreamEvent.Peripheral.Status(isDirect: true)
            let s8f = DeviceStreamEvent.Peripheral.Status(isDirect: false)
            
            let s9 = DeviceStreamEvent.Peripheral.Status(RSSI: 100)

            // MARK: .. should initialize
            
            it("should initialize properly") {
                
                expect(s1.isAvailable).to(beNil())
                expect(s1.isVisible).to(beNil())
                expect(s1.isConnected).to(beNil())
                expect(s1.isDirect).to(beNil())
                expect(s1.isDirty).to(beNil())
                expect(s1.isRebooted).to(beNil())
                expect(s1.isConnectable).to(beNil())
                expect(s1.RSSI).to(beNil())

                expect(s2.isAvailable).to(beTrue())
                expect(s2.isVisible).to(beNil())
                expect(s2.isConnected).to(beNil())
                expect(s2.isDirect).to(beNil())
                expect(s2.isDirty).to(beNil())
                expect(s2.isRebooted).to(beNil())
                expect(s2.isConnectable).to(beNil())
                expect(s2.RSSI).to(beNil())

                expect(s2f.isAvailable).to(beFalse())
                expect(s2f.isVisible).to(beNil())
                expect(s2f.isConnected).to(beNil())
                expect(s2f.isDirect).to(beNil())
                expect(s2f.isDirty).to(beNil())
                expect(s2f.isRebooted).to(beNil())
                expect(s2f.isConnectable).to(beNil())
                expect(s2f.RSSI).to(beNil())

                expect(s3.isAvailable).to(beNil())
                expect(s3.isVisible).to(beTrue())
                expect(s3.isConnected).to(beNil())
                expect(s3.isDirect).to(beNil())
                expect(s3.isDirty).to(beNil())
                expect(s3.isRebooted).to(beNil())
                expect(s3.isConnectable).to(beNil())
                expect(s3.RSSI).to(beNil())
                
                expect(s3f.isAvailable).to(beNil())
                expect(s3f.isVisible).to(beFalse())
                expect(s3f.isConnected).to(beNil())
                expect(s3f.isDirect).to(beNil())
                expect(s3f.isDirty).to(beNil())
                expect(s3f.isRebooted).to(beNil())
                expect(s3f.isConnectable).to(beNil())
                expect(s3f.RSSI).to(beNil())
                
                expect(s4.isAvailable).to(beNil())
                expect(s4.isVisible).to(beNil())
                expect(s4.isConnected).to(beNil())
                expect(s4.isDirect).to(beNil())
                expect(s4.isDirty).to(beTrue())
                expect(s4.isRebooted).to(beNil())
                expect(s4.isConnectable).to(beNil())
                expect(s4.RSSI).to(beNil())
                
                expect(s4f.isAvailable).to(beNil())
                expect(s4f.isVisible).to(beNil())
                expect(s4f.isConnected).to(beNil())
                expect(s4f.isDirect).to(beNil())
                expect(s4f.isDirty).to(beFalse())
                expect(s4f.isRebooted).to(beNil())
                expect(s4f.isConnectable).to(beNil())
                expect(s4f.RSSI).to(beNil())
                
                expect(s5.isAvailable).to(beNil())
                expect(s5.isVisible).to(beNil())
                expect(s5.isConnected).to(beNil())
                expect(s5.isDirect).to(beNil())
                expect(s5.isDirty).to(beNil())
                expect(s5.isRebooted).to(beNil())
                expect(s5.isConnectable).to(beTrue())
                expect(s5.RSSI).to(beNil())
                
                expect(s5f.isAvailable).to(beNil())
                expect(s5f.isVisible).to(beNil())
                expect(s5f.isConnected).to(beNil())
                expect(s5f.isDirect).to(beNil())
                expect(s5f.isDirty).to(beNil())
                expect(s5f.isRebooted).to(beNil())
                expect(s5f.isConnectable).to(beFalse())
                expect(s5f.RSSI).to(beNil())
                
                expect(s6.isAvailable).to(beNil())
                expect(s6.isVisible).to(beNil())
                expect(s6.isConnected).to(beTrue())
                expect(s6.isDirect).to(beNil())
                expect(s6.isDirty).to(beNil())
                expect(s6.isRebooted).to(beNil())
                expect(s6.isConnectable).to(beNil())
                expect(s6.RSSI).to(beNil())
                
                expect(s6f.isAvailable).to(beNil())
                expect(s6f.isVisible).to(beNil())
                expect(s6f.isConnected).to(beFalse())
                expect(s6f.isDirect).to(beNil())
                expect(s6f.isDirty).to(beNil())
                expect(s6f.isRebooted).to(beNil())
                expect(s6f.isConnectable).to(beNil())
                expect(s6f.RSSI).to(beNil())
                
                expect(s7.isAvailable).to(beNil())
                expect(s7.isVisible).to(beNil())
                expect(s7.isConnected).to(beNil())
                expect(s7.isDirect).to(beNil())
                expect(s7.isDirty).to(beNil())
                expect(s7.isRebooted).to(beTrue())
                expect(s7.isConnectable).to(beNil())
                expect(s7.RSSI).to(beNil())
                
                expect(s7f.isAvailable).to(beNil())
                expect(s7f.isVisible).to(beNil())
                expect(s7f.isConnected).to(beNil())
                expect(s7f.isDirect).to(beNil())
                expect(s7f.isDirty).to(beNil())
                expect(s7f.isRebooted).to(beFalse())
                expect(s7f.isConnectable).to(beNil())
                expect(s7f.RSSI).to(beNil())
                
                expect(s8.isAvailable).to(beNil())
                expect(s8.isVisible).to(beNil())
                expect(s8.isConnected).to(beNil())
                expect(s8.isDirect).to(beTrue())
                expect(s8.isDirty).to(beNil())
                expect(s8.isRebooted).to(beNil())
                expect(s8.isConnectable).to(beNil())
                expect(s8.RSSI).to(beNil())
                
                expect(s8f.isAvailable).to(beNil())
                expect(s8f.isVisible).to(beNil())
                expect(s8f.isConnected).to(beNil())
                expect(s8f.isDirect).to(beFalse())
                expect(s8f.isDirty).to(beNil())
                expect(s8f.isRebooted).to(beNil())
                expect(s8f.isConnectable).to(beNil())
                expect(s8f.RSSI).to(beNil())
                
                expect(s9.isAvailable).to(beNil())
                expect(s9.isVisible).to(beNil())
                expect(s9.isConnected).to(beNil())
                expect(s9.isDirect).to(beNil())
                expect(s9.isDirty).to(beNil())
                expect(s9.isRebooted).to(beNil())
                expect(s9.isConnectable).to(beNil())
                expect(s9.RSSI) == 100
            }
            
            // MARK: .. should compare
            
            it("should compare properly") {
                expect(s1).to(equal(s1))
                expect(s1).toNot(equal(s2))
                expect(s1).toNot(equal(s2f))
                expect(s1).toNot(equal(s3))
                expect(s1).toNot(equal(s3f))
                expect(s1).toNot(equal(s4))
                expect(s1).toNot(equal(s4f))
                expect(s1).toNot(equal(s5))
                expect(s1).toNot(equal(s5f))
                expect(s1).toNot(equal(s6))
                expect(s1).toNot(equal(s6f))
                expect(s1).toNot(equal(s7))
                expect(s1).toNot(equal(s7f))
                expect(s1).toNot(equal(s8))
                expect(s1).toNot(equal(s8f))
                expect(s1).toNot(equal(s9))

                expect(s2).toNot(equal(s1))
                expect(s2).to(equal(s2))
                expect(s2).toNot(equal(s2f))
                expect(s2).toNot(equal(s3))
                expect(s2).toNot(equal(s3f))
                expect(s2).toNot(equal(s4))
                expect(s2).toNot(equal(s4f))
                expect(s2).toNot(equal(s5))
                expect(s2).toNot(equal(s5f))
                expect(s2).toNot(equal(s6))
                expect(s2).toNot(equal(s6f))
                expect(s2).toNot(equal(s7))
                expect(s2).toNot(equal(s7f))
                expect(s2).toNot(equal(s8))
                expect(s2).toNot(equal(s8f))
                expect(s2).toNot(equal(s9))

                expect(s2f).toNot(equal(s1))
                expect(s2f).toNot(equal(s2))
                expect(s2f).to(equal(s2f))
                expect(s2f).toNot(equal(s3))
                expect(s2f).toNot(equal(s3f))
                expect(s2f).toNot(equal(s4))
                expect(s2f).toNot(equal(s4f))
                expect(s2f).toNot(equal(s5))
                expect(s2f).toNot(equal(s5f))
                expect(s2f).toNot(equal(s6))
                expect(s2f).toNot(equal(s6f))
                expect(s2f).toNot(equal(s7))
                expect(s2f).toNot(equal(s7f))
                expect(s2f).toNot(equal(s8))
                expect(s2f).toNot(equal(s8f))
                expect(s2f).toNot(equal(s9))
                
                expect(s3).toNot(equal(s1))
                expect(s3).toNot(equal(s2))
                expect(s3).toNot(equal(s2f))
                expect(s3).to(equal(s3))
                expect(s3).toNot(equal(s3f))
                expect(s3).toNot(equal(s4))
                expect(s3).toNot(equal(s4f))
                expect(s3).toNot(equal(s5))
                expect(s3).toNot(equal(s5f))
                expect(s3).toNot(equal(s6))
                expect(s3).toNot(equal(s6f))
                expect(s3).toNot(equal(s7))
                expect(s3).toNot(equal(s7f))
                expect(s3).toNot(equal(s8))
                expect(s3).toNot(equal(s8f))
                expect(s3).toNot(equal(s9))
                
                expect(s3f).toNot(equal(s1))
                expect(s3f).toNot(equal(s2))
                expect(s3f).toNot(equal(s2f))
                expect(s3f).toNot(equal(s3))
                expect(s3f).to(equal(s3f))
                expect(s3f).toNot(equal(s4))
                expect(s3f).toNot(equal(s4f))
                expect(s3f).toNot(equal(s5))
                expect(s3f).toNot(equal(s5f))
                expect(s3f).toNot(equal(s6))
                expect(s3f).toNot(equal(s6f))
                expect(s3f).toNot(equal(s7))
                expect(s3f).toNot(equal(s7f))
                expect(s3f).toNot(equal(s8))
                expect(s3f).toNot(equal(s8f))
                expect(s3f).toNot(equal(s9))
                
                expect(s4).toNot(equal(s1))
                expect(s4).toNot(equal(s2))
                expect(s4).toNot(equal(s2f))
                expect(s4).toNot(equal(s3))
                expect(s4).toNot(equal(s3f))
                expect(s4).to(equal(s4))
                expect(s4).toNot(equal(s4f))
                expect(s4).toNot(equal(s5))
                expect(s4).toNot(equal(s5f))
                expect(s4).toNot(equal(s6))
                expect(s4).toNot(equal(s6f))
                expect(s4).toNot(equal(s7))
                expect(s4).toNot(equal(s7f))
                expect(s4).toNot(equal(s8))
                expect(s4).toNot(equal(s8f))
                expect(s4).toNot(equal(s9))
                
                expect(s4f).toNot(equal(s1))
                expect(s4f).toNot(equal(s2))
                expect(s4f).toNot(equal(s2f))
                expect(s4f).toNot(equal(s3))
                expect(s4f).toNot(equal(s3f))
                expect(s4f).toNot(equal(s4))
                expect(s4f).to(equal(s4f))
                expect(s4f).toNot(equal(s5))
                expect(s4f).toNot(equal(s5f))
                expect(s4f).toNot(equal(s6))
                expect(s4f).toNot(equal(s6f))
                expect(s4f).toNot(equal(s7))
                expect(s4f).toNot(equal(s7f))
                expect(s4f).toNot(equal(s8))
                expect(s4f).toNot(equal(s8f))
                expect(s4f).toNot(equal(s9))
                
                expect(s5).toNot(equal(s1))
                expect(s5).toNot(equal(s2))
                expect(s5).toNot(equal(s2f))
                expect(s5).toNot(equal(s3))
                expect(s5).toNot(equal(s3f))
                expect(s5).toNot(equal(s4))
                expect(s5).toNot(equal(s4f))
                expect(s5).to(equal(s5))
                expect(s5).toNot(equal(s5f))
                expect(s5).toNot(equal(s6))
                expect(s5).toNot(equal(s6f))
                expect(s5).toNot(equal(s7))
                expect(s5).toNot(equal(s7f))
                expect(s5).toNot(equal(s8))
                expect(s5).toNot(equal(s8f))
                expect(s5).toNot(equal(s9))
                
                expect(s5f).toNot(equal(s1))
                expect(s5f).toNot(equal(s2))
                expect(s5f).toNot(equal(s2f))
                expect(s5f).toNot(equal(s3))
                expect(s5f).toNot(equal(s3f))
                expect(s5f).toNot(equal(s4))
                expect(s5f).toNot(equal(s4f))
                expect(s5f).toNot(equal(s5))
                expect(s5f).to(equal(s5f))
                expect(s5f).toNot(equal(s6))
                expect(s5f).toNot(equal(s6f))
                expect(s5f).toNot(equal(s7))
                expect(s5f).toNot(equal(s7f))
                expect(s5f).toNot(equal(s8))
                expect(s5f).toNot(equal(s8f))
                expect(s5f).toNot(equal(s9))
                
                expect(s6).toNot(equal(s1))
                expect(s6).toNot(equal(s2))
                expect(s6).toNot(equal(s2f))
                expect(s6).toNot(equal(s3))
                expect(s6).toNot(equal(s3f))
                expect(s6).toNot(equal(s4))
                expect(s6).toNot(equal(s4f))
                expect(s6).toNot(equal(s5))
                expect(s6).toNot(equal(s5f))
                expect(s6).to(equal(s6))
                expect(s6).toNot(equal(s6f))
                expect(s6).toNot(equal(s7))
                expect(s6).toNot(equal(s7f))
                expect(s6).toNot(equal(s8))
                expect(s6).toNot(equal(s8f))
                expect(s6).toNot(equal(s9))
                
                expect(s6f).toNot(equal(s1))
                expect(s6f).toNot(equal(s2))
                expect(s6f).toNot(equal(s2f))
                expect(s6f).toNot(equal(s3))
                expect(s6f).toNot(equal(s3f))
                expect(s6f).toNot(equal(s4))
                expect(s6f).toNot(equal(s4f))
                expect(s6f).toNot(equal(s5))
                expect(s6f).toNot(equal(s5f))
                expect(s6f).toNot(equal(s6))
                expect(s6f).to(equal(s6f))
                expect(s6f).toNot(equal(s7))
                expect(s6f).toNot(equal(s7f))
                expect(s6f).toNot(equal(s8))
                expect(s6f).toNot(equal(s8f))
                expect(s6f).toNot(equal(s9))
                
                expect(s7).toNot(equal(s1))
                expect(s7).toNot(equal(s2))
                expect(s7).toNot(equal(s2f))
                expect(s7).toNot(equal(s3))
                expect(s7).toNot(equal(s3f))
                expect(s7).toNot(equal(s4))
                expect(s7).toNot(equal(s4f))
                expect(s7).toNot(equal(s5))
                expect(s7).toNot(equal(s5f))
                expect(s7).toNot(equal(s6))
                expect(s7).toNot(equal(s6f))
                expect(s7).to(equal(s7))
                expect(s7).toNot(equal(s7f))
                expect(s7).toNot(equal(s8))
                expect(s7).toNot(equal(s8f))
                expect(s7).toNot(equal(s9))
                
                expect(s7f).toNot(equal(s1))
                expect(s7f).toNot(equal(s2))
                expect(s7f).toNot(equal(s2f))
                expect(s7f).toNot(equal(s3))
                expect(s7f).toNot(equal(s3f))
                expect(s7f).toNot(equal(s4))
                expect(s7f).toNot(equal(s4f))
                expect(s7f).toNot(equal(s5))
                expect(s7f).toNot(equal(s5f))
                expect(s7f).toNot(equal(s6))
                expect(s7f).toNot(equal(s6f))
                expect(s7f).toNot(equal(s7))
                expect(s7f).to(equal(s7f))
                expect(s7f).toNot(equal(s8))
                expect(s7f).toNot(equal(s8f))
                expect(s7f).toNot(equal(s9))
                
                expect(s8).toNot(equal(s1))
                expect(s8).toNot(equal(s2))
                expect(s8).toNot(equal(s2f))
                expect(s8).toNot(equal(s3))
                expect(s8).toNot(equal(s3f))
                expect(s8).toNot(equal(s4))
                expect(s8).toNot(equal(s4f))
                expect(s8).toNot(equal(s5))
                expect(s8).toNot(equal(s5f))
                expect(s8).toNot(equal(s6))
                expect(s8).toNot(equal(s6f))
                expect(s8).toNot(equal(s7))
                expect(s8).toNot(equal(s7f))
                expect(s8).to(equal(s8))
                expect(s8).toNot(equal(s8f))
                expect(s8).toNot(equal(s9))
                
                expect(s8f).toNot(equal(s1))
                expect(s8f).toNot(equal(s2))
                expect(s8f).toNot(equal(s2f))
                expect(s8f).toNot(equal(s3))
                expect(s8f).toNot(equal(s3f))
                expect(s8f).toNot(equal(s4))
                expect(s8f).toNot(equal(s4f))
                expect(s8f).toNot(equal(s5))
                expect(s8f).toNot(equal(s5f))
                expect(s8f).toNot(equal(s6))
                expect(s8f).toNot(equal(s6f))
                expect(s8f).toNot(equal(s7))
                expect(s8f).toNot(equal(s7f))
                expect(s8f).toNot(equal(s8))
                expect(s8f).to(equal(s8f))
                expect(s8f).toNot(equal(s9))
                
                expect(s9).toNot(equal(s1))
                expect(s9).toNot(equal(s2))
                expect(s9).toNot(equal(s2f))
                expect(s9).toNot(equal(s3))
                expect(s9).toNot(equal(s3f))
                expect(s9).toNot(equal(s4))
                expect(s9).toNot(equal(s4f))
                expect(s9).toNot(equal(s5))
                expect(s9).toNot(equal(s5f))
                expect(s9).toNot(equal(s6))
                expect(s9).toNot(equal(s6f))
                expect(s9).toNot(equal(s7))
                expect(s9).toNot(equal(s7f))
                expect(s9).toNot(equal(s8))
                expect(s9).toNot(equal(s8f))
                expect(s9).to(equal(s9))
            }
            
            // MARK: .. should JSON-roundtrip
            
            it("should JSON-roundtrip properly") {

                let s1b: DeviceStreamEvent.Peripheral.Status? = |<s1.JSONDict
                expect(s1b) == s1

                let s2b: DeviceStreamEvent.Peripheral.Status? = |<s2.JSONDict
                expect(s2b) == s2

                let s2fb: DeviceStreamEvent.Peripheral.Status? = |<s2f.JSONDict
                expect(s2fb) == s2f
                
                let s3b: DeviceStreamEvent.Peripheral.Status? = |<s3.JSONDict
                expect(s3b) == s3
                
                let s3fb: DeviceStreamEvent.Peripheral.Status? = |<s3f.JSONDict
                expect(s3fb) == s3f
                
                let s4b: DeviceStreamEvent.Peripheral.Status? = |<s4.JSONDict
                expect(s4b) == s4
                
                let s4fb: DeviceStreamEvent.Peripheral.Status? = |<s4f.JSONDict
                expect(s4fb) == s4f
                
                let s5b: DeviceStreamEvent.Peripheral.Status? = |<s5.JSONDict
                expect(s5b) == s5
                
                let s5fb: DeviceStreamEvent.Peripheral.Status? = |<s5f.JSONDict
                expect(s5fb) == s5f
                
                let s6b: DeviceStreamEvent.Peripheral.Status? = |<s6.JSONDict
                expect(s6b) == s6
                
                let s6fb: DeviceStreamEvent.Peripheral.Status? = |<s6f.JSONDict
                expect(s6fb) == s6f
                
                let s7b: DeviceStreamEvent.Peripheral.Status? = |<s7.JSONDict
                expect(s7b) == s7
                
                let s7fb: DeviceStreamEvent.Peripheral.Status? = |<s7f.JSONDict
                expect(s7fb) == s7f

                let s8b: DeviceStreamEvent.Peripheral.Status? = |<s8.JSONDict
                expect(s8b) == s8
                
                let s8fb: DeviceStreamEvent.Peripheral.Status? = |<s8f.JSONDict
                expect(s8fb) == s8f

                let s9b: DeviceStreamEvent.Peripheral.Status? = |<s9.JSONDict
                expect(s9b) == s9
                
            }
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.Attribute
        
        describe("DeviceStreamEvent.Peripheral.Attribute instances") {
            
            let a1a = DeviceStreamEvent.Peripheral.Attribute(attributeId: 1, value: "1", data: "0100")
            let a1b = DeviceStreamEvent.Peripheral.Attribute(attributeId: 1, value: "2", data: "0200")

            let a2a = DeviceStreamEvent.Peripheral.Attribute(attributeId: 2, value: "2", data: "0200")
            
            // MARK: .. should initialize
            
            it("should initialize properly") {
                expect(a1a.attributeId) == 1
                expect(a1a.data) == "0100"
                expect(a1a.stringValue) == "1"

                expect(a1b.attributeId) == 1
                expect(a1b.data) == "0200"
                expect(a1b.stringValue) == "2"

                expect(a2a.attributeId) == 2
                expect(a2a.data) == "0200"
                expect(a2a.stringValue) == "2"
            }
            
            // MARK: .. should compare
            
            it("should compare properly") {
                expect(a1a) == a1a
                expect(a1a) != a1b
                expect(a1a) != a2a

                expect(a1b) != a1a
                expect(a1b) == a1b
                expect(a1b) != a2a

                expect(a2a) != a1a
                expect(a2a) != a1b
                expect(a2a) == a2a
            }
            
            // MARK: .. should JSON-roundtrip
            
            it("should JSON-roundtrip properly") {
                
                let a1aa: DeviceStreamEvent.Peripheral.Attribute? = |<a1a.JSONDict
                expect(a1aa) == a1a

                let a1ba: DeviceStreamEvent.Peripheral.Attribute? = |<a1b.JSONDict
                expect(a1ba) == a1b

                let a2aa: DeviceStreamEvent.Peripheral.Attribute? = |<a2a.JSONDict
                expect(a2aa) == a2a

            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.LocationState.Location
        
        describe("DeviceStreamEvent.Peripheral.LocationState.Location instances") {

            typealias Location = DeviceStreamEvent.Peripheral.LocationState.Location
            typealias Source = Location.Source
            
            let l1 = Location(latitude: 23.0, longitude: 25.0, source: .initialDeviceAssociate)
            let l2 = Location(latitude: 23.0, longitude: 25.0, altitude: 1000, source: .initialDeviceAssociate)
            let l3 = Location(latitude: 19.0, longitude: 55.0, horizontalAccuracy: 70, source: .hubLocationGPS)
            let l4 = Location(latitude: 19.0, longitude: 55.0, altitude: 10_000, horizontalAccuracy: 70, verticalAccuracy: 90,  source: .userDefinedLocation)
            
            // MARK: .. should initialize

            it("should initialize properly") {
                expect(l1.latitude) == 23.0
                expect(l1.longitude) == 25.0
                expect(l1.altitude).to(beNil())
                expect(l1.horizontalAccuracy).to(beNil())
                expect(l1.verticalAccuracy).to(beNil())
                expect(l1.source) == Source.initialDeviceAssociate
                
                expect(l2.latitude) == 23.0
                expect(l2.longitude) == 25.0
                expect(l2.altitude) == 1000
                expect(l2.horizontalAccuracy).to(beNil())
                expect(l2.verticalAccuracy).to(beNil())
                expect(l2.source) == Source.initialDeviceAssociate
                
                expect(l3.latitude) == 19
                expect(l3.longitude) == 55
                expect(l3.altitude).to(beNil())
                expect(l3.horizontalAccuracy) == 70
                expect(l3.verticalAccuracy).to(beNil())
                expect(l3.source) == Source.hubLocationGPS

                expect(l4.latitude) == 19.0
                expect(l4.longitude) == 55.0
                expect(l4.altitude) == 10_000
                expect(l4.horizontalAccuracy) == 70
                expect(l4.verticalAccuracy) == 90
                expect(l4.source) == Source.userDefinedLocation

            }
            
            // MARK: .. should compare

            it("should compare properly") {
                
                expect(l1) == l1
                expect(l1) != l2
                expect(l1) != l3
                expect(l1) != l4
                
                expect(l2) != l1
                expect(l2) == l2
                expect(l2) != l3
                expect(l2) != l4
                
                expect(l3) != l1
                expect(l3) != l2
                expect(l3) == l3
                expect(l3) != l4
                
                expect(l4) != l1
                expect(l4) != l2
                expect(l4) != l3
                expect(l4) == l4
                
            }
            
            // MARK: .. should JSON-roundtrip

            it("should roundtrip JSON properly") {
                
                let l1a: Location? = |<l1.JSONDict
                expect(l1a).toNot(beNil())
                expect(l1a) == l1

                let l2a: Location? = |<l2.JSONDict
                expect(l2a).toNot(beNil())
                expect(l2a) == l2

                let l3a: Location? = |<l3.JSONDict
                expect(l3a).toNot(beNil())
                expect(l3a) == l3

                let l4a: Location? = |<l4.JSONDict
                expect(l4a).toNot(beNil())
                expect(l4a) == l4

            }
        }
        
        // MARK: - DeviceStreamEvent.Peripheral.UpdateState
        
        describe("DeviceStreamEvent.Peripheral.UpdateState") {
            
            typealias UpdateState = DeviceStreamEvent.Peripheral.UpdateState
            
            it("should instantiate correctly") {
                let updated = UpdateState(maybeStateCode: 0)
                expect(updated) == UpdateState.updated
                expect(updated?.code) == 0
                
                let interrupted = UpdateState(maybeStateCode: 1)
                expect(interrupted) == UpdateState.interrupted
                expect(interrupted?.code) == 1

                let unknownUUID = UpdateState(maybeStateCode: 2)
                expect(unknownUUID) == UpdateState.unknownAttribute
                expect(unknownUUID?.code) == 2
                
                let lengthExceeded = UpdateState(maybeStateCode: 3)
                expect(lengthExceeded) == UpdateState.lengthExceeded
                expect(lengthExceeded?.code) == 3
                
                let conflict = UpdateState(maybeStateCode: 4)
                expect(conflict) == UpdateState.conflict
                expect(conflict?.code) == 4
                
                let timeout = UpdateState(maybeStateCode: 5)
                expect(timeout) == UpdateState.timeout
                expect(timeout?.code) == 5
                
                expect(UpdateState(maybeStateCode: -1)).to(beNil())
            }
            
        }

        // MARK: - DeviceStreamEvent.Peripheral.UpdateReason

        describe("DeviceStreamEvent.Peripheral.UpdateReason") {
            
            typealias Reason = DeviceStreamEvent.Peripheral.UpdateReason
            
            it("should instantiate correctly") {
                let unknown = Reason(maybeReasonCode: 0)
                expect(unknown) == Reason.unknown
                expect(unknown?.code) == 0
                
                let unsolicited = Reason(maybeReasonCode: 1)
                expect(unsolicited) == Reason.unsolicited
                expect(unsolicited?.code) == 1
                
                let serviceInitiated = Reason(maybeReasonCode: 2)
                expect(serviceInitiated) == Reason.serviceInitiated
                expect(serviceInitiated?.code) == 2
                
                let mcuInitiated = Reason(maybeReasonCode: 3)
                expect(mcuInitiated) == Reason.mcuInitiated
                expect(mcuInitiated?.code) == 3
                
                let linkingCompleted = Reason(maybeReasonCode: 4)
                expect(linkingCompleted) == Reason.linkingCompleted
                expect(linkingCompleted?.code) == 4
                
                let boundAttributeChanged = Reason(maybeReasonCode: 5)
                expect(boundAttributeChanged) == Reason.boundAttributeChanged
                expect(boundAttributeChanged?.code) == 5

                let fake = Reason(maybeReasonCode: 6)
                expect(fake) == Reason.fake
                expect(fake?.code) == 6

                expect(Reason(maybeReasonCode: -1)).to(beNil())
            }
            
        }
        
        // MARK: - DeviceStreamEvent.Peripheral
        
        describe("DeviceStreamEvent.Peripheral instances") {

            typealias Attribute = DeviceStreamEvent.Peripheral.Attribute
            typealias Status = DeviceStreamEvent.Peripheral.Status
            typealias Tag = DeviceStreamEvent.Peripheral.DeviceTag
            
            typealias LocationState = DeviceStreamEvent.Peripheral.LocationState
            typealias Location = LocationState.Location
            typealias Source = Location.Source

            let l1 = Location(latitude: 23.0, longitude: 25.0, source: .initialDeviceAssociate)
            let l2 = Location(latitude: 23.0, longitude: 25.0, altitude: 1000, source: .initialDeviceAssociate)
            let l3 = Location(latitude: 19.0, longitude: 55.0, horizontalAccuracy: 70, source: .hubLocationGPS)
            let l4 = Location(latitude: 19.0, longitude: 55.0, altitude: 10_000, horizontalAccuracy: 70, verticalAccuracy: 90,  source: .userDefinedLocation)

            let p1 = DeviceStreamEvent.Peripheral(
                id: "peripheralId1",
                profileId: "profileId1",
                attributes: [
                    Attribute(attributeId: 21, value: "1", data: "0100"),
                    Attribute(attributeId: 22, value: "2", data: "0200"),
                    Attribute(attributeId: 23, value: "3", data: "0300"),
                ],
                status: Status(isAvailable: true, isVisible: true),
                friendlyName: "friendlyName1",
                virtual: true,
                locationState: .known(l1),
                tags: [
                    Tag(id: "tag1", value: "tag1Value", localizationKey: "tag1LocKey"),
                ],
                createdTimestampMs: NSNumber(value: Int64.max)
            )
            
            let p2 = DeviceStreamEvent.Peripheral(
                id: "peripheralId2",
                profileId: "profileId2",
                attributes: [
                    Attribute(attributeId: 4, value: "0400", data: "4"),
                    Attribute(attributeId: 5, value: "0500", data: "5"),
                    Attribute(attributeId: 6, value: "0600", data: "6"),
                ],
                status: Status(isAvailable: true, isVisible: true),
                friendlyName: "friendlyName2",
                virtual: true,
                locationState: .known(l2),
                tags: [
                    Tag(id: "tag2", value: "tag2Value", localizationKey: "tag2LocKey"),
                    ],
                createdTimestampMs: NSNumber(value: Int64.max - 1)
            )
            
            let p3 = DeviceStreamEvent.Peripheral(
                id: "peripheralId3",
                profileId: "profileId3",
                attributes: [
                    Attribute(attributeId: 7, value: "0700", data: "7"),
                    Attribute(attributeId: 8, value: "0800", data: "8"),
                    Attribute(attributeId: 9, value: "0900", data: "9"),
                ],
                status: Status(isAvailable: true, isVisible: true),
                friendlyName: "friendlyName3",
                virtual: true,
                locationState: .known(l3),
                tags: [
                    Tag(id: "tag3", value: "tag3Value", localizationKey: "tag3LocKey"),
                    ],
                createdTimestampMs: NSNumber(value: Int64.max - 2)
            )
            
            let p4 = DeviceStreamEvent.Peripheral(
                id: "peripheralId4",
                profileId: "profileId4",
                attributes: [
                    Attribute(attributeId: 10, value: "0a00", data: "10"),
                    Attribute(attributeId: 11, value: "0b00", data: "11"),
                    Attribute(attributeId: 12, value: "0c00", data: "12"),
                ],
                status: Status(isAvailable: true, isVisible: true),
                friendlyName: "friendlyName4",
                virtual: true,
                locationState: .known(l4),
                tags: [
                    Tag(id: "tag4", value: "tag4Value", localizationKey: "tag4LocKey"),
                    ],
                createdTimestampMs: NSNumber(value: Int64.max - 3)
            )
            
            let p5 = DeviceStreamEvent.Peripheral(
                id: "peripheralId5",
                profileId: "profileId5",
                attributes: [
                    Attribute(attributeId: 13, value: "0d00", data: "13"),
                    Attribute(attributeId: 14, value: "0e00", data: "14"),
                    Attribute(attributeId: 15, value: "0f00", data: "15"),
                ],
                status: Status(isAvailable: true, isVisible: true),
                friendlyName: "friendlyName5",
                virtual: true,
                tags: [
                    Tag(id: "tag5", value: "tag5Value", localizationKey: "tag5LocKey"),
                    ],
                createdTimestampMs: NSNumber(value: Int64.max - 4)
            )
            
            // MARK: .. should instantiate

            it("should instantiate correctly") {
                
                expect(p1.id) == "peripheralId1"
                expect(p1.profileId) == "profileId1"
                expect(p1.attributes.count) == 3
                expect(p1.attribute(for: 21)) == Attribute(attributeId: 21, value: "1", data: "0100")
                expect(p1.attribute(for: 22)) == Attribute(attributeId: 22, value: "2", data: "0200")
                expect(p1.attribute(for: 23)) == Attribute(attributeId: 23, value: "3", data: "0300")
                expect(p1.attribute(for: 0)).to(beNil())
                expect(p1.status) == Status(isAvailable: true, isVisible: true)
                expect(p1.status.isAvailable).to(beTrue())
                expect(p1.status.isVisible).to(beTrue())
                expect(p1.friendlyName) == "friendlyName1"
                expect(p1.virtual) == true
                expect(p1.tags.count) == 1
                expect(p1.tags[0].value) == "tag1Value"
                expect(p1.locationState) == LocationState.known(l1)
                expect(p1.createdTimestampMs) == NSNumber(value: Int64.max)
                
            }
            
            // MARK: .. should compare
            
            it("should compare correctly") {
                expect(p1) == p1
                expect(p1) != p2
                expect(p1) != p3
                expect(p1) != p4
                expect(p1) != p5

                expect(p2) == p2
                expect(p2) != p1
                expect(p2) != p3
                expect(p2) != p4
                expect(p2) != p5

                expect(p3) == p3
                expect(p3) != p1
                expect(p3) != p2
                expect(p3) != p4
                expect(p3) != p5
                
                expect(p4) == p4
                expect(p4) != p1
                expect(p4) != p2
                expect(p4) != p3
                expect(p4) != p5
            }
            
            // MARK: .. should JSON-roundtrip
            
            it("should JSON-roundtrip correctly") {
                
                let p1dict = p1.JSONDict
                
                let p1b: DeviceStreamEvent.Peripheral? = |<p1dict
                expect(p1b).toNot(beNil())
                expect(p1b?.id) == p1.id
                expect(p1b?.profileId) == p1.profileId
                expect(p1b?.attributes) == p1.attributes
                expect(p1b?.friendlyName) == p1.friendlyName
                expect(p1b?.status) == p1.status
                expect(p1b?.createdTimestampMs) == p1.createdTimestampMs
                expect(p1b?.virtual) == p1.virtual
                expect(p1b?.tags) == p1.tags
                expect(p1b?.locationState) == p1.locationState
            }
            
            // MARK: .. should get/set attributes correctly
            
            it("should get/set attributes correctly") {
                
                var p1var = p1
                expect(p1var.attribute(for: 21)) == Attribute(attributeId: 21, value: "1", data: "0100")
                expect(p1var.attribute(for: 22)) == Attribute(attributeId: 22, value: "2", data: "0200")
                expect(p1var.attribute(for: 23)) == Attribute(attributeId: 23, value: "3", data: "0300")
                
                let p1var_21_new = Attribute(attributeId: 21, value: "241", data: "F100")
                let p1var_21_old = p1var.setAttribute(p1var_21_new)
                expect(p1var.attribute(for: 21)) == p1var_21_new
                expect(p1var_21_old?.attributeId) == 21
                expect(p1var_21_old?.data) == "0100"
                expect(p1var_21_old?.stringValue) == "1"
                
                let p1var_0_new = Attribute(attributeId: 0, value: "240", data: "F000")
                expect(p1var.attribute(for: 0)).to(beNil())
                expect(p1var.setAttribute(p1var_0_new)).to(beNil())
                expect(p1var.attribute(for: 0)) == p1var_0_new
                
                let p1var_0_new2 = Attribute(attributeId: 0, value: "208", data: "D000")
                expect(p1var.setAttribute(p1var_0_new2)) == p1var_0_new
                expect(p1var.attribute(for: 0)) == p1var_0_new2

                expect(p1var.removeAttribute(for: 0)) == p1var_0_new2
                expect(p1var.attribute(for: 0)).to(beNil())
                
            }
            
        }
        
        // MARK: - DeviceStreamEvent.OTAPackageInfo
        
        describe("DeviceStreamEvent.OTAPackageInfo") {
            
            let p1 = DeviceStreamEvent.OTAPackageInfo(
                packageTypeId: 1,
                packageName: "package1Name",
                version: "package1Version",
                versionNumber: "package1VersionNumber",
                downloadURL: "package1DownloadURL"
            )

            let p2 = DeviceStreamEvent.OTAPackageInfo(
                packageTypeId: 2,
                packageName: "package2Name",
                version: "package2Version",
                versionNumber: "package2VersionNumber",
                downloadURL: "package2DownloadURL"
            )

            // MARK: .. should instantiate
            
            it("should instantiate properly") {
                expect(p1.packageTypeId) == 1
                expect(p1.packageName) == "package1Name"
                expect(p1.version) == "package1Version"
                expect(p1.versionNumber) == "package1VersionNumber"
                expect(p1.downloadURL) == "package1DownloadURL"

                expect(p2.packageTypeId) == 2
                expect(p2.packageName) == "package2Name"
                expect(p2.version) == "package2Version"
                expect(p2.versionNumber) == "package2VersionNumber"
                expect(p2.downloadURL) == "package2DownloadURL"
            }
            
            // MARK: .. should compare
            
            it("should compare properly") {
                expect(p1) != p2
                expect(p2) != p1
                
                var p1a = p1
                p1a.packageName = "package1aName"
                expect(p1) != p1a
                expect(p1a) != p1

                var p1b = p1
                p1b.packageTypeId = 2
                expect(p1) != p1b
                expect(p1b) != p1

                var p1c = p1
                p1c.version = "package1cversion"
                expect(p1) != p1c
                expect(p1c) != p1

                var p1d = p1
                p1d.versionNumber = "package1dversionnumber"
                expect(p1) != p1d
                expect(p1d) != p1

                var p1e = p1
                p1e.downloadURL = "package1edownloadurl"
                expect(p1) != p1e
                expect(p1e) != p1
            }
            
            // MARK: .. should JSON-roundtrip
            
            it("should JSON-roundtrip properly") {
                let p1b: DeviceStreamEvent.OTAPackageInfo? = |<p1.JSONDict
                expect(p1b).toNot(beNil())
                expect(p1b) == p1
            }
        }
        
        // MARK: - DeviceStreamEvent.OTAProgress
        
        describe("DeviceStreamEvent.OTAProgress") {

            typealias OTAProgress = DeviceStreamEvent.OTAProgress
            typealias State = OTAProgress.State

            let p1: OTAProgress! = OTAProgress(state: 0, offset: 0, total: 200)
            let p2: OTAProgress! = OTAProgress(state: 1, offset: 0, total: 200)
            let p3: OTAProgress! = OTAProgress(state: 2, offset: 0, total: 200)
            let p4: OTAProgress! = OTAProgress(state: 3, offset: 0, total: 200)

            // MARK: .. should instantiate
            
            it("should instantiate correctly") {
                
                expect(p1).toNot(beNil())
                expect(p1.state) == State.start
                expect(p1.total) == 200
                expect(p1.offset) == 0
                expect(p1.progress) == 0

                expect(p2).toNot(beNil())
                expect(p2.state) == State.inProgress
                expect(p2.total) == 200
                expect(p2.offset) == 0
                expect(p2.progress) == 0

                expect(p3).toNot(beNil())
                expect(p3.state) == State.complete
                expect(p3.total) == 200
                expect(p3.offset) == 0
                expect(p3.progress).to(beNil())

                expect(p4).to(beNil())
            }
            
            // MARK: .. should compare
            
            it("should compare correctly") {
                
                expect(p1) == p1
                expect(p1) != p2
                expect(p1.hashValue) != p2.hashValue
                expect(p1) != p3
                expect(p1.hashValue) != p3.hashValue
                
                expect(p2) != p1
                expect(p2.hashValue) != p1.hashValue
                expect(p2) == p2
                expect(p2) != p3
                expect(p2.hashValue) != p3.hashValue
                
                expect(p3) != p1
                expect(p3.hashValue) != p1.hashValue
                expect(p3) != p2
                expect(p3.hashValue) != p2.hashValue
                expect(p3) == p3

            }
            
            // MARK: - DeviceStreamEvent.OTAProgress.State
            
            describe("DeviceStreamEvent.OTAProgress.State") {
                
                typealias State = DeviceStreamEvent.OTAProgress.State
                
                // MARK: .. should compare
                
                it("should compare correctly") {
                    expect(State.start) == State.start
                    expect(State.start) != State.inProgress
                    expect(State.start) != State.complete
                    expect(State.start) != State.unknown(-1)
                    expect(State.start) != State.unknown(State.start.rawValue)

                    expect(State.inProgress) != State.start
                    expect(State.inProgress) == State.inProgress
                    expect(State.inProgress) != State.complete
                    expect(State.inProgress) != State.unknown(-1)
                    expect(State.inProgress) != State.unknown(State.inProgress.rawValue)

                    expect(State.complete) != State.start
                    expect(State.complete) != State.inProgress
                    expect(State.complete) == State.complete
                    expect(State.complete) != State.unknown(-1)
                    expect(State.complete) != State.unknown(State.complete.rawValue)

                    expect(State.unknown(-1)) != State.start
                    expect(State.unknown(-1)) != State.inProgress
                    expect(State.unknown(-1)) != State.complete
                    expect(State.unknown(-1)) == State.unknown(-1)
                    expect(State.unknown(-1)) != State.unknown(1)
                }
                
                // MARK: .. should instantiate and associate values
                
                it("should instantiate and associate values correctly") {
                    let start = State(0)
                    expect(start) == State.start
                    expect(start.rawValue) == 0
                    
                    let inProgress = State(1)
                    expect(inProgress) == State.inProgress
                    expect(inProgress.rawValue) == 1
                    
                    let complete = State(2)
                    expect(complete) == State.complete
                    expect(complete.rawValue) == 2

                    let unknown1 = State(3)
                    expect(unknown1) == State.unknown(3)
                    expect(unknown1.rawValue) == 3

                    let unknown2 = State(-1)
                    expect(unknown2) == State.unknown(-1)
                    expect(unknown2.rawValue) == -1
                }
            }
        }
        
        // MARK: - DeviceStreamEvent
        
        describe("DeviceStreamEvent") {
        
            // MARK: .. should map names
            describe("Name mapping") {
                
                it("should map expected canonical names") {
                    expect(DeviceStreamEvent.Name.peripheralList.rawValue) == "peripheralList"
                    expect(DeviceStreamEvent.Name.deviceOTA.rawValue) == "device:ota"
                    expect(DeviceStreamEvent.Name.deviceOTAProgress.rawValue) == "device:ota_progress"
                    expect(DeviceStreamEvent.Name.invalidate.rawValue) == "invalidate"
                    expect(DeviceStreamEvent.Name.deviceError.rawValue) == "device:error"
                    expect(DeviceStreamEvent.Name.deviceMute.rawValue) == "device:mute"
                    expect(DeviceStreamEvent.Name.invalidate.rawValue) == "invalidate"
                }
            }
            
            // MARK: .peripheralList
            
            describe("DeviceStreamEvent.peripheralList messages") {
                
                let fixture: [String: Any]

                do {
                    fixture = (try self.fixture(named: "conclave_peripheralList"))!
                } catch {
                    fatalError("Unable to read fixture conclave_peripheralList: \(String(reflecting: error))")
                }
                
                guard
                    let name = fixture["event"] as? String,
                    let data = fixture["data"] as? [String: Any] else {
                        fatalError("Expected 'event' and 'data' keys in fixture.")
                }
                
                // MARK: .. should instantiate
                
                it("should instantiate properly") {
                    
                    guard let event = DeviceStreamEvent(name: name, data: data) else {
                        fail("Expected event to not be nil")
                        return
                    }
                    
                    switch event {
                        
                    case let .peripheralList(peripherals, currentSeq):
                        expect(peripherals.count) == 2

                        expect(peripherals[0].attribute(for: 1024)?.data).to(beNil())
                        expect(peripherals[0].attribute(for: 1024)?.stringValue).to(beNil())
                        expect(peripherals[0].createdTimestampMs) == 1476119789875
                        expect(peripherals[0].created) == Date.dateWithMillisSince1970(peripherals[0].createdTimestampMs)
                        expect(peripherals[0].status.isDirect).to(beTrue())

                        expect(peripherals[1].attribute(for: 1024)?.data) == "0100"
                        expect(peripherals[1].attribute(for: 1024)?.stringValue) == "1"
                        expect(peripherals[1].createdTimestampMs) == 123456789022
                        expect(peripherals[1].created) == Date.dateWithMillisSince1970( peripherals[1].createdTimestampMs)
                        expect(peripherals[1].status.isDirect).to(beFalse())

                        expect(currentSeq) == 100
                        
                    default:
                        fail("Expected a peripheralList!")
                    }
                    
                }
            }
            
            // MARK: .attributeChange
            
            describe("DeviceStreamEvent.attributeChange messages") {
                
                let fixture: [String: Any]
                
                do {
                    fixture = (try self.fixture(named: "conclave-attributeUpdate-attr_change"))!
                } catch {
                    fatalError("Unable to read fixture conclave-attributeUpdate-attr_change: \(String(reflecting: error))")
                }
                
                guard
                    let name = fixture["event"] as? String,
                    let data = fixture["data"] as? [String: Any] else {
                        fatalError("Expected 'event' and 'data' keys in fixture.")
                }
                
                // MARK: .. should instantiate properly
                
                it("should instantiate properly") {
                    
                    guard let event = DeviceStreamEvent(name: name, data: data) else {
                        fail("Expected event to not be nil")
                        return
                    }
                    
                    switch event {
                        
                    case let .attributeChange(seq, peripheralId, requestId, state, reason, attribute, sourceHubId):
                        
                        expect(seq).to(beNil())
                        expect(requestId) == 19
                        expect(peripheralId) == "ffffffff"
                        expect(state) == DeviceStreamEvent.Peripheral.UpdateState.unknownAttribute
                        expect(reason) == DeviceStreamEvent.Peripheral.UpdateReason.mcuInitiated
                        expect(attribute.attributeId) == 1000
                        expect(attribute.data) == "0100"
                        expect(attribute.stringValue) == "1"
                        expect(sourceHubId) == "dddddddd"
                        
                    default:
                        fail("Expected a peripheralList!")
                    }
                    
                }
            }
            
            // MARK: .statusChange
            
            describe("DeviceStreamEvent.statusChange messages") {
                
                let fixture: [String: Any]
                
                do {
                    fixture = (try self.fixture(named: "conclave-statusUpdate-status_change"))!
                } catch {
                    fatalError("Unable to read fixture conclave-statusUpdate-status_change: \(String(reflecting: error))")
                }
                
                guard
                    let name = fixture["event"] as? String,
                    let data = fixture["data"] as? [String: Any] else {
                        fatalError("Expected 'event' and 'data' keys in fixture.")
                }
                
                // MARK: .. should instantiate properly
                
                it("should instantiate properly") {
                    
                    guard let event = DeviceStreamEvent(name: name, data: data) else {
                        fail("Expected event to not be nil")
                        return
                    }
                    
                    switch event {
                        
                    case let .statusChange(seq, peripheralId, status):
                        
                        expect(seq).to(beNil())
                        expect(peripheralId) == "ffffffff"
                        expect(status.isVisible).to(beTrue())
                        expect(status.isAvailable).to(beFalse())
                        
                        if let RSSI = status.RSSI {
                            expect(RSSI) == -33
                        } else {
                            fail("Expected RSSI to not be nil.")
                        }
                        
                    default:
                        fail("Expected a peripheralList!")
                    }
                    
                }


            }
            
            // MARK: .deviceOTA
            
            describe("DeviceStreamEvent.deviceOTA messages") {
                
                let fixture: [String: Any]
                
                do {
                    fixture = (try self.fixture(named: "conclave-OTA-device_ota"))!
                } catch {
                    fatalError("Unable to read fixture conclave-OTA-device_ota: \(String(reflecting: error))")
                }
                
                guard
                    let name = fixture["event"] as? String,
                    let data = fixture["data"] as? [String: Any] else {
                        fatalError("Expected 'event' and 'data' keys in fixture.")
                }
                
                // MARK: .. should instantiate properly

                it("should instantiate properly") {
                    
                    guard let event = DeviceStreamEvent(name: name, data: data) else {
                        fail("Expected event to not be nil")
                        return
                    }
                    
                    switch event {
                        
                    case let .deviceOTA(seq, peripheralId, packageInfos):
                        
                        expect(seq).to(beNil())
                        expect(peripheralId) == "ffffffff"
                        expect(packageInfos.count) == 1
                        expect(packageInfos.first?.packageTypeId) == 4
                        expect(packageInfos.first?.packageName) == "Device Description"
                        expect(packageInfos.first?.version) == "1493840735486"
                        expect(packageInfos.first?.versionNumber) == "9860"
                        expect(packageInfos.first?.downloadURL) == "https://otacdn.dev.afero.io/..."
                        
                    default:
                        fail("Expected a peripheralList!")
                    }
                    
                }
                
                
            }
            
            // MARK: .deviceOTAProgress
            
            describe("DeviceStreamEvent.deviceOTAProgress messages") {
                
                // MARK: start messages
                
                describe("start messages") {
                    
                    let fixture: [String: Any]
                    
                    do {
                        fixture = (try self.fixture(named: "conclave-OTA-ota_progress-start"))!
                    } catch {
                        fatalError("Unable to read fixture conclave-OTA-ota_progress-start: \(String(reflecting: error))")
                    }
                    
                    guard
                        let name = fixture["event"] as? String,
                        let data = fixture["data"] as? [String: Any] else {
                            fatalError("Expected 'event' and 'data' keys in fixture.")
                    }
                    
                    // MARK: .. should instantiate
                    
                    it("should instantiate properly") {
                        
                        guard let event = DeviceStreamEvent(name: name, data: data) else {
                            fail("Expected event to not be nil")
                            return
                        }
                        
                        switch event {
                            
                        case let .deviceOTAProgress(seq, peripheralId, progress):
                            
                            expect(seq).to(beNil())
                            expect(peripheralId) == "ffffffff"
                            expect(progress) == DeviceStreamEvent.OTAProgress(state: .start, offset: 50, total: 500)
                            
                        default:
                            fail("Expected a peripheralList!")
                        }
                        
                    }
                    
                }
                
                // MARK: inProgress messages
                
                describe("inProgress messages") {
                    
                    let fixture: [String: Any]
                    
                    do {
                        fixture = (try self.fixture(named: "conclave-OTA-ota_progress-inProgress"))!
                    } catch {
                        fatalError("Unable to read fixture conclave-OTA-ota_progress-inProgress: \(String(reflecting: error))")
                    }
                    
                    guard
                        let name = fixture["event"] as? String,
                        let data = fixture["data"] as? [String: Any] else {
                            fatalError("Expected 'event' and 'data' keys in fixture.")
                    }
                    
                    // MARK: .. should instantiate
                    
                    it("should instantiate properly") {
                        
                        guard let event = DeviceStreamEvent(name: name, data: data) else {
                            fail("Expected event to not be nil")
                            return
                        }
                        
                        switch event {
                            
                        case let .deviceOTAProgress(seq, peripheralId, progress):
                            
                            expect(seq).to(beNil())
                            expect(peripheralId) == "ffffffff"
                            expect(progress) == DeviceStreamEvent.OTAProgress(state: .inProgress, offset: 230, total: 600)
                            
                        default:
                            fail("Expected a peripheralList!")
                        }
                        
                    }
                    
                }

                
                // MARK: complete messages
                
                describe("complete messages") {
                    
                    let fixture: [String: Any]
                    
                    do {
                        fixture = (try self.fixture(named: "conclave-OTA-ota_progress-complete"))!
                    } catch {
                        fatalError("Unable to read fixture conclave-OTA-ota_progress-complete: \(String(reflecting: error))")
                    }
                    
                    guard
                        let name = fixture["event"] as? String,
                        let data = fixture["data"] as? [String: Any] else {
                            fatalError("Expected 'event' and 'data' keys in fixture.")
                    }
                    
                    // MARK: .. should instantiate
                    
                    it("should instantiate properly") {
                        
                        guard let event = DeviceStreamEvent(name: name, data: data) else {
                            fail("Expected event to not be nil")
                            return
                        }
                        
                        switch event {
                            
                        case let .deviceOTAProgress(seq, peripheralId, progress):
                            
                            expect(seq).to(beNil())
                            expect(peripheralId) == "ffffffff"
                            expect(progress) == DeviceStreamEvent.OTAProgress(state: .complete, offset: 20, total: 1000)
                            
                        default:
                            fail("Expected a peripheralList!")
                        }
                        
                    }
                    
                }
                
                // MARK: unknown messages
                
                describe("unknown messages") {
                    
                    let fixture: [String: Any]
                    
                    do {
                        fixture = (try self.fixture(named: "conclave-OTA-ota_progress-unknown"))!
                    } catch {
                        fatalError("Unable to read fixture conclave-OTA-ota_progress-unknown: \(String(reflecting: error))")
                    }
                    
                    guard
                        let name = fixture["event"] as? String,
                        let data = fixture["data"] as? [String: Any] else {
                            fatalError("Expected 'event' and 'data' keys in fixture.")
                    }
                    
                    // MARK: .. should fail instantiation
                    
                    it("should fail instantiation") {
                        let event = DeviceStreamEvent(name: name, data: data)
                        expect(event).to(beNil())
                    }
                    
                }
                
            }
            
            // MARK: .invalidation
            
            describe("DeviceStreamEvent.invalidation messages") {

                let fixtureAccounts: [String: Any]
                let fixtureLocation: [String: Any]
                let fixtureProfilesId: [String: Any]
                let fixtureProfilesDeviceId: [String: Any]
                let fixtureProfilesIdAndDeviceId: [String: Any]
                let fixtureInvitations: [String: Any]
                let fixtureNoKind: [String: Any]
                
                
                do {
                    fixtureAccounts = (try self.fixture(named: "conclave-invalidate-accounts"))!
                    fixtureLocation = (try self.fixture(named: "conclave-invalidate-location"))!
                    fixtureProfilesId = (try self.fixture(named: "conclave-invalidate-profiles-id"))!
                    fixtureProfilesDeviceId = (try self.fixture(named: "conclave-invalidate-profiles-deviceId"))!
                    fixtureProfilesIdAndDeviceId = (try self.fixture(named: "conclave-invalidate-profiles-id-and-deviceId"))!
                    fixtureInvitations = (try self.fixture(named: "conclave-invalidate-invitations"))!
                    fixtureNoKind = (try self.fixture(named: "conclave-invalidate-nokind"))!
                } catch {
                    fatalError("Unable to read fixture: \(String(reflecting: error))")
                }
                
                guard
                    
                    let fixtureAccountsName = fixtureAccounts["event"] as? String,
                    let fixtureAccountsData = fixtureAccounts["data"] as? [String: Any],
                    
                    let fixtureLocationName = fixtureLocation["event"] as? String,
                    let fixtureLocationData = fixtureLocation["data"] as? [String: Any],
                    
                    let fixtureProfilesIdName = fixtureProfilesId["event"] as? String,
                    let fixtureProfilesIdData = fixtureProfilesId["data"] as? [String: Any],

                    let fixtureProfilesDeviceIdName = fixtureProfilesDeviceId["event"] as? String,
                    let fixtureProfilesDeviceIdData = fixtureProfilesDeviceId["data"] as? [String: Any],

                    let fixtureProfilesIdAndDeviceIdName = fixtureProfilesIdAndDeviceId["event"] as? String,
                    let fixtureProfilesIdAndDeviceIdData = fixtureProfilesIdAndDeviceId["data"] as? [String: Any],

                    let fixtureInvitationsName = fixtureInvitations["event"] as? String,
                    let fixtureInvitationsData = fixtureInvitations["data"] as? [String: Any],

                    let fixtureNoKindName = fixtureNoKind["event"] as? String,
                    let fixtureNoKindData = fixtureNoKind["data"] as? [String: Any]
                    
                    else {
                        fatalError("Expected 'event' and 'data' keys in all fixtures.")
                }
                
                // MARK: .. should instantiate
                
                it("should instantiate properly") {
                    
                    let ia = DeviceStreamEvent(name: fixtureAccountsName, data: fixtureAccountsData)
                    expect(ia).toNot(beNil())
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = ia {
                        expect(seq).to(beNil())
                        expect(kind) == "accounts"
                        expect(peripheralId).to(beNil())
                        expect(data.count) == fixtureAccountsData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: ia))")
                    }
                    
                    let il = DeviceStreamEvent(name: fixtureLocationName, data: fixtureLocationData)
                    expect(il).toNot(beNil())
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = il {
                        expect(seq).to(beNil())
                        expect(kind) == "location"
                        expect(peripheralId) == "eeeeeeee"
                        expect(data.count) == fixtureLocationData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: il))")
                    }
                    
                    let ipid = DeviceStreamEvent(name: fixtureProfilesIdName, data: fixtureProfilesIdData)
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = ipid {
                        expect(seq).to(beNil())
                        expect(kind) == "profiles"
                        expect(peripheralId) == "11111111"
                        expect(data.count) == fixtureProfilesIdData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: ipid))")
                    }

                    let ipdid = DeviceStreamEvent(name: fixtureProfilesDeviceIdName, data: fixtureProfilesDeviceIdData)
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = ipdid {
                        expect(seq).to(beNil())
                        expect(kind) == "profiles"
                        expect(peripheralId) == "22222222"
                        expect(data.count) == fixtureProfilesDeviceIdData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: ipdid))")
                    }

                    let ipidid = DeviceStreamEvent(name: fixtureProfilesIdAndDeviceIdName, data: fixtureProfilesIdAndDeviceIdData)
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = ipidid {
                        expect(seq).to(beNil())
                        expect(kind) == "profiles"
                        expect(peripheralId) == "22222222"
                        expect(data.count) == fixtureProfilesIdAndDeviceIdData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: ipidid))")
                    }

                    let ii = DeviceStreamEvent(name: fixtureInvitationsName, data: fixtureInvitationsData)
                    
                    if case let .some(.invalidate(seq, peripheralId, kind, data)) = ii {
                        expect(seq).to(beNil())
                        expect(kind) == "invitations"
                        expect(peripheralId).to(beNil())
                        expect(data.count) == fixtureInvitationsData.count
                    } else {
                        fail("Expected a .invalidate event; got \(String(describing: ii))")
                    }
                    
                    let iu = DeviceStreamEvent(name: fixtureNoKindName, data: fixtureNoKindData)
                    expect(iu).to(beNil())
                    

                }

                
            }
            
            // MARK: .deviceError
            
            describe("DeviceEventStream.deviceError messages") {
                
                typealias DeviceError = DeviceStreamEvent.DeviceError
                typealias Status = DeviceError.Status
                
                let fixture: [[String: Any]]
                
                do {
                    fixture = (try self.fixture(named: "conclave-error-device_error"))!
                } catch {
                    fatalError("Unable to read fixture conclave-error-device_error: \(String(reflecting: error))")
                }
                
                let events: [DeviceStreamEvent] = fixture.enumerated().map {
                    idx, data in
                    guard
                        let name = data["event"] as? String,
                        let eventData = data["data"] as? [String: Any],
                        let event = DeviceStreamEvent(name: name, data: eventData) else {
                            fatalError("Unable to instantiate DeviceStreamEvent with data at idx \(idx) in conclave-error-device_error (data: \(String(reflecting: data))")
                    }
                    return event
                }
                
                // MARK: .. should instantiate
                
                it("should instantiate properly") {
                    
                    var peripheralIds: [String] = []
                    var errorCodes: [UInt64] = []
                    var errorPeripheralIds: [String] = []
                    var errorEvents: [String] = []
                    var errorStatuses: [Status] = []
                    var errorChannelIds: [Int] = []
                    var errorRequestIds: [Int] = []
                    
                    events.forEach {
                        event in switch event {
                        case let .deviceError(_, peripheralId, error):
                            peripheralIds.append(peripheralId)
                            errorPeripheralIds.append(error.peripheralId)
                            errorStatuses.append(error.status)
                            errorCodes.append(error.status.rawValue)
                            errorChannelIds.append(error.channelId)
                            if let requestId = error.requestId {
                                errorRequestIds.append(requestId)
                            }
                            errorEvents.append(error.event)
                        default:
                            break
                        }
                    }
                    
                    expect(peripheralIds.count) == 14
                    expect(peripheralIds) == [
                        "ffffffff",
                        "fffffffd",
                        "ffffffdf",
                        "fffffdff",
                        "ffffdfff",
                        "fffdffff",
                        "ffdfffff",
                        "fdffffff",
                        "dfffffff",
                        "ddffffff",
                        "dfdfffff",
                        "dffdffff",
                        "dfffdfff",
                        "dffffdff",
                    ]

                    expect(errorCodes.count) == 14
                    expect(errorCodes) == [0, 0xFFFFFFFF] + Array(1...12)

                    expect(errorPeripheralIds) == peripheralIds
                    
                    expect(errorEvents.count) == 14
                    expect(errorEvents) == Array(repeating: "device:write", count: 14)

                    expect(errorStatuses.count) == 14
                    expect(errorStatuses) == [
                        Status.ok,
                        Status.fail,
                        Status.notFound,
                        Status.already,
                        Status.invalidParam,
                        Status.timedOut,
                        Status.cancelled,
                        Status.connectionFailed,
                        Status.shutdown,
                        Status.connectionNotAllowed,
                        Status.otaDownloadFailed,
                        Status.fileIOError,
                        Status.otaStartError,
                        Status.notAllowed
                    ]

                    expect(errorChannelIds.count) == 14
                    expect(errorChannelIds) == Array(62000...62013)

                    expect(errorRequestIds.count) == 14
                    expect(errorRequestIds) == Array(1883...1896)
                }
                
                
            }
            
            // MARK: .deviceMute
            
            describe("DeviceEventStream.deviceMute messages") {
                
                let fixture: [String: Any]
                
                do {
                    fixture = (try self.fixture(named: "conclave-rate-device_mute"))!
                } catch {
                    fatalError("Unable to read fixture conclave-rate-device_mute: \(String(reflecting: error))")
                }
                
                guard
                    let name = fixture["event"] as? String,
                    let data = fixture["data"] as? [String: Any] else {
                        fatalError("Expected 'event' and 'data' keys in fixture.")
                }
                
                // MARK: .. should instantiate
                
                it("should instantiate properly") {
                    
                    guard let event = DeviceStreamEvent(name: name, data: data) else {
                        fail("Expected event to not be nil")
                        return
                    }
                    
                    switch event {
                        
                    case let .deviceMute(seq, peripheralId, timeout):
                        
                        expect(seq).to(beNil())
                        expect(peripheralId) == "ffffffff"
                        expect(timeout).to(beCloseTo(59.902))
                        
                    default:
                        fail("Expected a deviceMute!")
                    }
                    
                }
                
                
            }


            
        }
        
    }
    
}
