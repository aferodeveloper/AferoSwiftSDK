//
//  AferoAFNetworkingAPIClient+Users.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit

public extension AferoAPIClientProto {
    
    /// Fetch a users's account info.
    
    public func fetchAccountInfo() -> Promise<UserAccount.User> {
        return GET("/v1/users/me")
    }
    
    // MARK: - Users
    
    /**
     Request a password reset for the given `credentialId` (email).
     
     - parameter credentialId: The email address associated with the account.
     - returns: A `Promise<Void>` indicating success or failure.
     */
    
    public func resetPassword(_ credentialId: String) -> Promise<Void> {
        
        if let encodedCredential = credentialId.alphanumericURLEncodedString {
            return POST("/v1/credentials/\(encodedCredential)/passwordReset")
        } else {
            return Promise {
                _, reject in
                let errorString = NSLocalizedString("Credential encoding wasn’t successful.", comment: "API client reset password credential encoding error message")
                reject(NSError(code: .encodingFailure, localizedDescription: errorString))
            }
        }
    }
    
    /**
     Create an account.
     - parameter credentialID: The user ID (i.e. email)
     - parameter password: The user's password
     - parameter firstName: User firstname
     - parameter lastName: User lastname
     - parameter credentialType: The type of credential to use; defaults to "email"
     - parameter verified: Whether or not the account should be created with a verified stated. Defaults to false.
     - parameter accountType: Defaults to "CUSTOMER"
     - parameter accountDescription: Defaults to "Primary Account"
     - returns: A `Promse<Any>` with the deserialized JSON results.
     */
    
    public func createAccount(_ credentialId: String, password: String, firstName: String, lastName: String, credentialType: String = "email", verified: Bool = false, accountType: String = "CUSTOMER", accountDescription: String = "Primary Account") -> Promise<Any?>
    {
        let parameters = [
            "account": [
                "type": accountType,
                "description": accountDescription
            ],
            "user": [
                "firstName": firstName,
                "lastName": lastName
            ],
            "credential": [
                "credentialId": credentialId,
                "password": password,
                "type": credentialType,
                "verified": verified
            ]
            ] as [String : Any]
        
        return POST("v1/accounts", parameters: parameters)
    }
    
    public func setAccountDescription(_ accountId: String, description: String) -> Promise<Void> {
        
        let parameters = [
            "description": description
        ]
        
        return PUT("/v1/accounts/\(accountId)/description", parameters: parameters)
    }

}

public extension AferoAPIClientProto {
    
    // MARK: - Remote Notification and Mobile Info
    
    /// Send device environment info to the service, return a promise.
    ///
    /// - parameter userId: The id of the signed-in user. Can be obtained
    ///                     via `UserAccount.User.userId`
    /// - parameter mobileDeviceId: The app-generated `UUID` for this device.
    /// - parameter apnsToken: A valid APNS token, if any.
    /// - returns: A `Promise<Void>`
    ///
    ///  **Important**
    ///
    /// `mobileDeviceId` is an identifier for the the device on which
    /// your app is running. It is used both to obtain authorization to communicate with
    /// realtime Afero Cloud device state updates, iand to manage service-based
    /// information related to state of the mobile device on the Afero cloud, such as
    /// push notification routing.
    ///
    /// `mobileDeviceId` should be a UUID generated and persisted
    /// specifically for this purpose. It **must not** be any identifier
    /// provided by the platform for any other purpose, such as
    /// `UDID` or advertising identifier.
    
    func updateDeviceInfo(userId: String, mobileDeviceId: String, apnsToken: Data? = nil) -> Promise<Void> {
        
        guard let safeUserId = userId.pathAllowedURLEncodedString else {
            return Promise { _, reject in reject("Invalid userId: \(userId)")}
        }
        
        var json: [String: Any] = [
            "platform": "IOS",
            "mobileDeviceId": mobileDeviceId,
            "extendedData": AferoAppEnvironment.environmentInfoDict,
            ]
        
        if let maybeToken = apnsToken {
            json["pushId"] = maybeToken.base64EncodedString(options: NSData.Base64EncodingOptions())
        }
        
        let path = "/v1/users/\(safeUserId)/mobileDevices"
        
        return POST(path, parameters: json)
    }
    
    /// Clear the service's record of this device's association with the given user.
    ///
    /// - parameter userId: The `userId` (NOT `accountId`) for the disassociation.
    /// - parameter mobileDeviceId: The app-generated `UUID` for this device.
    /// - warning: This will include nuking the association between this device
    ///             and its APNS token on the service, among other things.
    ///
    ///  **Important**
    ///
    /// `mobileDeviceId` is an identifier for the the device on which
    /// your app is running. It is used both to obtain authorization to communicate with
    /// realtime Afero Cloud device state updates, iand to manage service-based
    /// information related to state of the mobile device on the Afero cloud, such as
    /// push notification routing.
    ///
    /// `mobileDeviceId` should be a UUID generated and persisted
    /// specifically for this purpose. It **must not** be any identifier
    /// provided by the platform for any other purpose, such as
    /// `UDID` or advertising identifier.

    public func disassociateMobileDeviceData(userId: String, mobileDeviceId: String, attemptOAuthRefresh: Bool = false) -> Promise<Void> {
        
        return DELETE("/v1/users/\(userId)/mobileDevices/\(mobileDeviceId)", attemptOAuthRefresh: attemptOAuthRefresh)
    }
    

}

public extension AferoAPIClientProto {
    
    public func authConclave(accountId: String, userId: String, mobileDeviceId: String, onDone: @escaping AuthConclaveOnDone) {
        _ = authConclave(accountId: accountId, userId: userId, mobileDeviceId: mobileDeviceId).then {
            access in onDone(access, nil)
            }.catch {
                err in onDone(nil, err)
        }
    }
    
    public func authConclave(accountId: String, userId: String, mobileDeviceId: String) -> Promise<ConclaveAccess> {
        
        guard
            let escapedAccountId = accountId.pathAllowedURLEncodedString,
            let escapedMobileDeviceId = mobileDeviceId.pathAllowedURLEncodedString else {
                NSLog("Unable to encode accountId \(accountId) or mobileDeviceId \(mobileDeviceId)")
                return Promise { _, reject in reject("Bad or missing parameters") }
        }
        
        return updateDeviceInfo(userId: userId, mobileDeviceId: mobileDeviceId)
            .then {
                () -> Promise<ConclaveAccess> in
                self.POST("/v1/accounts/\(escapedAccountId)/mobileDevices/\(escapedMobileDeviceId)/conclaveAccess", parameters: [:])
            }.recover {
                err throws -> ConclaveAccess in
                NSLog("Error obtaining ConclaveAccess token: \(String(reflecting: err))")
                let error = err as NSError
                if error.httpStatusCodeValue == .forbidden {
                    NSLog("Access denied by conclave (\(err)); sigining out.")
                    self.doSignOut(error: error, completion: {})
                }
                throw err
        }
        
    }

}

// MARK: - Activity

public extension AferoAPIClientProto {
    
    func fetchActivity(
        _ accountId: String,
        deviceId: String? = nil,
        endTimestamp: Int64? = nil,
        limit: Int = 40,
        historyFilter: String? = nil
        ) -> Promise<[HistoryActivity]> {
        
        var endTimestampNumber = NSNumber(value: Int64(Date().timeIntervalSince1970 * 1000) as Int64)
        if let endTimestamp = endTimestamp {
            endTimestampNumber = NSNumber(value: endTimestamp)
        }
        
        var body: [String: Any] = [
            "endTimestamp": endTimestampNumber,
            "limit": limit,
            ]
        
        if let historyFilter = historyFilter {
            body["filter"] = historyFilter
        }
        
        let path: String
        
        if let deviceId = deviceId {
            path = "/v1/accounts/\(accountId)/devices/\(deviceId)/activity"
        } else {
            path = "/v1/accounts/\(accountId)/activity"
        }
        
        return GET(path, parameters: body)
    }
    
}

