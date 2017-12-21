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
import ReactiveSwift
@testable import Afero

class MockDeviceTagPersisting: DeviceTagPersisting {

    // MARK: Delete
    
    typealias DeviceTag = DeviceTagPersisting.DeviceTag
    
    private(set) var deleteCalledCount: Int = 0
    func resetDeleteCalledCount() { deleteCalledCount = 0 }
    
    enum ExpectedDeleteTagResult {
        case success
        case failure(error: Error)
    }
    
    var expectedDeleteTagResult: ExpectedDeleteTagResult = .success
    
    func purgeTag(with id: DeviceTag.Id, onDone: @escaping DeviceTagPersisting.DeleteTagOnDone) {
        deleteCalledCount += 1
        switch expectedDeleteTagResult {
        case .success: onDone(id, nil)
        case .failure(let error): onDone(nil, error)
        }
    }
    
    // MARK: Add or Update
    
    private(set) var addOrUpdateCalledCount: Int = 0
    func resetAddOrUpdateCalledCount() { addOrUpdateCalledCount = 0 }
    
    enum ExpectedAddOrUpdateTagResult {
        case success(id: DeviceTag.Id)
        case failure(error: Error)
    }
    
    var expectedAddOrUpdateTagResult: ExpectedAddOrUpdateTagResult = .success(id: "foo")
    
    func persist(tag: DeviceTag, onDone: @escaping DeviceTagPersisting.AddOrUpdateTagOnDone) {
        
        addOrUpdateCalledCount += 1
        
        switch expectedAddOrUpdateTagResult {
            
        case .success(let expectedId):
            let resultTag = tag.mutableCopy() as! AferoMutableDeviceTag
            if resultTag.id == nil {
                resultTag.id = expectedId
            }
            onDone(resultTag, nil)
            
        case .failure(let error): onDone(nil, error)
        }
    }
    
}

class DeviceTagCollectionSpec: QuickSpec {
    
    override func spec() {
        
        typealias DeviceTag = DeviceTagCollection.DeviceTag
        
        var events: [DeviceTagCollection.Event]!
        var persistence: MockDeviceTagPersisting!
        var c: DeviceTagCollection!
        var d: Disposable?
        
        let t1 = DeviceTag(id: "id1", value: "v1", key: "k1")!
        let t1b = DeviceTag(id: "id1b", value: "v1b", key: "k1")!
        let t2 = DeviceTag(id: "id2", value: "v2", key: "k2")!
        let t3 = DeviceTag(id: "id3", value: "v3")!
        let t3b = DeviceTag(id: "id3b", value: "v3b")!
        
        beforeEach {
            persistence = MockDeviceTagPersisting()
            c = DeviceTagCollection(with: persistence)
            events = []
            d = c.eventSignal
                .observe(on: QueueScheduler.main)
                .observeValues {
                    events.append($0)
            }
        }
        
        afterEach {
            d?.dispose()
        }
        
        describe("publicly") {
            
            describe("Initialization") {
                
                it("should initializize") {
                    expect(c.count) == 0
                    expect(c.isEmpty).to(beTrue())
                }
            }
            
            describe("when addingOrUpdating tags") {
                
                var maybeTag: DeviceTag?
                var maybeError: Error?
                
                beforeEach {
                    maybeTag = nil
                    maybeError = nil
                }
                
                it("should update tags when recognized ids are specified") {
                    
                    c.add(tag: t1) { _, _ in }
                    
                    expect(c.count) == 1
                    
                    expect(c.deviceTags) == Set([
                        t1
                        ])

                    expect(persistence.addOrUpdateCalledCount) == 0
                    expect(persistence.deleteCalledCount) == 0

                    persistence.expectedAddOrUpdateTagResult = .success(id: "foo")
                    
                    let t1updated = t1.mutableCopy() as! AferoMutableDeviceTag
                    t1updated.value = "v1updated"
                    
//                    let o = c.observe(\.deviceTags, options: [.prior, .new, .old, .initial ]) {
//                        obj, chg in
//                        print("\(obj) \(chg)")
//                    }
                    
                    c.addOrUpdateTag(with: t1updated.value, groupedUsing: t1updated.key, identifiedBy: t1updated.id, using: t1updated.localizationKey) {
                        maybeTag = $0
                        maybeError = $1
                    }
                    
                    expect(maybeTag) == t1updated
                    expect(maybeError).to(beNil())
                    expect(persistence.addOrUpdateCalledCount) == 1
                    expect(persistence.deleteCalledCount) == 0
                    expect(c.count) == 1
                    
                    expect(c.deviceTags) == Set([
                        t1updated
                        ])
                    
                }
                
                it("should fail to update tags when unrecognized ids are specified") {
                    
                    c.add(tag: t1) { _, _ in }
                    
                    expect(c.count) == 1
                    
                    expect(c.deviceTags) == Set([
                        t1
                        ])
                    
                    expect(persistence.addOrUpdateCalledCount) == 0
                    expect(persistence.deleteCalledCount) == 0
                    
                    persistence.expectedAddOrUpdateTagResult = .failure(error: "Unknown id")
                    
                    let t1updated = t1.mutableCopy() as! AferoMutableDeviceTag
                    t1updated.value = "v1updated"
                    
                    c.addOrUpdateTag(
                        with: t1updated.value,
                        groupedUsing: t1updated.key,
                        identifiedBy: "some ridiculous id",
                        using: t1updated.localizationKey
                    ) {
                        maybeTag = $0
                        maybeError = $1
                    }
                    
                    expect(maybeTag).to(beNil())
                    expect(maybeError).toNot(beNil())
                    expect(persistence.addOrUpdateCalledCount) == 1
                    expect(persistence.deleteCalledCount) == 0
                    expect(c.count) == 1
                    
                    expect(c.deviceTags) == Set([
                        t1
                        ])

                }
                
                it("should add tags when no ids are specified") {

                    
                    c.add(tag: t1) { _, _ in }
                    
                    expect(c.count) == 1
                    
                    expect(c.deviceTags) == Set([
                        t1
                        ])
                    
                    expect(persistence.addOrUpdateCalledCount) == 0
                    expect(persistence.deleteCalledCount) == 0
                    
                    persistence.expectedAddOrUpdateTagResult = .success(id: t2.id!)
                    
                    c.addOrUpdateTag(
                        with: t2.value,
                        groupedUsing: t2.key,
                        using: t2.localizationKey
                    ) {
                        maybeTag = $0
                        maybeError = $1
                    }
                    
                    expect(maybeTag) == t2
                    expect(maybeError).to(beNil())
                    expect(persistence.addOrUpdateCalledCount) == 1
                    expect(persistence.deleteCalledCount) == 0
                    expect(c.count) == 2
                    
                    expect(c.deviceTags) == Set([
                        t1, t2
                        ])
                    
                }
                
            }
            
            describe("when deleting tags") {
                
                var maybeId: DeviceTag.Id?
                var maybeError: Error?

                beforeEach {
                    c.add(tag: t1) { _, _ in }
                    maybeId = nil
                    maybeError = nil
                }
                
                it("should delete tags when recognized ids are specified") {
                    
                    expect(c.deviceTags) == Set([t1])
                    expect(c.count) == 1
                    expect(persistence.deleteCalledCount) == 0
                    
                    c.deleteTag(identifiedBy: t1.id!) {
                        maybeId = $0
                        maybeError = $1
                    }
                    
                    expect(c.deviceTags).to(beEmpty())
                    expect(c.count) == 0
                    expect(persistence.deleteCalledCount) == 1
                    expect(maybeId) == t1.id
                    expect(maybeError).to(beNil())
                    
                }
                
                it("should fail to delete tags when unrecognized ids are specified.") {

                    expect(c.deviceTags) == Set([t1])
                    expect(c.count) == 1
                    expect(persistence.deleteCalledCount) == 0
                    
                    persistence.expectedDeleteTagResult = .failure(error: "unrecognized id")
                    
                    c.deleteTag(identifiedBy: "doo") {
                        maybeId = $0
                        maybeError = $1
                    }
                    
                    expect(persistence.deleteCalledCount) == 1
                    expect(maybeId).to(beNil())
                    expect(maybeError).toNot(beNil())
                    expect(c.deviceTags) == Set([t1])
                    expect(c.count) == 1

                }
            }
            

        }
        
        describe("internally") {

            describe("when setting manipulating tags") {
                
                describe("when adding tags") {
                    
                    it("should append tags when addTag is called for tags with differing ids.") {
                        
                        c.add(tag: t1) { _, _ in }
                        expect(c.isEmpty).to(beFalse())
                        expect(c.count) == 1
                        
                        c.add(tag: t1) { _, _ in }
                        expect(c.isEmpty).to(beFalse())
                        expect(c.count) == 1
                        
                        let t1b = DeviceTag(id: "id1b", value: "v1b", key: "k1")!
                        c.add(tag: t1b) { _, _ in }
                        expect(c.isEmpty).to(beFalse())
                        expect(c.count) == 2
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t1b),
                                    ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
                    }
                    
                    it("should replace tags when addTag is called for tags with equal ids.") {
                        
                        c.add(tag: t1) { _, _ in }
                        expect(c.isEmpty).to(beFalse())
                        expect(c.count) == 1
                        
                        let t1c = t1.mutableCopy() as! AferoMutableDeviceTag
                        t1c.value = "v1c"
                        c.add(tag: t1c) { _, _ in }
                        
                        expect(c.isEmpty).to(beFalse())
                        expect(c.count) == 1
                        expect(c.deviceTags.first) == t1c
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.deletedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t1c)
                                ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
                    }
                    
                }
                
                describe("when removing tags") {
                    
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
                        expect(c.deviceTags.first) == t1
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t2),
                                    DeviceTagCollection.Event.deletedTag(t2),
                                    ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
                    }
                    
                    it("should remove a single tag when given an id to remove.") {
                        
                        c.add(tag: t1) { _, _ in }
                        c.add(tag: t2) { _, _ in }
                        
                        expect(c.count) == 2
                        
                        var removed: Set<DeviceTag> = []
                        var err: Error?
                        
                        c.remove(withId: t2.id!) {
                            maybeRemoved, maybeErr in
                            maybeRemoved?.forEach {
                                removed.insert($0)
                            }
                            err = maybeErr
                        }
                        
                        expect(removed).toEventually(equal(Set([t2])))
                        expect(err != nil).toNotEventually(beTrue())
                        
                        expect(c.count) == 1
                        expect(c.deviceTags) == Set([t1])
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t2),
                                    DeviceTagCollection.Event.deletedTag(t2),
                                    ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
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
                        expect(c.deviceTags) == Set([t1, t2])
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t2),
                                    ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
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
                        expect(c.deviceTags) == Set([t2])
                        
                        expect(Set(events)).toEventually(
                            equal(
                                Set([
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t1b),
                                    DeviceTagCollection.Event.addedTag(t2),
                                    DeviceTagCollection.Event.deletedTag(t1),
                                    DeviceTagCollection.Event.deletedTag(t1b),
                                    ])
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
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
                        expect(c.deviceTags) == Set([t1, t1b, t2])
                        
                        expect(events).toEventually(
                            equal(
                                [
                                    DeviceTagCollection.Event.addedTag(t1),
                                    DeviceTagCollection.Event.addedTag(t1b),
                                    DeviceTagCollection.Event.addedTag(t2),
                                    DeviceTagCollection.Event.addedTag(t3),
                                    DeviceTagCollection.Event.addedTag(t3b),
                                    DeviceTagCollection.Event.deletedTag(t3),
                                    DeviceTagCollection.Event.deletedTag(t3b),
                                    ]
                            ),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
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
                        expect(c.deviceTags) == Set([t1, t2])
                        
                        expect(events.count).toNotEventually(
                            beGreaterThan(2),
                            timeout: 4.0,
                            pollInterval: 0.1
                        )
                        
                    }
                    
                }
                
            }

        }
        
    }
    
}

