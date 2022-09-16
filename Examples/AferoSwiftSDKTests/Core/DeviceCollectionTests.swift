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
import OHHTTPStubs

@testable import Afero


import ReactiveSwift

class DeviceCollectionSpec: QuickSpec {
    
    override func spec() {
        
        describe("DeviceCollection") {
            
            var deviceEventStreamable: MockDeviceEventStreamable!
            var deviceCollection: DeviceCollection!
            var contentEventDisposable: Disposable!
            var stateEventDisposable: Disposable!
            var apiClient: MockAPIClient!
            
            let accountId = "accountIdFoo"
            let clientId = "clientIdFoo"
            
            beforeEach {
                
                deviceEventStreamable = MockDeviceEventStreamable(clientId: clientId, accountId: accountId)
                apiClient = MockAPIClient()
                
                deviceCollection = DeviceCollection(apiClient: apiClient, deviceEventStreamable: deviceEventStreamable)
            }
            
            afterEach {
                deviceEventStreamable = nil
                deviceCollection = nil
                
                contentEventDisposable?.dispose()
                contentEventDisposable = nil
                
                stateEventDisposable?.dispose()
                stateEventDisposable = nil
                HTTPStubs.removeAllStubs()
            }
            
            // MARK: - Should Instantiate
            
            it("should instantiate") {
                expect(deviceCollection.eventStream) === deviceEventStreamable
            }
            
            // MARK: - When Starting
            
            describe("when starting") {
                
                // PeripheralList fixture
                
                guard
                    let peripheralListFixtureData: [String: Any] = try! self.fixture(named: "conclave_peripheralList") else {
                        fatalError("Couldn't read peripheralList.")
                }
                
                let peripheralListFixture: DeviceStreamEvent
                
                guard
                    let peripheralListData = peripheralListFixtureData["data"] as? [String: Any],
                    let peripheralList: [DeviceStreamEvent.Peripheral] = |<(peripheralListData["peripherals"] as? [AferoJSONCodedType]),
                    let peripheralListCurrentSeq = peripheralListData["currentSeq"] as? Int else {
                        fatalError("Unable to extract 'peripherals' ([Peripheral]) and/or 'currentSeq' (Int) from \(String(reflecting: peripheralListFixtureData))")
                }
                
                peripheralListFixture = DeviceStreamEvent.peripheralList(peripherals: peripheralList, currentSeq: peripheralListCurrentSeq)
                let peripheralListFixtureTruncated = DeviceStreamEvent.peripheralList(peripherals: Array(peripheralList.dropLast()), currentSeq: peripheralListCurrentSeq + 1)
                
                // Account profiles fixture
                
                guard let accountProfilesFixtureData: [[String: Any]] = try! self.fixture(named: "accountDeviceProfiles") else {
                    fatalError("Unable to read accountProfilesFixture")
                }
                
                beforeEach {
                    stub(condition: isPath("/v1/accounts/\(accountId)/deviceProfiles") && isMethodGET()) {
                        request in
                        return OHHTTPStubs.HTTPStubsResponse(jsonObject: accountProfilesFixtureData, statusCode: 200, headers: nil)
                    }
                    
                    accountProfilesFixtureData.forEach {
                        fixture in guard let profileId = fixture["profileId"] as? String else {
                            fatalError("No profileId found in \(String(describing: fixture))")
                        }
                        
                        stub(condition: isPath("/v1/accounts/\(accountId)/deviceProfiles/\(profileId)") && isMethodGET()) {
                            request in
                            return OHHTTPStubs.HTTPStubsResponse(jsonObject: fixture, statusCode: 200, headers: nil)
                        }
                    }
                }
                
                typealias State = DeviceCollection.ConnectionState

                // MARK: • should start if the delegate tells it to

                it("should start if the delegate tells it to") {
                    expect(deviceCollection.connectionState) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollection.connectionState) == State.loading
                }
                
                // MARK: • should transition from loading to loaded when it gets a peripheralList
                
                it("should transition from loading to loaded when it gets a peripheralList") {
                    
                    expect(deviceCollection.connectionState) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollection.connectionState) == State.loading
                    
                }
                
                // MARK: • should attempt to fetch profiles for the peripherals when it gets a peripheralList
                
                it("should attempt to fetch profiles for the peripherals when it gets a peripheralList") {
                    
                    expect(deviceCollection.connectionState) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollection.connectionState) == State.loading
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    expect(deviceCollection.connectionState).toEventually(equal(State.loaded))
                    
                }
                
                // MARK: • should have the expected number of devices after getting a peripheralList
                
                it("should have the expected number of devices after getting a peripheralList") {
                    
                    expect(deviceCollection.connectionState) == State.unloaded
                    deviceCollection.start()
                    expect(deviceCollection.connectionState) == State.loading
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    expect(deviceCollection.devices.count).toEventually(equal(peripheralList.count), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(deviceCollection.devices.filter { $0.isDirect }.count).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(deviceCollection.connectionState).toEventually(equal(State.loaded))
                    
                }
                
                // MARK: • should fire two device add events
                
                it("should fire two device add events") {
                    
                    var beginCount: Int = 0
                    var addCount: Int = 0
                    var deleteCount: Int = 0
                    var endCount: Int = 0
                    
                    contentEventDisposable = deviceCollection.contentsSignal
                        .observe(on: QueueScheduler.main)
                        .observeValues {
                            contentEvent in
                            switch contentEvent {
                            case .beginUpdates: beginCount += 1
                            case .create: addCount += 1
                            case .delete: deleteCount += 1
                            case .endUpdates: endCount += 1
                            default: break
                            }
                    }
                    
                    deviceCollection.start()
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    
                    // NOTE: .create messages are only sent once a device's profile has been resolved.
                    // Because we're stubbing our profile fetch throught he URL loading mechanism
                    // (see the stubs above), with the delay below, one device is removed
                    // before its profile is resolved, and therefore before its create message is ever
                    // sent. The delay is in place to ensure that there's time to load the profile,
                    // so that we will indeed get the two adds.
                    
                    after(2.0) {
                        deviceEventStreamable.eventSink.send(value: peripheralListFixtureTruncated)
                    }

                    expect(beginCount).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(beginCount).toNotEventually(beGreaterThan(2), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(addCount).toEventually(equal(peripheralList.count), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(deleteCount).toEventually(equal(peripheralList.count - 1), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(endCount).toEventually(equal(2), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(endCount).toNotEventually(beGreaterThan(2), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                    expect(deviceCollection.devices.count).toEventually(equal(peripheralList.count - 1), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                }

                // MARK: • should fire the expected state events
                
                it("should fire the expected state events") {
                    
                    var stateEvents: [DeviceCollection.ConnectionState] = []
                    
                    stateEventDisposable = deviceCollection.connectionStateSignal
                        .observe(on: QueueScheduler.main)
                        .observeValues {
                            stateEvents.append($0)
                    }
                    
                    stateEvents.append(deviceCollection.connectionState)
                    
                    expect(stateEvents) == [.unloaded]
                    deviceCollection.start()
                    deviceEventStreamable.eventSink.send(value: peripheralListFixture)
                    after(1.0) {
                        deviceCollection.stop()
                    }

                    expect(stateEvents).toEventually(equal([.unloaded, .loading, .loaded, .unloaded]), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.milliseconds(250))
                }
                
            }
            
            // MARK: - End-to-end behavioral -
            
            // MARK: When associating a device
            
            describe("when associating a device") {
                
                beforeEach {
                    
                    // PeripheralList fixture
                    
                    guard
                        let peripheralListFixtureData: [String: Any] = try! self.fixture(named: "conclave_peripheralList") else {
                            fatalError("Couldn't read peripheralList.")
                    }
                    
                    let peripheralListFixture: DeviceStreamEvent
                    
                    guard
                        let peripheralListData = peripheralListFixtureData["data"] as? [String: Any],
                        let peripheralList: [DeviceStreamEvent.Peripheral] = |<(peripheralListData["peripherals"] as? [AferoJSONCodedType]),
                        let peripheralListCurrentSeq = peripheralListData["currentSeq"] as? Int else {
                            fatalError("Unable to extract 'peripherals' ([Peripheral]) and/or 'currentSeq' (Int) from \(String(reflecting: peripheralListFixtureData))")
                    }
                    
                    peripheralListFixture = DeviceStreamEvent.peripheralList(peripherals: peripheralList, currentSeq: peripheralListCurrentSeq)
                    let peripheralListFixtureTruncated = DeviceStreamEvent.peripheralList(peripherals: Array(peripheralList.dropLast()), currentSeq: peripheralListCurrentSeq + 1)
                    
                    // Account profiles fixture
                    
                    guard let accountProfilesFixtureData: [[String: Any]] = try! self.fixture(named: "accountDeviceProfiles") else {
                        fatalError("Unable to read accountProfilesFixture")
                    }
                    
                    stub(condition: isPath("/v1/accounts/\(accountId)/deviceProfiles") && isMethodGET()) {
                        request in
                        return OHHTTPStubs.HTTPStubsResponse(jsonObject: accountProfilesFixtureData, statusCode: 200, headers: nil)
                    }
                    
                    accountProfilesFixtureData.forEach {
                        fixture in guard let profileId = fixture["profileId"] as? String else {
                            fatalError("No profileId found in \(String(describing: fixture))")
                        }
                        
                        stub(condition: isPath("/v1/accounts/\(accountId)/deviceProfiles/\(profileId)") && isMethodGET()) {
                            request in
                            return OHHTTPStubs.HTTPStubsResponse(jsonObject: fixture, statusCode: 200, headers: nil)
                        }
                    }
                    
                    typealias State = DeviceCollection.ConnectionState

                }
                
                afterEach {
                    HTTPStubs.removeAllStubs()
                }

                // MARK: • Create device if association return beats peripheralList
                
                it("should create a DeviceModel from association result and emit deviceCreate, if the association returns first, ") {
                    
                }
                
                // MARK: • Update device if peripheralList beats association return
                
                it("should update the DeviceModel from the association result and emit deviceUpdate if the association comes after the peripheralList") {
                    
                }
                
                // MARK: • Succeed with no changes if we already have a device with that association id.
                
                it("should succeed with no changes if we already have a device with that association id.") {
                    
                }
                
            }
            
            // MARK: - When disassociating a device
            
            describe("when disassociating a device") {

                // MARK: • Create device if association return beats peripheralList
                
                it("if the disassociation returns before peripheralList received, should remove device from association result and emit deviceDelete") {
                    
                }
                
                // MARK: • Update device if peripheralList beats association return
                
                it("if the peripheralList received before disassociation returns, only emit one deviceDelete") {
                    
                }

            }
            
            describe("when a device state update arrives") {
                
                it("should update the local device if any") {
                    
                }
            }
            
            describe("when a device attribute update arrives") {
                
                it("should update the local device, if any") {
                    
                }
            }
            
            
        }
    }
}
