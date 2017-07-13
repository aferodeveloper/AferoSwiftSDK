//
//  DeviceCollectionTests.swift
//  iTokui
//
//  Created by Justin Middleton on 6/6/17.
//  Copyright © 2017 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero


import ReactiveSwift

class DeviceCollectionSpec: QuickSpec {
    
    override func spec() {
        
        describe("DeviceCollection") {
            
//            var deviceCollectionDelegate: MockDeviceCollectionDelegate!
            var deviceEventStreamable: MockDeviceEventStreamable!
            var profileSource: MockDeviceAccountProfilesSource!
            var batchActionRequestable: MockDeviceBatchActionRequestable!
            var deviceCollection: DeviceCollection!
            var contentEventDisposable: Disposable!
            var stateEventDisposable: Disposable!
            
            let accountId = "accountIdFoo"
            let clientId = "clientIdFoo"
            
            beforeEach {
//                deviceCollectionDelegate = MockDeviceCollectionDelegate()
                deviceEventStreamable = MockDeviceEventStreamable(clientId: clientId, accountId: accountId)
                profileSource = MockDeviceAccountProfilesSource()
                batchActionRequestable = MockDeviceBatchActionRequestable()
                deviceCollection = DeviceCollection(deviceEventStreamable: deviceEventStreamable, profileSource: profileSource, batchActionRequestable: batchActionRequestable)
            }
            
            afterEach {
                deviceEventStreamable = nil
                profileSource = nil
                batchActionRequestable = nil
                deviceCollection = nil
                
                contentEventDisposable?.dispose()
                contentEventDisposable = nil
                
                stateEventDisposable?.dispose()
                stateEventDisposable = nil
            }
            
            // MARK: - Should Instantiate
            
            it("should instantiate") {
                
                let dc = DeviceCollection(delegate: deviceCollectionDelegate, deviceEventStreamable: deviceEventStreamable, profileSource: profileSource, batchActionRequestable: batchActionRequestable)
                
                expect(dc.delegate) === deviceCollectionDelegate
                expect(dc.eventStream) === deviceEventStreamable
                expect(dc.profileSource.source) === profileSource
                expect(dc.batchActionRequestable) === batchActionRequestable
                
            }
            
            // MARK: - When Starting
            
            describe("when starting") {
                
                // PeripheralList fixture
                
                let peripheralListFixtureData: [String: Any]
                let peripheralListFixture: DeviceStreamEvent
                
                do {
                    peripheralListFixtureData = (try self.readJson("conclave_peripheralList")) as! [String: Any]
                } catch {
                    fatalError("Unable to read fixture(s): \(String(reflecting: error))")
                }
                
                guard
                    let peripheralListData = peripheralListFixtureData["data"] as? [String: Any],
                    let peripheralList: [DeviceStreamEvent.Peripheral] = |<(peripheralListData["peripherals"] as? [AferoJSONCodedType]),
                    let peripheralListCurrentSeq = peripheralListData["currentSeq"] as? Int else {
                        fatalError("Unable to extract 'peripherals' ([Peripheral]) and/or 'currentSeq' (Int) from \(String(reflecting: peripheralListFixtureData))")
                }
                
                peripheralListFixture = DeviceStreamEvent.peripheralList(peripherals: peripheralList, currentSeq: peripheralListCurrentSeq)
                let peripheralListFixtureTruncated = DeviceStreamEvent.peripheralList(peripherals: Array(peripheralList.dropLast()), currentSeq: peripheralListCurrentSeq + 1)
                
                // Account profiles fixture
                
                let accountProfilesFixtureData: [[String: Any]]

                do {
                    accountProfilesFixtureData = (try self.readJson("accountDeviceProfiles")) as! [[String: Any]]
                } catch {
                    fatalError("Unable to read fixture(s): \(String(reflecting: error))")
                }
                
                guard
                    let accountProfilesFixture: [DeviceProfile] = |<accountProfilesFixtureData else {
                        fatalError("Unable to extract 'accountProfilesFixtureData' ([DeviceProfile]) from \(String(reflecting: accountProfilesFixtureData))")
                }
                
                typealias State = DeviceCollection.State

                // MARK: • should not start if the delegate tells it not to
                
                it("should not start if the delegate tells it not to") {

                    deviceCollectionDelegate.setShouldStart(false, for: deviceCollection)

                    expect(deviceCollectionDelegate.shouldStartCallCount) == 0
                    expect(deviceCollection.state) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 1
                    expect(deviceCollection.state) == State.unloaded
                    expect(profileSource.fetchProfileByProfileIdRequestCount) == 0
                    expect(profileSource.fetchProfileByDeviceIdRequestCount) == 0
                    expect(profileSource.fetchProfilesByAccountIdRequestCount) == 0
                }
                
                // MARK: • should start if the delegate tells it to

                it("should start if the delegate tells it to") {

                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 0
                    expect(deviceCollection.state) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 1
                    expect(deviceCollection.state) == State.loading
                    expect(profileSource.fetchProfileByProfileIdRequestCount) == 0
                    expect(profileSource.fetchProfileByDeviceIdRequestCount) == 0
                    expect(profileSource.fetchProfilesByAccountIdRequestCount) == 1
                }
                
                // MARK: • should transition from loading to loaded when it gets a peripheralList
                
                it("should transition from loading to loaded when it gets a peripheralList") {
                    
                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 0
                    expect(deviceCollection.state) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 1
                    expect(deviceCollection.state) == State.loading
                    
                }
                
                // MARK: • should attempt to fetch profiles for the peripherals when it gets a peripheralList
                
                it("should attempt to fetch profiles for the peripherals when it gets a peripheralList") {
                    
                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 0
                    expect(deviceCollection.state) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 1
                    expect(deviceCollection.state) == State.loading
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    expect(profileSource.fetchProfileByProfileIdRequestCount).toEventually(equal(peripheralList.count))
                    expect(deviceCollection.state).toEventually(equal(State.loaded))
                    
                }
                
                // MARK: • should have the expected number of devices after getting a peripheralList
                
                it("should have the expected number of devices after getting a peripheralList") {

                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    profileSource.accountProfilesToReturn = [accountId: accountProfilesFixture]
                    
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 0
                    expect(deviceCollection.state) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollectionDelegate.shouldStartCallCount) == 1
                    expect(deviceCollection.state) == State.loading
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    expect(profileSource.fetchProfilesByAccountIdRequestCount).toEventually(equal(1))
                    expect(deviceCollection.visibleDevices.count).toEventually(equal(peripheralList.count))
                    expect(deviceCollection.devices.filter { $0.isDirect }.count) == 1
                    expect(deviceCollection.state).toEventually(equal(State.loaded))
                    
                }
                
                // MARK: • should fire two device add events
                
                it("should fire two device add events") {
                    
                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    profileSource.accountProfilesToReturn = [accountId: accountProfilesFixture]
                    
                    var addCount: Int = 0
                    var deleteCount: Int = 0
                    
                    contentEventDisposable = deviceCollection.contentsSignal
                        .observe(on: QueueScheduler.main)
                        .observeValues {
                            contentEvent in
                            switch contentEvent {
                            case .create: addCount += 1
                            case .delete: deleteCount += 1
                            default: break
                            }
                    }
                    
                    deviceCollection.start()
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    deviceEventStreamable.eventSink.send(value: peripheralListFixtureTruncated)

                    expect(addCount).toEventually(equal(peripheralList.count))
                    expect(deleteCount).toEventually(equal(peripheralList.count - 1))
                    expect(deviceCollection.visibleDevices.count).toEventually(equal(peripheralList.count - 1))
                }

                // MARK: • should fire the expected state events
                
                it("should fire the expected state events") {
                    
                    deviceCollectionDelegate.setShouldStart(true, for: deviceCollection)
                    profileSource.accountProfilesToReturn = [accountId: accountProfilesFixture]
                    
                    var stateEvents: [DeviceCollection.State] = []
                    
                    stateEventDisposable = deviceCollection.stateSignal
                        .observe(on: QueueScheduler.main)
                        .observeValues {
                            stateEvents.append($0)
                    }
                    
                    stateEvents.append(deviceCollection.state)
                    
                    expect(stateEvents) == [.unloaded]
                    deviceCollection.start()
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    after(1.0) {
                        deviceCollection.stop()
                    }

                    expect(stateEvents).toEventually(equal([.unloaded, .loading, .loaded, .unloaded]), timeout: 5.0, pollInterval: 0.25)
                }
                
            }
            
        }
    }
}
