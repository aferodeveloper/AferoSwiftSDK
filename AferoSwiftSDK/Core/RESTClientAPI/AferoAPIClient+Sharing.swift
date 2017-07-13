//
//  APIiClient+Sharing.swift
//  Pods
//
//  Created by Justin Middleton on 7/7/17.
//
//

import Foundation
import PromiseKit

public extension AferoAPIClientProto {
    
    // MARK: - Account Access and Sharing
    
    public typealias AccountUserSummary = (users: [UserAccount.User], invitations: [Invitation])
    
    /// Fetch a summary of users who have access to accounts, and the
    /// open invitations on an account.
    ///
    /// - parameter accountId: The account for which to fetch access details
    /// - returns: A `Promise<AccountUserSummary>`
    
    public func fetchAccountUserSummary(_ accountId: String) -> Promise<AccountUserSummary> {
        
        return GET("/v1/accounts/\(accountId)/accountUserSummary").then {
            (maybeBody: Any?) throws -> AccountUserSummary in
            
            guard
                let body = maybeBody as? [String: Any],
                let users: [UserAccount.User] = |<(body["users"] as? [Any]),
                let invitations: [Invitation] = |<(body["invitations"] as? [Any]) else {
                    throw NSError.UnexpectedResult(localizedDescription: "Unable to decode AccountUserSummary.")
            }
            
            return (users: users, invitations: invitations)
        }
    }
    
    /// NOTE: Deprectated. See `fetchAccountUserSummary()`.
    ///
    /// Get a list of users with access to the given account.
    ///
    /// - parameter accountId: The account for which to fetch access details
    
    public func fetchAccountAccess(_ accountId: String) -> Promise<[UserAccount.User]> {
        return GET("/v1/accounts/\(accountId)/userAccountAccess")
    }
    
    /// Revoke access for a given userId.
    ///
    /// - parameter accountId: The account for which to revoke access.
    /// - parameter userId: The user for which to revoke access
    /// - returns: A `Promise<Void>`
    
    public func revokeAccountAccess(_ accountId: String, userId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/userAccountAccess/\(userId)")
    }
    
    /// Send an invitation to access the given account.
    ///
    /// - parameter accountId: The account for which access is being granted.
    /// - parameter userId: The id of the user sending the invitation.
    /// - parameter group: CURRENTLY UNUSED. The group ID to which to grant access; nil assumes account-wide. Defaults to `nil`.
    /// - parameter email: The email address to which to send the invitation.
    /// - parameter locale: The optional locale to use for inviting the user. Defaults to Hobson's choice.
    /// - parameter startAccess: The date at which access shall start. Defaults to no start date.
    /// - parameter endAccess: The date at which access shall end. Defaults to no end date.
    /// - parameter canWrite: Whether or not the account being invited will be able to modify devices. Defaults to `false`
    /// - parameter owner: Whether or not the user will be be an owner, and therefore able to invite other users, etc. Defaults to `false`.
    /// - returns: a `Promise<Void>`
    
    public func sendAccountAccessInvitation(accountId: String, userId: String, group: String? = nil, email: String, message: String? = nil, locale: String? = nil, startAccess: Date? = nil, endAccess: Date? = nil, canWrite: Bool = false, owner: Bool = false) -> Promise<Void> {
        
        var params: [String: Any] = [
            "targetEmail": email,
            "targetLocale": "",
            "sourceAccountId": accountId,
            "sourceUserId": userId,
            "startAccessTimestamp": 0,
            "endAccessTimestamp": 0,
            "accountPrivilegesDto": [
                "canWrite": canWrite,
                "owner": owner,
            ],
            ]
        
        if let message = message {
            params["customMessage"] = message
        }
        
        if let locale = locale {
            params["targetLocale"] = locale
        }
        
        if let startAccess = startAccess {
            params["startAccessTimestamp"] = startAccess
        }
        
        if let endAccess = endAccess {
            params["endAccessTimestamp"] = endAccess.millisSince1970
        }
        
        return POST("/v1/accounts/\(accountId)/invitations",
            parameters: params)
        
    }
    
    /// Revoke a pending invitation.
    ///
    /// - parameter accountId: The account for which to revoke access.
    /// - parameter invitationId: The invitation to revoke.
    
    public func revokeAccountAccessInvitation(_ accountId: String, invitationId: String) -> Promise<Void> {
        return DELETE("/v1/accounts/\(accountId)/invitations/\(invitationId)")
    }
    

}
