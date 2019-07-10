//
//  AferoAFNetworkingAPIClient+Users.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit
import CocoaLumberjack

// MARK: - Users and Accounts -

public extension AferoAPIClientProto {
    
    /// Fetch a users's account info.
    
    func fetchAccountInfo() -> Promise<UserAccount.User> {
        return GET("/v1/users/me")
    }
    
    /**
     Request a password reset for the given `credentialId` (email).
     
     - parameter credentialId: The email address associated with the account.
     - returns: A `Promise<Void>` indicating success or failure.
     */
    
    func resetPassword(_ credentialId: String) -> Promise<Void> {
        
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
    
    private static var platformId: String {

        #if os(iOS)
        return "IOS"
        #endif

        #if os(macOS)
        return "macOS"
        #endif

        #if os(watchOS)
        return "watchOS"
        #endif

        #if os(tvOS)
        return "tvOS"
        #endif

        #if os(Linux)
        return "Linux"
        #endif
    }
    
    private static func httpRequestHeaders(appId: String) -> HTTPRequestHeaders {
        var httpRequestHeaders = HTTPRequestHeaders()
        
        if let appIdHeaderValue = String(format: "%@:%@", appId, platformId).bytes.toBase64() {
            httpRequestHeaders["x-afero-app"] = appIdHeaderValue
        }
        
        return httpRequestHeaders
    }
    
    /// Request a password recovery email.
    ///
    /// - parameter credentialId: The id of (for example, email) of the account
    ///   for which to request a password reset.
    ///
    /// - parameter appId: The id of the app for which the email should be sent
    ///   (e.g. bundleId).
    
    func sendPasswordRecoveryEmail(for credentialId: String, appId: String) -> Promise<Void> {
        let headers = type(of: self).httpRequestHeaders(appId: appId)
        let credentialIdValue = credentialId.pathAllowedURLEncodedString!
        return POST("/v1/credentials/\(credentialIdValue)/passwordReset", httpRequestHeaders: headers)
    }
    
    /// Update a password with a shortcode.
    ///
    /// - parameter password: The new password.
    /// - parameter shortCode: The short code obtained separately (e.g. via recovery email)
    /// - parameter appId: The id of this app (e.g. bundlId)
    
    func updatePassword(with password: String, shortCode: String, appId: String) -> Promise<Void> {
        let headers = type(of: self).httpRequestHeaders(appId: appId)
        let shortCodeValue = shortCode.pathAllowedURLEncodedString!
        let body = [
            "password": password
        ];
        
        return POST("/v1/shortvalues/\(shortCodeValue)/passwordReset", parameters: body, httpRequestHeaders: headers)
    }
    
    /// Update a password while authenticated.
    ///
    /// - parameter password: The new password.
    /// - parameter credentialId: The id (e.g. email) of the user being updated.
    /// - parameter accountId : The id of the account.
    /// - parameter platformId: The platform on which this is being performed. Defaults to IOS.
    
    func updatePassword(with password: String, credentialId: String, accountId: String) -> Promise<Void> {
        let credentialIdValue = credentialId.pathAllowedURLEncodedString!
        let accountIdValue = accountId.pathAllowedURLEncodedString!
        let body = [
            "password": password
        ];
        
        return PUT("/v1/accounts/\(accountIdValue)/credentials/\(credentialIdValue)/password", parameters: body)
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
    
    func createAccount(
        _ credentialId: String,
        password: String,
        firstName: String,
        lastName: String,
        credentialType: String = "email",
        verified: Bool = false,
        accountType: String = "CUSTOMER",
        accountDescription: String = "Primary Account"
        ) -> Promise<Any?>
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
    
    /// Resend a verification email/token for an account.
    ///
    /// When a user creates an account, they are sent a verification token. If
    /// this endpoint is called prior to the verification token being redeemed,
    /// then a new token will be generated and sent.
    ///
    func resendVerificationToken(for credentialId: String) -> Promise<Void> {

        guard let credentialParam = credentialId.pathAllowedURLEncodedString else {
            let msg = "Invalid credentialId."
            DDLogError(msg, tag: TAG)
            return Promise { _, reject in reject(msg) }
        }
        
        return POST("/v1/accounts/\(credentialParam)/verify")
        
    }
    
    /// Set the human-readable description of the account identified by `accountId`.
    ///
    /// - parameter accountId: The id of the account whose description is to be set.
    /// - parameter description: The new description.
    
    func setAccountDescription(_ accountId: String, description: String) -> Promise<Void> {
        
        let parameters = [
            "description": description
        ]
        
        return PUT("/v1/accounts/\(accountId)/description", parameters: parameters)
    }
    

}

// MARK: - Remote Notification and Mobile Client Info -

public extension AferoAPIClientProto {
    
    
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
    /// realtime Afero Cloud device state updates, and to manage service-based
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
        
        if let appId = AferoAppEnvironment.appIdentifier {
            json["appId"] = appId
        } else {
            DDLogError("Unable to determine appId!", tag: TAG)
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

    func disassociateMobileDeviceData(userId: String, mobileDeviceId: String, attemptOAuthRefresh: Bool = false) -> Promise<Void> {
        
        return DELETE("/v1/users/\(userId)/mobileDevices/\(mobileDeviceId)", attemptOAuthRefresh: attemptOAuthRefresh)
    }
    

}

// MARK: - Conclave Access -

extension AferoAPIClientProto {
    
    /// Acquire a Conclave access token.

    public func authConclave(accountId: String) -> Promise<ConclaveAccess> {
        
        guard let escapedAccountId = accountId.pathAllowedURLEncodedString else {
            
            return Promise {
                _, reject in
                let msg = "Unable to escape accountId '\(accountId)'"
                DDLogError("\(msg); bailing.", tag: TAG)
                reject(msg)
            }
            
        }
        
        let body: [String: Any] = [
            "user": true
        ]
        
        return POST("/v1/accounts/\(escapedAccountId)/conclaveAccess", parameters: body)
    }
    
    @available(*, unavailable, message: "Use authConclave(with accountId:).")
    public func authConclave(accountId: String, userId: String, mobileDeviceId: String) -> Promise<ConclaveAccess> {
        return Promise { _, reject in reject("Method unsupported.") }
    }

}

// MARK: - Activity -

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

