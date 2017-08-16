//
//  DeviceLocationTests.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 7/23/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero
import CoreLocation

class DeviceLocationSpec: QuickSpec {
    
    override func spec() {
        
        describe("Instantiating") {
            
            it("should default instantiate properly") {
                let location = DeviceLocation()
                expect(location.latitude) == 0
                expect(location.longitude) == 0
                expect(location.sourceType) == DeviceLocation.SourceType.clientIPEstimate
                expect(location.timestamp.timeIntervalSinceNow).to(beCloseTo(0, within: 0.1))
            }
            
            it("should instantiate with latitude and longitude") {
                let location = DeviceLocation(latitude: 90, longitude: 45, sourceType: .hubLocationGPS)
                expect(location.latitude) == 90
                expect(location.longitude) == 45
                expect(location.sourceType) == DeviceLocation.SourceType.hubLocationGPS
            }
            
            it("should instantiate with a CLLocation") {
                
                let cllocation1 = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: 33, longitude: 44),
                    altitude: 1999,
                    horizontalAccuracy: 5.0,
                    verticalAccuracy: 7.0,
                    course: 180,
                    speed: 25,
                    timestamp: Date(timeIntervalSince1970: 1000)
                )
                
                let location1 = DeviceLocation(location: cllocation1, sourceType: .hubLocationIP, formattedAddressLines: ["one", "two", "three"])
                
                // Check to see that we're comparing a copy.
                expect(location1.location === cllocation1).toNot(beTrue())
                
                expect(location1.latitude) == cllocation1.coordinate.latitude
                expect(location1.longitude) == cllocation1.coordinate.longitude
                expect(location1.altitude) == cllocation1.altitude
                expect(location1.horizontalAccuracy) == cllocation1.horizontalAccuracy
                expect(location1.verticalAccuracy) == cllocation1.verticalAccuracy
                expect(location1.course) == cllocation1.course
                expect(location1.speed) == cllocation1.speed
                expect(location1.timestamp) == cllocation1.timestamp
                
            }
            
            it("should instantiate from a fixture") {

                do {
                    guard let locations: [DeviceLocation] = try self.fixture(named: "deviceLocations1") else {
                        fail("Couldn't read fixture 'deviceLocations1'")
                        return
                    }
                    expect(locations.count) == 5
                } catch {
                    fatalError("Error reading fixture 'deviceLocations1': \(String(reflecting: error))")
                }
                
            }
            
            it("should roundtrip") {

                do {
                    
                    guard let locations: [DeviceLocation] = try self.fixture(named: "deviceLocations1") else {
                        fail("Couldn't read fixture 'deviceLocations1'")
                        return
                    }
                    expect(locations.count) == 5
                    
                    guard let newLocations: [DeviceLocation] = |<(locations.JSONDict as? [AferoJSONCodedType]) else {
                        fail("Couldn't instantiate newLocations from locations.")
                        return
                    }
                    
                    expect(newLocations) == locations
                    
                } catch {
                    fatalError("Error reading fixture 'deviceLocations1': \(String(reflecting: error))")
                }
                
            }
        }
    }
    
}
