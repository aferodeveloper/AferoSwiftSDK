//
//  APIClientTests.swift
//  iTokui
//
//  Created by Justin Middleton on 5/15/17.
//  Copyright © 2017 Kiban Labs, Inc. All rights reserved.
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

class APIClientAccountSpec: QuickSpec {
    
    override func spec() {
        describe("when calling fetchAccountInfo()") {

            guard let janeDoeUser: UserAccount.User = try! fixture(named: "userJaneDoe")
                else {
                    fatalError("Unable to read JSON reasource 'userJaneDoe'.")
            }
            
            var apiClient: MockAPIClient! = nil
            
            beforeEach {
                apiClient = MockAPIClient()
            }
            
            afterEach {
                OHHTTPStubs.removeAllStubs()
            }
            
            it("should GET /users/me.") {

                stub(condition: isPath("/v1/users/me") && isMethodGET()) {
                    request in
                    return OHHTTPStubsResponse(jsonObject: janeDoeUser.JSONDict!, statusCode: 200, headers: nil)
                }
                
                var fetchedUser: UserAccount.User?
                var error: Error?

                expect(apiClient.refreshOauthCount) == 0
                
                _ = apiClient.fetchAccountInfo()
                    .then {
                        user -> Void in
                        fetchedUser = user
                    }.catch {
                        err in
                        error = err
                }
                
                expect(error).to(beNil())
                expect(apiClient.refreshOauthCount).toNotEventually(beGreaterThan(0), timeout: 5.0)
                expect(fetchedUser).toEventually(equal(janeDoeUser), timeout: 5.0)
            }
            
            it("should not refresh oauth if a 503 is encountered.") {
                
                stub(condition: isPath("/v1/users/me") && isMethodGET()) {
                    request in
                    return OHHTTPStubsResponse(jsonObject: ["error_description", "service unavailable"], statusCode: 503, headers: nil)
                }
                
                var fetchedUser: UserAccount.User?
                var error: Error?
                
                expect(apiClient.refreshOauthCount) == 0
                
                _ = apiClient.fetchAccountInfo()
                    .then {
                        user -> Void in
                        fetchedUser = user
                    }.catch {
                        err in
                        error  = err
                }
                
                expect(apiClient.refreshOauthCount).toNotEventually(beGreaterThan(0), timeout: 5.0)
                expect(fetchedUser != nil).toNotEventually(beTrue(), timeout: 5.0)
                expect(error?.httpStatusCodeValue).toEventually(equal(.serviceUnavailable))
            }
            
            it("should not refresh oauth if a 500 is encountered.") {
                
                stub(condition: isPath("/v1/users/me") && isMethodGET()) {
                    request in
                    return OHHTTPStubsResponse(jsonObject: ["error_description", "service unavailable"], statusCode: 500, headers: nil)
                }
                
                var fetchedUser: UserAccount.User?
                var error: Error?
                
                expect(apiClient.refreshOauthCount) == 0
                
                _ = apiClient.fetchAccountInfo()
                    .then {
                        user -> Void in
                        fetchedUser = user
                    }.catch {
                        err in
                        error  = err
                }
                
                expect(apiClient.refreshOauthCount).toNotEventually(beGreaterThan(0), timeout: 5.0)
                expect(fetchedUser != nil).toNotEventually(beTrue(), timeout: 5.0)
                expect(error?.httpStatusCodeValue).toEventually(equal(.internalServerError))
                
            }
            
            it("should attempt to refresh OAuth but not change availability if a 401 is encountered.") {
                
                stub(condition: isPath("/v1/users/me") && isMethodGET()) {
                    _ in
                    let resp = ["error_description": "authentication required"]
                    return OHHTTPStubsResponse(jsonObject: resp, statusCode: 401, headers: nil)
                }

                var response: Any?
                var error: Error?
                
                expect(apiClient.refreshOauthCount) == 0

                _ = apiClient.fetchAccountInfo()
                    .then {
                        resp -> Void in
                        response = resp
                    }.catch {
                        err in
                        error = err
                }
                
                expect(response != nil).toNotEventually(beTrue(), timeout: 5.0)
                expect(error).toNotEventually(beNil(), timeout: 5.0)
                expect(error?.httpStatusCodeValue).toEventually(equal(.unauthorized), timeout: 5.0)
                expect(apiClient.refreshOauthCount).toEventually(equal(1), timeout: 5.0)

            }
            
            it("should not attempt to refresh OAuth or change availability if a 403 is encountered.") {
                
                stub(condition: isPath("/v1/users/me") && isMethodGET()) {
                    _ in
                    let resp = ["error_description": "authentication required"]
                    return OHHTTPStubsResponse(jsonObject: resp, statusCode: 403, headers: nil)
                }
                
                var response: Any?
                var error: Error?
                
                expect(apiClient.refreshOauthCount) == 0
                
                _ = apiClient.fetchAccountInfo()
                    .then {
                        resp -> Void in
                        response = resp
                    }.catch {
                        err in
                        error = err
                }
                
                expect(response != nil).toNotEventually(beTrue(), timeout: 5.0)
                expect(error).toNotEventually(beNil(), timeout: 5.0)
                expect(error?.httpStatusCodeValue).toEventually(equal(.forbidden), timeout: 5.0)
                expect(apiClient.refreshOauthCount).toNotEventually(beGreaterThan(0), timeout: 5.0)
                
            }
        }
    }
}
