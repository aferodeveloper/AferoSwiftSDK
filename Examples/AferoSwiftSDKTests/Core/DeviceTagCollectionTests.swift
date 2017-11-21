//
//  DeviceTagCollectionTests.swift
//  AferoTests
//
//  Created by Justin Middleton on 11/16/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero

class DeviceTagCollectionSpec: QuickSpec {
    

    override func spec() {
        
        typealias DeviceTag = DeviceTagCollection.DeviceTag

        fdescribe("Initialization") {
            
            it("should initializize") {
                let c = DeviceTagCollection()
                expect(c.count) == 0
                expect(c.isEmpty).to(beTrue())
            }
        }
        
        fdescribe("when setting tags") {
            
            var c: DeviceTagCollection!
            
            let t1 = DeviceTag(id: "id1", key: "k1", value: "v1")
            let t1b = DeviceTag(id: "id1b", key: "k1", value: "v1b")
            let t2 = DeviceTag(id: "id2", key: "k2", value: "v2")
            let t3 = DeviceTag(id: "id3", value: "v3")
            let t3b = DeviceTag(id: "id3b", value: "v3b")

            beforeEach {
                c = DeviceTagCollection()
            }
            
            it("should append tags when addTag is called.") {
                
                c.add(tag: t1) { _, _ in }
                expect(c.isEmpty).to(beFalse())
                expect(c.count) == 1

                c.add(tag: t1) { _, _ in }
                expect(c.isEmpty).to(beFalse())
                expect(c.count) == 1

                let t1b = DeviceTag(id: "id1b", key: "k1", value: "v1b")
                c.add(tag: t1b) { _, _ in }
                expect(c.isEmpty).to(beFalse())
                expect(c.count) == 2
                
            }

            it("should remove a single tag when given a tag to remove.") {

                c.add(tag: t1) { _, _ in }
                c.add(tag: t2) { _, _ in }
                
                expect(c.count) == 2
                
                var removed: Set<DeviceTag> = []
                var err: Error?

                c.remove(tag: t2) {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed).toEventually(equal(Set([t2])))
                expect(err != nil).toNotEventually(beTrue())
                
                expect(c.count) == 1
                expect(c.tags.first) == t1
            }

            it("should remove a single tag when given an id to remove.") {
                
                c.add(tag: t1) { _, _ in }
                c.add(tag: t2) { _, _ in }
                
                expect(c.count) == 2
                
                var removed: Set<DeviceTag> = []
                var err: Error?
                
                c.remove(withId: t2.id) {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed).toEventually(equal(Set([t2])))
                expect(err != nil).toNotEventually(beTrue())
                
                expect(c.count) == 1
                expect(c.tags) == Set([t1])
            }
            
            it("should be unchanged when removing an unknown id") {

                c.add(tag: t1) { _, _ in }
                c.add(tag: t2) { _, _ in }
                
                expect(c.count) == 2
                
                var removed: Set<DeviceTag> = []
                var err: Error?
                
                c.remove(withId: "foo") {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed.count).toNotEventually(beGreaterThan(0))
                expect(err != nil).toNotEventually(beTrue())
                
                expect(c.count) == 2
                expect(c.tags) == Set([t1, t2])
                
            }
            
            it("should remove all tags matching a key when removing by key.") {

                c.add(tag: t1) { _, _ in }
                c.add(tag: t1b) { _, _ in }
                c.add(tag: t2) { _, _ in }
                
                expect(c.count) == 3
                
                var removed: Set<DeviceTag> = []
                var err: Error?
                
                c.remove(withKey: t1b.key) {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed).toEventually(equal(Set([t1, t1b])))
                expect(err != nil).toNotEventually(beTrue())
                expect(c.count) == 1
                expect(c.tags) == Set([t2])

            }

            it("should remove all tags without a key when removing by a nil key.") {
                
                c.add(tag: t1) { _, _ in }
                c.add(tag: t1b) { _, _ in }
                c.add(tag: t2) { _, _ in }
                c.add(tag: t3) { _, _ in }
                c.add(tag: t3b) { _, _ in }

                expect(c.count) == 5
                
                var removed: Set<DeviceTag> = []
                var err: Error?
                
                c.remove(withKey: nil) {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed).toEventually(equal(Set([t3, t3b])))
                expect(err != nil).toNotEventually(beTrue())
                expect(c.count) == 3
                expect(c.tags) == Set([t1, t1b, t2])
                
            }

            it("should be unchanged when removing by an unknown key") {

                c.add(tag: t1) { _, _ in }
                c.add(tag: t2) { _, _ in }
                
                expect(c.count) == 2
                
                var removed: Set<DeviceTag> = []
                var err: Error?
                
                c.remove(withKey: "foo") {
                    maybeRemoved, maybeErr in
                    maybeRemoved?.forEach {
                        removed.insert($0)
                    }
                    err = maybeErr
                }
                
                expect(removed.count).toNotEventually(beGreaterThan(0))
                expect(err != nil).toNotEventually(beTrue())
                
                expect(c.count) == 2
                expect(c.tags) == Set([t1, t2])

            }
            
        }
    }
    
}

