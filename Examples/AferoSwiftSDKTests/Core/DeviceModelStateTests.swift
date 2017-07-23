//
//  DeviceModelStateTests.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 7/23/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero

class DeviceModelStateSpec: QuickSpec {
    
    override func spec() {

        describe("Instantiation") {
            
            it("should default initialize as expected") {
                let state = DeviceModelState()
                expect(state.available).to(beFalse())
                expect(state.visible).to(beFalse())
                expect(state.dirty).to(beFalse())
                expect(state.rebooted).to(beFalse())
                expect(state.connectable).to(beFalse())
                expect(state.connected).to(beFalse())
                expect(state.direct).to(beFalse())
                expect(state.rssi) == 0
                expect(state.locationState) == LocationState.notLocated
                expect(state.linked).to(beFalse())
                expect(state.updatedTimestampMillis) == 0
                expect(state.updatedTimestamp) == Date(timeIntervalSince1970: 0)
                expect(state.deviceLocalityId).to(beNil())
                expect(state.hubConnectInfo) == []
                expect(state.setupState).to(beNil())
            }
            
            it("should instantiate from a fixture") {
            
                guard let state1: DeviceModelState = try! self.fixture(named: "deviceModelState_deviceAssociate1") else {
                    fail("Unable to instantiate fixture1.")
                    return
                }
                
                expect(state1.available).to(beFalse())
                expect(state1.visible).to(beFalse())
                expect(state1.dirty).to(beFalse())
                expect(state1.rebooted).to(beFalse())
                expect(state1.connectable).to(beFalse())
                expect(state1.connected).to(beFalse())
                expect(state1.direct).to(beFalse())
                expect(state1.rssi) == 0
                expect(state1.locationState) == LocationState.located(at:
                    DeviceLocation(
                        latitude: 37.8488,
                        longitude: -122.5349,
                        sourceType: .clientIPEstimate
                    )
                )
                expect(state1.linked).to(beTrue())
                expect(state1.updatedTimestampMillis) == 1500828122154
                expect(state1.updatedTimestamp) == Date.dateWithMillisSince1970(1500828122154)
                expect(state1.deviceLocalityId).to(beNil())
                expect(state1.hubConnectInfo) == []
                expect(state1.setupState) == "PENDING"
            }
            
            it("should JSON-roundtrip") {

                guard let state1: DeviceModelState = try! self.fixture(named: "deviceModelState_deviceAssociate1") else {
                    fail("Unable to instantiate fixture1.")
                    return
                }
                
                let state1Json = state1.JSONDict!
                
                guard let state2: DeviceModelState = |<state1Json else {
                    fail("Unable to instantiate from JSONDict")
                    return
                }
                
                expect(state2) == state1
                
            }
            
        }
        
        describe("Computed properties") {
            
            it("Should compute timestamps correctly") {
                var state = DeviceModelState()
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)
                
                state.updatedTimestampMillis = 1_000
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)
                
                state.updatedTimestampMillis = 10_000
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)

                state.updatedTimestampMillis = 100_000
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)
                
                state.updatedTimestampMillis = 1_000_000
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)

                state.updatedTimestampMillis = 10_000_000
                expect(state.updatedTimestamp) == Date.dateWithMillisSince1970(state.updatedTimestampMillis)
            }
        }
        
        
    }
    
}
