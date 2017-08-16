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
                expect(state.isAvailable).to(beFalse())
                expect(state.isVisible).to(beFalse())
                expect(state.isDirty).to(beFalse())
                expect(state.isRebooted).to(beFalse())
                expect(state.isConnectable).to(beFalse())
                expect(state.isConnected).to(beFalse())
                expect(state.isDirect).to(beFalse())
                expect(state.RSSI) == 0
                expect(state.locationState) == LocationState.notLocated
                expect(state.isLinked).to(beFalse())
                expect(state.updatedTimestampMillis).to(beCloseTo(Date().millisSince1970, within: 1000))
                expect(state.updatedTimestamp.timeIntervalSinceNow).to(beCloseTo(Date().timeIntervalSinceNow, within: 1.0))
                expect(state.deviceLocalityId).to(beNil())
            }
            
            it("should custom-initialize as expected") {
                let timestampMillis = NSNumber(value: 66666666)
                let localityUUID = NSUUID().uuidString
                
                let state = DeviceModelState(
                    isAvailable: true,
                    isVisible: true,
                    isDirty: true,
                    isRebooted: true,
                    isConnectable: true,
                    isConnected: true,
                    isDirect: true,
                    RSSI: 100,
                    locationState: LocationState.located(
                        at: DeviceLocation(
                            latitude: 20.0,
                            longitude: 30.0,
                            timestamp: Date(),
                            sourceType: .clientIPEstimate
                        )
                    ),
                    isLinked: true,
                    updatedTimestampMillis: timestampMillis,
                    deviceLocalityId: localityUUID
                )
                
                expect(state.isAvailable).to(beTrue())
                expect(state.isVisible).to(beTrue())
                expect(state.isDirty).to(beTrue())
                expect(state.isRebooted).to(beTrue())
                expect(state.isConnected).to(beTrue())
                expect(state.isConnectable).to(beTrue())
                expect(state.isDirect).to(beTrue())
                expect(state.isLinked).to(beTrue())
                expect(state.RSSI) == 100
                expect(state.locationState) == LocationState.located(at: DeviceLocation(latitude: 20.0, longitude: 30.0, sourceType: .clientIPEstimate))
                expect(state.deviceLocalityId) == localityUUID
            }
            

            it("should instantiate from a fixture") {
            
                guard let state1: DeviceModelState = try! self.fixture(named: "deviceModelState_deviceAssociate1") else {
                    fail("Unable to instantiate fixture1.")
                    return
                }
                
                expect(state1.isAvailable).to(beFalse())
                expect(state1.isVisible).to(beFalse())
                expect(state1.isDirty).to(beFalse())
                expect(state1.isRebooted).to(beFalse())
                expect(state1.isConnectable).to(beFalse())
                expect(state1.isConnected).to(beFalse())
                expect(state1.isDirect).to(beFalse())
                expect(state1.RSSI) == 0
                expect(state1.locationState) == LocationState.located(at:
                    DeviceLocation(
                        latitude: 37.8488,
                        longitude: -122.5349,
                        sourceType: .clientIPEstimate
                    )
                )
                expect(state1.isLinked).to(beTrue())
                expect(state1.updatedTimestampMillis) == 1500828122154
                expect(state1.updatedTimestamp) == Date.dateWithMillisSince1970(1500828122154)
                expect(state1.deviceLocalityId).to(beNil())
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
        
        it("Should compare as expected") {
            
            let s1 = DeviceModelState(
                isAvailable: true,
                isVisible: true,
                isDirty: true,
                isRebooted: true,
                isConnectable: true,
                isConnected: true,
                isDirect: true,
                RSSI: 100,
                locationState: LocationState.located(
                    at: DeviceLocation(
                        latitude: 20.0,
                        longitude: 30.0,
                        timestamp: Date(),
                        sourceType: .clientIPEstimate
                    )
                ),
                isLinked: true,
                updatedTimestampMillis: 666666,
                deviceLocalityId: NSUUID().uuidString
            )
            
            var s2 = s1
            s2.isAvailable = false
            
            var s3 = s1
            s3.isVisible = false
            
            var s4 = s1
            s4.isDirect = false
            
            var s5 = s1
            s5.isDirty = false
            
            var s6 = s1
            s6.isRebooted = false
            
            var s7 = s1
            s7.isConnected = false
            
            var s8 = s1
            s8.isConnectable = false
            
            var s9 = s1
            s9.locationState = .notLocated
            
            var s10 = s1
            s10.isLinked = false
            
            var s11 = s1
            s11.deviceLocalityId = NSUUID().uuidString
            
            expect(s1) == s1
            expect(s2) != s1
            expect(s3) != s1
            expect(s4) != s1
            expect(s5) != s1
            expect(s6) != s1
            expect(s7) != s1
            expect(s8) != s1
            expect(s9) != s1
            expect(s10) != s1
            expect(s11) != s1

            expect(s1) != s2
            expect(s2) == s2
            expect(s3) != s2
            expect(s4) != s2
            expect(s5) != s2
            expect(s6) != s2
            expect(s7) != s2
            expect(s8) != s2
            expect(s9) != s2
            expect(s10) != s2
            expect(s11) != s2

            expect(s1) != s3
            expect(s2) != s3
            expect(s3) == s3
            expect(s4) != s3
            expect(s5) != s3
            expect(s6) != s3
            expect(s7) != s3
            expect(s8) != s3
            expect(s9) != s3
            expect(s10) != s3
            expect(s11) != s3

            expect(s1) != s4
            expect(s2) != s4
            expect(s3) != s4
            expect(s4) == s4
            expect(s5) != s4
            expect(s6) != s4
            expect(s7) != s4
            expect(s8) != s4
            expect(s9) != s4
            expect(s10) != s4
            expect(s11) != s4

            expect(s1) != s5
            expect(s2) != s5
            expect(s3) != s5
            expect(s4) != s5
            expect(s5) == s5
            expect(s6) != s5
            expect(s7) != s5
            expect(s8) != s5
            expect(s9) != s5
            expect(s10) != s5
            expect(s11) != s5

            expect(s1) != s6
            expect(s2) != s6
            expect(s3) != s6
            expect(s4) != s6
            expect(s5) != s6
            expect(s6) == s6
            expect(s7) != s6
            expect(s8) != s6
            expect(s9) != s6
            expect(s10) != s6
            expect(s11) != s6

            expect(s1) != s7
            expect(s2) != s7
            expect(s3) != s7
            expect(s4) != s7
            expect(s5) != s7
            expect(s6) != s7
            expect(s7) == s7
            expect(s8) != s7
            expect(s9) != s7
            expect(s10) != s7
            expect(s11) != s7

            expect(s1) != s8
            expect(s2) != s8
            expect(s3) != s8
            expect(s4) != s8
            expect(s5) != s8
            expect(s6) != s8
            expect(s7) != s8
            expect(s8) == s8
            expect(s9) != s8
            expect(s10) != s8
            expect(s11) != s8

            expect(s1) != s9
            expect(s2) != s9
            expect(s3) != s9
            expect(s4) != s9
            expect(s5) != s9
            expect(s6) != s9
            expect(s7) != s9
            expect(s8) != s9
            expect(s9) == s9
            expect(s10) != s9
            expect(s11) != s9

            expect(s1) != s10
            expect(s2) != s10
            expect(s3) != s10
            expect(s4) != s10
            expect(s5) != s10
            expect(s6) != s10
            expect(s7) != s10
            expect(s8) != s10
            expect(s9) != s10
            expect(s10) == s10
            expect(s11) != s10

            expect(s1) != s11
            expect(s2) != s11
            expect(s3) != s11
            expect(s4) != s11
            expect(s5) != s11
            expect(s6) != s11
            expect(s7) != s11
            expect(s8) != s11
            expect(s9) != s11
            expect(s10) != s11
            expect(s11) == s11

        }
        
        it("Should update from a DeviceStreamEvent.Peripheral.Status message") {
            
            var s1 = DeviceModelState(
                isAvailable: false,
                isVisible: false,
                isDirty: false,
                isRebooted: false,
                isConnectable: false,
                isConnected: false,
                isDirect: false,
                RSSI: 100,
                locationState: LocationState.located(
                    at: DeviceLocation(
                        latitude: 20.0,
                        longitude: 30.0,
                        timestamp: Date(),
                        sourceType: .clientIPEstimate
                    )
                ),
                isLinked: false,
                updatedTimestampMillis: 666666,
                deviceLocalityId: NSUUID().uuidString
            )
            
            expect(s1.isAvailable).to(beFalse())
            expect(s1.isVisible).to(beFalse())
            expect(s1.isDirty).to(beFalse())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())
            
            // NOTE: The redundancy below is for checking idempotency.
            
            let u1 = DeviceStreamEvent.Peripheral.Status(isAvailable: true)
            
            s1.update(with: u1)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beFalse())
            expect(s1.isDirty).to(beFalse())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u1)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beFalse())
            expect(s1.isDirty).to(beFalse())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u2 = DeviceStreamEvent.Peripheral.Status(isVisible: true)
            s1.update(with: u2)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beFalse())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u2)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beFalse())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u3 = DeviceStreamEvent.Peripheral.Status(isDirty: true)
            s1.update(with: u3)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u3)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beFalse())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u4 = DeviceStreamEvent.Peripheral.Status(isConnectable: true)
            s1.update(with: u4)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u4)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beFalse())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u5 = DeviceStreamEvent.Peripheral.Status(isConnected: true)
            s1.update(with: u5)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u5)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beFalse())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u7 = DeviceStreamEvent.Peripheral.Status(isRebooted: true)
            s1.update(with: u7)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u7)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beFalse())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            let u8 = DeviceStreamEvent.Peripheral.Status(isDirect: true)
            s1.update(with: u8)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beTrue())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u8)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beTrue())
            expect(s1.RSSI) == 100
            expect(s1.isLinked).to(beFalse())


            let u9 = DeviceStreamEvent.Peripheral.Status(RSSI: 200)
            s1.update(with: u9)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beTrue())
            expect(s1.RSSI) == 200
            expect(s1.isLinked).to(beFalse())

            s1.update(with: u9)
            expect(s1.isAvailable).to(beTrue())
            expect(s1.isVisible).to(beTrue())
            expect(s1.isDirty).to(beTrue())
            expect(s1.isRebooted).to(beTrue())
            expect(s1.isConnectable).to(beTrue())
            expect(s1.isConnected).to(beTrue())
            expect(s1.isDirect).to(beTrue())
            expect(s1.RSSI) == 200
            expect(s1.isLinked).to(beFalse())

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
