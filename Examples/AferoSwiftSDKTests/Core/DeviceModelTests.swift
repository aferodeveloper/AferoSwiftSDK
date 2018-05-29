//
//  DeviceModelTests.swift
//  iTokui
//
//  Created by Justin Middleton on 6/12/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import UIKit
import Quick
import Nimble
@testable import Afero
import ReactiveSwift



class DeviceStateSpec: QuickSpec {
    
    override func spec() {
        describe("DeviceState") {
            
            it("Should instantiate") {
                
                let state = DeviceState(isAvailable: true, isDirect: false, profileId: "boop", friendlyName: "boopName")
                
                expect(state.isAvailable).to(beTrue())
                expect(state.isDirect).to(beFalse())
                expect(state.profileId) == "boop"
                expect(state.friendlyName) == "boopName"
            }
            
            it("Should test equality correctly") {

                let state = DeviceState(isAvailable: true, isDirect: false, profileId: "boop", friendlyName: "boopName")
                
                let state1b = state
                expect(state1b) == state
                expect(state) == state1b
                
                var state2 = state
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))
                
                state2 = state
                state2.isAvailable = false
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))

                state2 = state
                state2.isDirect = true
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))
                
                state2 = state
                state2.profileId = nil
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))

                state2 = state
                state2.profileId = "fool"
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))

                state2 = state
                state2.friendlyName = nil
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))

                state2 = state
                state2.friendlyName = "booor"
                expect(state2).toNot(equal(state))
                expect(state).toNot(equal(state2))

            }
        }
    }
}

class DeviceModelSpec: QuickSpec {

    override func spec() {

        let accountId = "foofoo"
        
        describe("When instantiating a device") {
            
            it("should instantiate correctly") {

                let deviceModel = BaseDeviceModel(
                    deviceId: "foo",
                    accountId: accountId,
                    associationId: "fooassociation",
                    attributes: [100: false])
                
                expect(deviceModel.attribute(for: 100)?.value.boolValue).toNot(beNil())
                expect(deviceModel.attribute(for: 100)?.value.boolValue).to(beFalsy())
                expect(deviceModel.deviceId) == "foo"
                expect(deviceModel.accountId) == accountId
                expect(deviceModel.associationId) == "fooassociation"
                expect(deviceModel.profileId).to(beNil())
                expect(deviceModel.deviceCloudSupporting).to(beNil())
            }
            
            
        }
        
        describe("When updating the profile ID") {
            
            it("Should make a request to the resolver") {
                
                let requestSem = DispatchSemaphore(value: 0)
                let resolver = MockDeviceAccountProfilesSource()

                resolver.fetchCompleteBlock = {
                    requestSem.signal()
                }
                
                let deviceModel = BaseDeviceModel(
                    deviceId: "foo",
                    accountId: accountId,
                    associationId: "fooassociation",
                    attributes: [100: false],
                    profileSource: resolver
                    )

                var writeCount = 0
                
                var profileEventCount: Int = 0
                
                deviceModel.eventSignal.observe() {
                    event in switch event {
                    case .value(let deviceEvent):
                        switch(deviceEvent) {
                        case .stateUpdate:
                            writeCount += 1
                        case .profileUpdate:
                            profileEventCount += 1
                        default:
                            break // TODO: Test the other cases here.
                        }
                    default: break
                    }
                }

                expect(resolver.fetchProfilesByAccountIdRequestCount) == 0
                expect(resolver.fetchProfileByDeviceIdRequestCount) == 0
                expect(resolver.fetchProfileByProfileIdRequestCount) == 0
                expect(writeCount) == 0
                
                deviceModel.profileId = "foo"
                
                // First we should time out, because we haven't actually
                // given the resolver a profile.
                
                guard case .success = requestSem.wait(timeout: .now() + 5.0) else {
                    fail("Timed out waiting for requestSem")
                    return
                }
                
                expect(resolver.fetchProfilesByAccountIdRequestCount) == 0
                expect(resolver.fetchProfileByDeviceIdRequestCount) == 0
                expect(resolver.fetchProfileByProfileIdRequestCount) == 1
                expect(deviceModel.profile).to(beNil())
                
                resolver.profileToReturn = try! self.fixture(named: "profileTest")
                deviceModel.profileId = "bar"
                
                // Now we should succeed.
                
                guard case .success = requestSem.wait(timeout: .now() + 5.0) else {
                    fail("Timed out waiting for requestSem")
                    return
                }
                
                expect(resolver.fetchProfilesByAccountIdRequestCount) == 0
                expect(resolver.fetchProfileByDeviceIdRequestCount) == 0
                expect(resolver.fetchProfileByProfileIdRequestCount) == 2
                expect(profileEventCount).toEventually(equal(1))
                expect(deviceModel.profile) == resolver.profileToReturn
                
            }
        }
        
        describe("When updating the profile") {
            
            let profile1 = DeviceProfile(attributes: [
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 202,   type: .sInt8,   operations: [.Read]),
                
                ]
            )
            
            let profile2 = DeviceProfile(attributes: [
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                ]
            )


            var deviceModel: DeviceModelable!
            var disposable: Disposable!
            
            beforeEach {
                deviceModel = BaseDeviceModel(
                    deviceId: "foo",
                    accountId: "moo",
                    profile: profile1
                )
            }
            
            afterEach { disposable?.dispose() }

            it("Should emit a profile update if the profile changes") {
                expect(profile1) != profile2
                
                var gotEvent: Bool = false
                
                disposable = deviceModel.eventSignal.observeValues {
                    event in switch event {
                    case .profileUpdate: gotEvent = true
                    default: break
                    }
                }
                
                (deviceModel as! BaseDeviceModel).profile = profile2
                expect(gotEvent).toEventually(beTrue(), timeout: 2.0, pollInterval: 0.25)
            }
            
            it("Should not emit a profile update if the profile does not change.") {

                expect(profile1) == profile1
                
                var gotEvent: Bool = false
                
                disposable = deviceModel.eventSignal.observeValues {
                    event in switch event {
                    case .profileUpdate: gotEvent = true
                    default: break
                    }
                }
                
                (deviceModel as! BaseDeviceModel).profile = profile1
                expect(gotEvent).toNotEventually(beTrue(), timeout: 2.0, pollInterval: 0.25)

            }
        }
        
        describe("When interrogating attributes") {
            
            let profile = DeviceProfile(attributes: [
                
                // Values that can be modified
                DeviceProfile.AttributeDescriptor(id: 50,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 100,   type: .sInt32,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 20,    type: .q1516,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 70,    type: .q3132,   operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 90,    type: .boolean, operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 101,   type: .sInt64,  operations: [.Read]),
                DeviceProfile.AttributeDescriptor(id: 201,   type: .sInt64,  operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 202,   type: .sInt8,   operations: [.Read]),
                
                // OfflineSchedule attributes
                DeviceProfile.AttributeDescriptor(id: 59001, type: .boolean,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59002, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59004, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59007, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59036, type: .bytes,   operations: [.Read, .Write]),
                DeviceProfile.AttributeDescriptor(id: 59037, type: .bytes,   operations: [.Read, .Write]),
                
                ])
            
            let deviceModel = BaseDeviceModel(
                deviceId: "foo",
                accountId: "moo",
                profile: profile
            )
            
            let rdeviceModel = RecordingDeviceModel(model: deviceModel)
            
            it("Should correctly show readable attributes") {
                expect(deviceModel.hasPresentableReadableAttributes).to(beFalse())
                expect(deviceModel.hasReadableAttributes).to(beTrue())
                expect(deviceModel.readableAttributes.count) == 14
                
                expect(rdeviceModel.hasPresentableReadableAttributes).to(beFalse())
                expect(rdeviceModel.hasReadableAttributes).to(beTrue())
                expect(rdeviceModel.readableAttributes.count) == 14

            }
            
            it("Should correctly show writable attributes") {
                expect(deviceModel.hasPresentableWritableAttributes).to(beFalse())
                expect(deviceModel.hasWritableAttributes).to(beTrue())
                expect(deviceModel.writableAttributes.count) == 10
                
                expect(rdeviceModel.hasPresentableWritableAttributes).to(beFalse())
                expect(rdeviceModel.hasWritableAttributes).to(beTrue())
                expect(rdeviceModel.writableAttributes.count) == 10

            }

        }
        
        describe("When posting actions") {
            
            let writeSink = MockDeviceCloudSupporting()
            let deviceModel = BaseDeviceModel(
                deviceId: "foo",
                accountId: accountId,
                profile: try! self.fixture(named: "profileTest"),
                deviceCloudSupporting: writeSink
            )
            
            beforeEach() {
                writeSink.postErrorToReturn = nil
                writeSink.postWasInvoked = false
                writeSink.postedActions = []
            }
            
            it("Should forward the update to its writeSink") {
                
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(deviceModel.deviceCloudSupporting) === writeSink
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(writeSink.postErrorToReturn).to(beNil())
                
                var error: Error? = nil
                
                deviceModel.deviceCloudSupporting?.post(actions: [.attributeWrite(attributeId: 100, value: "false")] , forDeviceId: "test", withAccountId: accountId) {
                    error = $1
                }
                
                expect(error).to(beNil())
                expect(writeSink.postWasInvoked).to(beTrue())
            }
            
            it("Should forward errors.") {
                
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(deviceModel.deviceCloudSupporting) === writeSink
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(writeSink.postErrorToReturn).to(beNil())
                
                var error: Error? = nil
                
                writeSink.postErrorToReturn = NSError(domain: "test error fixture", code: 666, userInfo: ["foo": "bar"])
                expect(writeSink.postErrorToReturn).toNot(beNil())
                
                deviceModel.deviceCloudSupporting?.post(actions: [.attributeWrite(attributeId: 100, value: "false")] , forDeviceId: "test", withAccountId: "test") {
                    error = $1
                }
                
                expect(writeSink.postWasInvoked).to(beTrue())
                expect(error).toNot(beNil())
                expect(error as NSError?) == writeSink.postErrorToReturn! as NSError
            }
            
            it("should post notify requests with a five-minut interval on start") {

                expect(deviceModel.deviceCloudSupporting) === writeSink
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(writeSink.postErrorToReturn).to(beNil())
                
                deviceModel.notifyViewing(true)
                expect(writeSink.postedActions).toEventually(contain(DeviceBatchAction.Request.notifyViewing(interval: 5 * 60)), timeout: 1, pollInterval: 0.1)
            }

            it("should post notify requests with 0-length interval on stop") {
                
                expect(deviceModel.deviceCloudSupporting) === writeSink
                expect(writeSink.postWasInvoked).to(beFalse())
                expect(writeSink.postErrorToReturn).to(beNil())
                
                deviceModel.notifyViewing(false)
                expect(writeSink.postedActions).toEventually(contain(DeviceBatchAction.Request.notifyViewing(interval: 0)), timeout: 1, pollInterval: 0.1)
            }

        }

        describe("When the device's state is updated") {

            it("Should emit the latest device state") {

                let deviceModel = BaseDeviceModel(
                    deviceId: "foo",
                    accountId: accountId,
                    attributes: [100: false, 1010: "Moo"],
                    profile: try! self.fixture(named: "profileTest")
                )
                
                var writeState: DeviceState? = deviceModel.currentState
                var writeCount = 0
                
                deviceModel.eventSignal.observe() {
                    event in switch event {
                    case .value(let deviceEvent):
                        switch(deviceEvent) {
                        case let .stateUpdate(newState):
                            writeState = newState
                            writeCount += 1
                        default:
                            break // TODO: Test the other cases here.
                        }
                    default: break
                    }
                }
                
                expect(writeState?.isAvailable).to(beFalse())
                expect(writeCount) == 0

                try! deviceModel.update([2000: "Hi!"])
                expect(deviceModel.isAvailable).to(beFalse())
                expect(deviceModel.value(for: 100)) == false
                expect(deviceModel.value(for: 2000)) == "Hi!"
                expect(writeCount).toEventually(equal(1))
                
                deviceModel.isAvailable = true
                expect(writeState?.isAvailable).toEventually(beTrue())
                expect(writeState?.isDirect).toEventually(beFalse())
                expect(deviceModel.value(for: 100)) == false
                expect(deviceModel.value(for: 2000)) == "Hi!"
                expect(writeCount).toEventually(equal(2))
                
                deviceModel.isDirect = true
                expect(writeCount).toEventually(equal(3), timeout: 2.0, pollInterval: 0.25)
                expect(writeState?.isDirect).toEventually(beTrue(), timeout: 2.0, pollInterval: 0.25)

            }
        }
    }
}
