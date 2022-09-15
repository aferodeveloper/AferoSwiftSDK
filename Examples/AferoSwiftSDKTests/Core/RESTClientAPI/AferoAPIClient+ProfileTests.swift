//
//  APIClientTests.swift
//  iTokui
//
//  Created by Cora Middleton on 6/14/2019.
//  Copyright © 2017-2019 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import PromiseKit

import Quick
import Nimble
import HTTPStatusCodes
import OHHTTPStubs

@testable import Afero

/// Tests for the APIClient.
///
/// see https://github.com/AliSoftware/OHHTTPStubs for info on the HTTP stubbing lib.

class APIClientProfileSpec: QuickSpec {
    
    override func spec() {
        
        describe("APIClient+Profile") {
            
            var apiClient: MockAPIClient! = nil
            
            beforeEach {
                apiClient = MockAPIClient()
            }
            
            afterEach {
                HTTPStubs.removeAllStubs()
            }
            
            describe("when calling fetchProfile(assocationId:version:)") {
                
                it("should GET the expected request and handle success") {
                    
                    let associationId = "myAssociationId"
                    let version = 666
                    
                    let path = "/v1/devices/\(associationId)/deviceProfiles/versions/\(version)"
                    let result = DeviceProfile(id: "profileId", deviceType: "deviceType", attributes: [DeviceProfile.AttributeDescriptor]())
                    
                    stub(condition: isPath(path) && isMethodGET()) {
                        _ in OHHTTPStubs.HTTPStubsResponse(jsonObject: result.JSONDict!, statusCode: 200, headers: [:])
                    }
                    
                    var response: DeviceProfile?
                    var error: Error?
                    
                    _ = apiClient.fetchProfile(for: associationId, with: version)
                        .then {
                            response = $0
                        }
                        .catch {
                            error = $0
                    }
                    
                    expect(response).toEventually(equal(result), timeout: DispatchTimeInterval.seconds(5))
                    expect(error != nil).toNotEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
                    
                }
                
                it("should GET the expected request and handle failure") {
                    
                    let associationId = "myAssociationId"
                    let version = 666
                    
                    let path = "/v1/devices/\(associationId)/deviceProfiles/versions/\(version)"
                    
                    stub(condition: isPath(path) && isMethodGET()) {
                        _ in OHHTTPStubs.HTTPStubsResponse(jsonObject: [:], statusCode: 404, headers: [:])
                    }
                    
                    var response: DeviceProfile?
                    var error: Error?
                    
                    _ = apiClient.fetchProfile(for: associationId, with: version)
                        .then {
                            response = $0
                        }
                        .catch {
                            error = $0
                    }
                    
                    expect(response != nil).toEventuallyNot(beTrue(), timeout: DispatchTimeInterval.seconds(5))
                    expect(error?.httpStatusCode != nil).toEventually(equal(404), timeout: DispatchTimeInterval.seconds(5))
                    
                }

            }

            describe("when calling fetchProfile(assocationId:version:onDone:)") {
                
                it("should GET the expected request and handle success") {
                    
                    let associationId = "myAssociationId"
                    let version = 666
                    
                    let path = "/v1/devices/\(associationId)/deviceProfiles/versions/\(version)"
                    let result = DeviceProfile(id: "profileId", deviceType: "deviceType", attributes: [DeviceProfile.AttributeDescriptor]())
                    
                    stub(condition: isPath(path) && isMethodGET()) {
                        _ in OHHTTPStubs.HTTPStubsResponse(jsonObject: result.JSONDict!, statusCode: 200, headers: [:])
                    }
                    
                    var response: DeviceProfile?
                    var error: Error?
                    
                    apiClient.fetchProfile(for: associationId, with: version) {
                        result, err in
                        response = result
                        error = err
                    }
                    
                    expect(response).toEventually(equal(result), timeout: DispatchTimeInterval.seconds(5))
                    expect(error != nil).toNotEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
                    
                }
                
                it("should GET the expected request and handle failure") {
                    
                    let associationId = "myAssociationId"
                    let version = 666
                    
                    let path = "/v1/devices/\(associationId)/deviceProfiles/versions/\(version)"
                    
                    stub(condition: isPath(path) && isMethodGET()) {
                        _ in OHHTTPStubs.HTTPStubsResponse(jsonObject: [:], statusCode: 404, headers: [:])
                    }
                    
                    var response: DeviceProfile?
                    var error: Error?
                    
                    apiClient.fetchProfile(for: associationId, with: version) {
                        result, err in
                        response = result
                        error = err
                    }

                    expect(response != nil).toEventuallyNot(beTrue(), timeout: DispatchTimeInterval.seconds(5))
                    expect(error?.httpStatusCode != nil).toEventually(equal(404), timeout: DispatchTimeInterval.seconds(5))
                    
                }
                
            }

            
        }
    }
}
