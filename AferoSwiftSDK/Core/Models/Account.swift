//
//  Account.swift
//  iTokui
//
//  Created by Justin Middleton on 8/14/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation


import CocoaLumberjack

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


// MARK: - Protocols

/*
We have a few different ways of representing users and accounts on the service;
where possible, we refer to them by protocol on the client.
*/

// MARK: AccountAccess

public protocol AccountAccessPrivilegesRepresentable {
    var canWrite: Bool { get }
    var owner: Bool { get }
}

public protocol AccountAccessRepresentable {

    var accountId: String { get }
    var userId: String? { get }

    associatedtype PrivilegesType: AccountAccessPrivilegesRepresentable
    var privileges: PrivilegesType { get }

    var startAccess: Date? { get }
    var endAccess: Date? { get }
}

// MARK: Partner

public protocol PartnerRepresentable {
    var name: String { get }
    var partnerId: String { get }
    var created: Date { get }
}

public protocol PartnerPrivilegesRepresentable {

    var owner: Bool { get }
    var inviteUsers: Bool { get }
    var manageDeviceProfiles: Bool { get }
    var viewDeviceInfo: Bool { get }
}

public protocol PartnerAccessRepresentable {

    associatedtype PartnerType: PartnerRepresentable
    var partner: PartnerType { get }

    associatedtype PartnerPrivilegesType: PartnerPrivilegesRepresentable
    var privileges: PartnerPrivilegesType { get }
}

// MARK: ToS



// MARK: User

// MARK: - Implementation: PartnerAccess

public struct PartnerAccess: PartnerAccessRepresentable, Equatable {
    
    public typealias PartnerType = Partner
    public typealias PartnerPrivilegesType = PartnerPrivileges
    
    public var partner: PartnerType
    public var privileges: PartnerPrivilegesType = PartnerPrivileges()
    
    init(partner: Partner, privileges: PartnerPrivileges) {
        self.partner = partner
        self.privileges = privileges
    }

    public struct Partner: PartnerRepresentable, Equatable {
        
        public var name: String
        public var partnerId: String
        public var created: Date
        
        init(name: String, partnerId: String, created: Date) {
            self.name = name
            self.partnerId = partnerId
            self.created = created
        }
    }
    
    public struct PartnerPrivileges: PartnerPrivilegesRepresentable, Comparable {

        public var owner: Bool = false
        public var inviteUsers: Bool = false
        public var manageDeviceProfiles: Bool = false
        public var viewDeviceInfo: Bool = false
        
        init(owner: Bool = false, inviteUsers: Bool = false, manageDeviceProfiles: Bool = false, viewDeviceInfo: Bool = false) {
            self.owner = owner
            self.inviteUsers = inviteUsers
            self.manageDeviceProfiles = manageDeviceProfiles
            self.viewDeviceInfo = viewDeviceInfo
        }
    }
}

public func ==(lhs: PartnerAccess, rhs: PartnerAccess) -> Bool {
    return lhs.partner == rhs.partner && lhs.privileges == rhs.privileges
}

public func <(lhs: PartnerAccess, rhs: PartnerAccess) -> Bool {
    return lhs.privileges < rhs.privileges
}

public func ==(lhs: PartnerAccess.Partner, rhs: PartnerAccess.Partner) -> Bool {
    return lhs.name == rhs.name && lhs.partnerId == rhs.partnerId && lhs.created == rhs.created
}

public func ==(lhs: PartnerAccess.PartnerPrivileges, rhs: PartnerAccess.PartnerPrivileges) -> Bool {
    return lhs.owner == rhs.owner && lhs.inviteUsers == rhs.inviteUsers && lhs.manageDeviceProfiles == rhs.manageDeviceProfiles && lhs.viewDeviceInfo == rhs.viewDeviceInfo
}

public func <(lhs: PartnerAccess.PartnerPrivileges, rhs: PartnerAccess.PartnerPrivileges) -> Bool {

    if lhs == rhs {
        return false
    }
    
    if lhs.owner {
        return false
    } else if rhs.owner {
        return true
    }
    
    if lhs.manageDeviceProfiles {
        return false
    } else if rhs.manageDeviceProfiles {
        return true
    }
    
    if lhs.inviteUsers {
        return false
    } else if rhs.inviteUsers {
        return true
    }
    
    if lhs.viewDeviceInfo {
        return false
    } else if rhs.viewDeviceInfo {
        return true
    }
    
    return false
}

// MARK: - Implementation: UserAccount

public struct UserAccount {
    
    // MARK: UserAccount.User
    
    public struct User: CustomDebugStringConvertible, Hashable, Comparable {
        
        public var debugDescription: String {
            return "<UserAccount.User> userId: \(userId) credentialId: \(String(describing: credentialId)) cname: \(canonicalName) name: \(String(describing: name)) firstName: \(String(describing: firstName)) lastName: \(String(describing: lastName))"
        }
        
        public var lastUsed: Date? = nil
        public var name: String? = nil
        public var firstName: String? = nil
        public var lastName: String? = nil
        public var credential: Credential? = nil
        
        // At the moment, credentialIds currently hang directly off user objects
        // returned from sharing; this allows us to handle both cases. If/when
        // that's fixed (see SERV-970), we can remove this.
        
        public var credentialIdInternal: String? = nil

        // MARK: <UserAccountRepresentable>
        
        public var userId: String

        public var credentialId: String? {
            get { return credential?.credentialId ?? credentialIdInternal }
            set {
                guard credential != nil else {
                    credentialIdInternal = newValue
                    return
                }
                
                guard let newValue = newValue else {
                    assert(false, "Setting nil value on non-optional property credential.credentialId.")
                    return
                }
                
                credential!.credentialId = newValue
            }
        }
        
        /**
        The canonical name of this user for presentation purposes. If the `name`
        field is non-nil, it will be used solely. Otherwise, a space-joined concatenation
        of `firstName` and `lastName`.
        */
        
        public var canonicalName: String {
            
            if let name = name {
                return name
            }
            
            var nameArr = [String]()
            
            if let firstName = firstName {
                nameArr.append(firstName)
            }
            
            if let lastName = lastName {
                nameArr.append(lastName)
            }
            
            return nameArr.joined(separator: " ")
        }
        
        // As mentioned elsewhere, these are here because the AccountAccess types
        // for /accounts/me and /accounts/sharing are different.
        
        public var accountAccess: [AccountAccess]? = nil
        
        public var sharingAccountAccess: SharingAccountAccess? = nil
        
        public typealias PartnerAccessType = PartnerAccess
        public var partnerAccess: [PartnerAccessType]? = nil
        
        public var tos: [ToS]? = nil
        
        public init(userId: String, credentialId: String?, credential: Credential? = nil, firstName: String? = nil, lastName: String? = nil, name: String? = nil, accountAccess: [AccountAccess]? = nil, sharingAccountAccess: SharingAccountAccess? = nil, partnerAccess: [PartnerAccessType]? = nil, tos: [ToS]? = nil, lastUsed: Date? = nil) {

            if firstName == nil && lastName == nil && name == nil {
                fatalError("Need at least one name field to make a valid user object")
            }

            self.userId = userId
            self.credentialIdInternal = credentialId
            self.credential = credential
            self.firstName = firstName
            self.lastName = lastName
            self.name = name
            self.accountAccess = accountAccess
            self.sharingAccountAccess = sharingAccountAccess
            self.partnerAccess = partnerAccess
            self.tos = tos
            self.lastUsed = lastUsed
        }
        
        // MARK: Credential
        
        public struct Credential: Equatable, CustomDebugStringConvertible {

            public var debugDescription: String {
                return "<UserAccount.User.Credential> credentialId: \(credentialId) type: \(type) lastUsed: \(lastUsed) verified: \(verified) failedAttempts: \(failedAttempts)"
            }
            
            public var credentialId: String
            public var type: String
            public var lastUsed: Date
            public var verified: Bool
            public var failedAttempts: Int
            
        }
        
        // MARK: ToS
        
        public struct ToS: CustomDebugStringConvertible  {
            public var currentVersion: Int
            public var userVersion: Int
            public var tosType: String
            public var url: String
            public var needsAcceptence: Bool
            
            public var debugDescription: String {
                return "<UserAccount.User.ToS> currentVersion: \(currentVersion) userVersion: \(userVersion) needsAcceptence: \(needsAcceptence)"
            }
            
            init(currentVersion: Int, userVersion: Int, tosType: String, url: String, needsAcceptence: Bool) {
                self.currentVersion = currentVersion
                self.userVersion = userVersion
                self.tosType = tosType
                self.url = url
                self.needsAcceptence = needsAcceptence
            }
        }
        
        // MARK: Equatable
        
        public static func ==(lhs: UserAccount.User, rhs: UserAccount.User) -> Bool {
            return lhs.name == rhs.name
                && lhs.firstName == rhs.firstName
                && lhs.lastName == rhs.lastName
                && lhs.credential == rhs.credential
                && lhs.accountAccess == rhs.accountAccess
                && lhs.partnerAccess == rhs.partnerAccess
        }
        
        // MARK: Hashable
        
        public func hash(into h: inout Hasher) {
            h.combine(userId)
        }

        // MARK: Comparable
        
        public static func <(lhs: UserAccount.User, rhs: UserAccount.User) -> Bool {
            return lhs.name < rhs.name
        }
        
        // MARK: UserAccount.User.Privileges
        
        public struct Privileges: AccountAccessPrivilegesRepresentable, CustomDebugStringConvertible, Hashable, Comparable {
            
            public var debugDescription: String {
                return "<UserAccount.User.AccountAccess.Privileges> canWrite: \(canWrite), owner: \(owner)"
            }
            
            public var canWrite: Bool = false
            public var owner: Bool = false
            
            init(canWrite: Bool = false, owner: Bool = false) {
                self.canWrite = canWrite
                self.owner = owner
            }
            
            // MARK: <Hashable>
            
            public static func ==(lhs: UserAccount.User.Privileges, rhs: UserAccount.User.Privileges) -> Bool {
                return lhs.canWrite == rhs.canWrite &&
                    lhs.owner == rhs.owner
            }
            
            public func hash(into h: inout Hasher) {
                h.combine(canWrite)
                h.combine(owner)
            }
            
            // MARK: <Comparable>

            public static func <(lhs: UserAccount.User.Privileges, rhs: UserAccount.User.Privileges) -> Bool {
                if lhs.owner == rhs.owner { return lhs.canWrite }
                return lhs.owner
            }
            
        }
        
        // MARK: UserAccount.User.AccountAccess
        
        public struct AccountAccess: Hashable, Comparable, AccountAccessRepresentable, CustomDebugStringConvertible {
            
            public var debugDescription: String {
                return "<UserAccount.User.AccountAccess> accountId: \(accountId) userId: \(String(reflecting: userId)) privileges: \(privileges) startAccess: \(String(reflecting: startAccess)) endAccess: \(String(reflecting: endAccess))"
            }
            
            public var accountId: String { return account.accountId }
            
            public var userId: String?
            
            public typealias PrivilegesType = Privileges
            public var privileges: PrivilegesType = Privileges()
            
            public var startAccess: Date? = nil
            public var endAccess: Date? = nil
            
            public var isOwner: Bool { return privileges.owner }
            public var canWrite: Bool { return privileges.canWrite }
            public var type: String { return account.type }
            public var accountDescription: String? { return account.accountDescription }
            public var accountCreated: Date { return account.created }
        
            var account: Account
            
            init(account: Account, userId: String?, privileges: Privileges, startAccess: Date?, endAccess: Date?) {
                self.account = account
                self.userId = userId
                self.privileges = privileges
                self.startAccess = startAccess
                self.endAccess = endAccess
            }
            
            // MARK: <Equatable>
            
            public static func ==(lhs: UserAccount.User.AccountAccess, rhs: UserAccount.User.AccountAccess) -> Bool {
                return lhs.userId == rhs.userId &&
                    lhs.privileges == rhs.privileges &&
                    lhs.startAccess == rhs.startAccess &&
                    lhs.endAccess == rhs.endAccess &&
                    lhs.account == rhs.account
            }
            
            // MARK: <Hashable>
            
            public func hash(into h: inout Hasher) {
                h.combine(privileges)
                h.combine(account)
                h.combine(userId)
                h.combine(startAccess)
                h.combine(endAccess)
            }
            
            // MARK: <Comparable>
            
            public static func <(lhs: UserAccount.User.AccountAccess, rhs: UserAccount.User.AccountAccess) -> Bool {
                
                if lhs.isOwner != rhs.isOwner {
                    return lhs.isOwner
                }
                
                return lhs.account < rhs.account
            }
            
            // MARK: UserAccount.User.AccountAccess.Account
            
            struct Account: Hashable, Comparable {
                
                var accountId: String
                var type: String
                var accountDescription: String?
                var created: Date
                
                init(accountId: String, type: String, description: String?, created: Date) {
                    self.accountId = accountId
                    self.type = type
                    self.accountDescription = description
                    self.created = created
                }
                
                // MARK: <Hashable>
                
                public func hash(into h: inout Hasher) {
                    h.combine(accountId)
                    h.combine(type)
                    h.combine(accountDescription)
                    h.combine(created)
                }
                
                public static func ==(lhs: UserAccount.User.AccountAccess.Account, rhs: UserAccount.User.AccountAccess.Account) -> Bool {
                    return lhs.accountId == rhs.accountId &&
                        lhs.type == rhs.type &&
                        lhs.accountDescription == rhs.accountDescription
                }
                
                // MARK: <Comparable>
                
                public static func <(lhs: UserAccount.User.AccountAccess.Account, rhs: UserAccount.User.AccountAccess.Account) -> Bool {

                    if lhs.type < rhs.type { return true }
                    if lhs.type > rhs.type { return false }
                    
                    if let lad = lhs.accountDescription, let rad = rhs.accountDescription {
                        if lad < rad { return true }
                        if lad > rad { return false }
                    }
                    
                    return lhs.accountId < rhs.accountId
                }
                
            }

        }
        
        /* Wherein we describe the difference between `SharingAccountAccess` and `AccountAccess`.
        AccountAccess objects come when making a request to /accounts/me. SharingAccountAccess objects
        come from requestion sharing info. They look similar, but have different schemata.
        */
        
        public struct SharingAccountAccess: Hashable, AccountAccessRepresentable, CustomDebugStringConvertible {
            
            public typealias PrivilegesType = Privileges
            
            public var debugDescription: String {
                return "<UserAccount.User.SharingAccountAccess> accountId: \(accountId) userId: \(String(reflecting: userId)) privileges: \(privileges) startAccess: \(String(reflecting: startAccess)) endAccess: \(String(reflecting: endAccess))"
            }
            
            public func hash(into h: inout Hasher) {
                h.combine(accountId)
                h.combine(privileges)
                h.combine(userId)
                h.combine(startAccess)
                h.combine(endAccess)
            }
            
            public var userId: String?
            public var accountId: String
            public var privileges: Privileges
            
            public var startAccess: Date?
            public var endAccess: Date?
            
            init(userId: String, accountId: String, privileges: Privileges, startAccess: Date? = nil, endAccess: Date? = nil) {
                self.userId = userId
                self.accountId = accountId
                self.privileges = privileges
                self.startAccess = startAccess
                self.endAccess = endAccess
            }

        }
        
    }
    
}

public struct Invitation: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return "<Invitation> tokenValue: \(tokenValue) accountId: \(accountId) credentialId: \(credentialId) type: \(invitationType) created: \(createdDate) expires: \(expiresDate) params: \(tokenParams)"
    }
    
    public var tokenValue: String
    public var credentialId: String
    public var invitationType: String
    public var createdDate: Date
    public var expiresDate: Date
    public var tokenParams: [String: Any]
    public var accountId: String
    
    init(tokenValue: String, credentialId: String, invitationType: String, createdDate: Date, expiresDate: Date, tokenParams: [String: Any] = [:], accountId: String) {
        self.tokenValue = tokenValue
        self.credentialId = credentialId
        self.invitationType = invitationType
        self.createdDate = createdDate
        self.expiresDate = expiresDate
        self.tokenParams = tokenParams
        self.accountId = accountId
    }
    
    public subscript(key: String) -> Any? {
        get { return tokenParams[key] }
        set { tokenParams[key] = newValue }
    }
    
}

// MARK: - JSON (Invitations)

extension Invitation: AferoJSONCoding {
    
    static let CoderKeyValue = "value"
    static let CoderKeyCredentialId = "credentialId"
    static let CoderKeyType = "type"
    static let CoderKeyCreatedTimestamp = "createdTimestamp"
    static let CoderKeyExpiresTimestamp = "expiresTimestamp"
    static let CoderKeyTokenParams = "tokenParams"
    static let CoderKeyAccountId = "accountId"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyValue: tokenValue,
            type(of: self).CoderKeyCredentialId: credentialId,
            type(of: self).CoderKeyAccountId: accountId,
            type(of: self).CoderKeyType: invitationType,
            type(of: self).CoderKeyCreatedTimestamp: createdDate.millisSince1970,
            type(of: self).CoderKeyExpiresTimestamp: expiresDate.millisSince1970,
        ]
        
        if let paramString = (try? JSONSerialization.data(withJSONObject: tokenParams, options: []))?.stringValue {
            ret[type(of: self).CoderKeyTokenParams] = paramString
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let tokenValue = json[type(of: self).CoderKeyValue] as? String,
            let accountId = json[type(of: self).CoderKeyAccountId] as? String,
            let credentialId = json[type(of: self).CoderKeyCredentialId] as? String,
            let invitationType = json[type(of: self).CoderKeyType] as? String,
            let createdTimestamp = json[type(of: self).CoderKeyCreatedTimestamp] as? NSNumber,
            let expiresTimestamp = json[type(of: self).CoderKeyExpiresTimestamp] as? NSNumber {
        
                var tokenParams: [String: Any] = [:]
                
                if
                    let paramString = json[type(of: self).CoderKeyTokenParams] as? NSString,
                    let paramData = paramString.data(using: String.Encoding.utf8.rawValue) {
                        
                        do {
                            try tokenParams = (JSONSerialization.jsonObject(with: paramData, options: []) as? [String: Any])!
                        } catch {
                            DDLogError("Error decoding invitation token params: \(error) invitation: \(json)")
                            return nil
                        }
                }
                
                
                let createdDate = Date.dateWithMillisSince1970(createdTimestamp)
                let expiresDate = Date.dateWithMillisSince1970(expiresTimestamp)
                
                self.init(tokenValue: tokenValue, credentialId: credentialId, invitationType: invitationType, createdDate: createdDate, expiresDate: expiresDate, tokenParams: tokenParams, accountId: accountId)

        } else {
            DDLogError("Unable to decode Invitation: \(String(reflecting: json))")
            return nil
        }
    }
}


extension UserAccount.User.ToS: AferoJSONCoding {
    static let CoderKeyCurrentVersion = "currentVersion"
    static let CoderKeyUserVersion = "userVersion"
    static let CoderKeyTosType = "tosType"
    static let CoderKeyUrl = "url"
    static let CoderKeyNeedsAcceptance = "needsAcceptance"
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [:]
        
        ret[type(of: self).CoderKeyCurrentVersion] = currentVersion
        ret[type(of: self).CoderKeyUserVersion] = userVersion
        ret[type(of: self).CoderKeyTosType] = tosType
        ret[type(of: self).CoderKeyUrl] = url
        ret[type(of: self).CoderKeyNeedsAcceptance] = needsAcceptence
        
        return ret
    }
    public init?(json: AferoJSONCodedType?) {
        
        guard let jsonDict = json as? [String: Any] else {
            DDLogError("Unable to decode User: \(String(reflecting: json))")
            return nil
        }
        self.init(
            currentVersion: jsonDict[type(of: self).CoderKeyCurrentVersion] as! Int,
            userVersion: jsonDict[type(of: self).CoderKeyUserVersion] as! Int,
            tosType: jsonDict[type(of: self).CoderKeyTosType] as! String,
            url: jsonDict[type(of: self).CoderKeyUrl] as! String,
            needsAcceptence: jsonDict[type(of: self).CoderKeyNeedsAcceptance] as! Bool
        )
    }
}

// MARK: - JSON (UserAccount)

extension UserAccount.User: AferoJSONCoding {
    
    static let CoderKeyUserId = "userId"
    static let CoderKeyCredentialId = "credentialId"
    static let CoderKeyCredential = "credential"
    static let CoderKeyFirstName = "firstName"
    static let CoderKeyLastName = "lastName"
    static let CoderKeyName = "name"
    static let CoderKeyAccountAccess = "accountAccess"
    
    // Yes, intentional ∆ between key name and value. "userAccountAccess" is /only/ used for sharing.
    static let CoderKeySharingAccountAccess = "userAccountAccess"
    static let CoderKeyPartnerAccess = "partnerAccess"
    static let CoderKeyToS = "tos"

    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyUserId: userId,
        ]
        
        if let credentialId = credentialId {
            ret[type(of: self).CoderKeyCredentialId] = credentialId
        }
        
        if let credential = self.credential {
            ret[type(of: self).CoderKeyCredential] = credential.JSONDict!
        }
        
        if let firstName = firstName {
            ret[type(of: self).CoderKeyFirstName] = firstName
        }
        
        if let lastName = lastName {
            ret[type(of: self).CoderKeyLastName] = lastName
        }
        
        if let name = name {
            ret[type(of: self).CoderKeyName] = name
        }
    
        if let accountAccess = accountAccess {
            ret[type(of: self).CoderKeyAccountAccess] = accountAccess.map { return $0.JSONDict! }
        }

        if let sharingAccountAccess = sharingAccountAccess {
            ret[type(of: self).CoderKeySharingAccountAccess] = sharingAccountAccess.JSONDict!
        }

        if let partnerAccess = partnerAccess {
            ret[type(of: self).CoderKeyPartnerAccess] = partnerAccess.map { return $0.JSONDict! }
        }
        
        if let tos = tos {
            ret[type(of: self).CoderKeyToS] = tos.map { return $0.JSONDict! }
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let userId = json[type(of: self).CoderKeyUserId] as?  String {
                
                self.init(
                    userId: userId,
                    credentialId: json[type(of: self).CoderKeyCredentialId] as? String,
                    credential: |<json[type(of: self).CoderKeyCredential],
                    firstName: json[type(of: self).CoderKeyFirstName] as? String,
                    lastName: json[type(of: self).CoderKeyLastName] as? String,
                    name: json[type(of: self).CoderKeyName] as? String,
                    accountAccess: |<(json[type(of: self).CoderKeyAccountAccess] as? [[String: Any]]),
                    sharingAccountAccess: |<(json[type(of: self).CoderKeySharingAccountAccess] as? [String: Any]),
                    partnerAccess: |<(json[type(of: self).CoderKeyPartnerAccess] as? [[String: Any]]),
                    tos: |<(json[type(of: self).CoderKeyToS] as? [[String: Any]]))
        } else {
            DDLogError("Unable to decode User: \(String(reflecting: json))")
            return nil
        }
    }
    
}

extension UserAccount.User.Credential: AferoJSONCoding {
    
    static let CoderKeyLastUsedTimetamp = "lastUsedTimestamp"
    static let CoderKeyCredentialId = "credentialId"
    static let CoderKeyType = "type"
    static let CoderKeyVerified = "verified"
    static let CoderKeyFailedAttempts = "failedAttempts"
    
    public var JSONDict: AferoJSONCodedType? {
        
        return [
            Swift.type(of: self).CoderKeyCredentialId: credentialId,
            Swift.type(of: self).CoderKeyType: type,
            Swift.type(of: self).CoderKeyVerified: verified,
            Swift.type(of: self).CoderKeyLastUsedTimetamp: lastUsed.millisSince1970,
            Swift.type(of: self).CoderKeyFailedAttempts: failedAttempts,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {

        guard
            let jsonDict = json as? [String: Any],
            let credentialId = jsonDict[Swift.type(of: self).CoderKeyCredentialId] as? String,
            let type = jsonDict[Swift.type(of: self).CoderKeyType] as? String,
            let verified = jsonDict[Swift.type(of: self).CoderKeyVerified] as? Bool,
            let lastUsedTimestamp = jsonDict[Swift.type(of: self).CoderKeyLastUsedTimetamp] as? NSNumber,
            let failedAttempts = jsonDict[Swift.type(of: self).CoderKeyFailedAttempts] as? Int else {
                DDLogError("Unable to decode UserAccount.User.Credential json: \(String(reflecting: json))")
                return nil
        }
        
        let lastUsed = Date.dateWithMillisSince1970(lastUsedTimestamp)
        
        self.init(credentialId: credentialId, type: type, lastUsed: lastUsed, verified: verified, failedAttempts: failedAttempts)
    }
}

extension UserAccount.User.AccountAccess: AferoJSONCoding {
    
    static let CoderKeyAccount = "account"
    static let CoderKeyUserId = "userId"
    static let CoderKeyPrivileges = "privileges"
    static let CoderKeyStartAccess = "startAccessTimestamp"
    static let CoderKeyEndAccess = "endAccessTimestamp"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            Swift.type(of: self).CoderKeyAccount: account.JSONDict!,
            Swift.type(of: self).CoderKeyPrivileges: privileges.JSONDict!,
        ]
        
        if let userId = userId {
            ret[Swift.type(of: self).CoderKeyUserId] = userId
        }
        
        if let startAccess = startAccess {
            ret[Swift.type(of: self).CoderKeyStartAccess] = startAccess.millisSince1970
        }
        
        if let endAccess = endAccess {
            ret[Swift.type(of: self).CoderKeyEndAccess] = endAccess.millisSince1970
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let account: Account = |<(json[Swift.type(of: self).CoderKeyAccount] as? [String: Any]),
            let privileges: UserAccount.User.Privileges = |<(json[Swift.type(of: self).CoderKeyPrivileges] as? [String: Any]) {
                
                var startAccess: Date? = nil
                
                if let startAccessMillis = json[Swift.type(of: self).CoderKeyStartAccess] as? NSNumber {
                    startAccess = Date.dateWithMillisSince1970(startAccessMillis)
                }
                
                var endAccess: Date? = nil
                
                if let endAccessMillis = json[Swift.type(of: self).CoderKeyStartAccess] as? NSNumber {
                    endAccess = Date.dateWithMillisSince1970(endAccessMillis)
                }
                
                self.init(account: account, userId: json[Swift.type(of: self).CoderKeyUserId] as? String, privileges: privileges, startAccess: startAccess as Date?, endAccess: endAccess as Date?)
        } else {
            DDLogError("Unable to decode AccountAccess: \(String(reflecting: json))")
            return nil
        }
    }
}

extension UserAccount.User.SharingAccountAccess: AferoJSONCoding {
    
    static let CoderKeyAccountId = "accountId"
    static let CoderKeyUserId = "userId"
    static let CoderKeyPrivileges = "privileges"
    static let CoderKeyStartAccess = "startAccessTimestamp"
    static let CoderKeyEndAccess = "endAccessTimestamp"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyAccountId: accountId,
            type(of: self).CoderKeyPrivileges: privileges.JSONDict!,
        ]
        
        if let userId = userId {
            ret[type(of: self).CoderKeyUserId] = userId
        }
        
        if let startAccess = startAccess {
            ret[type(of: self).CoderKeyStartAccess] = startAccess.millisSince1970
        }
        
        if let endAccess = endAccess {
            ret[type(of: self).CoderKeyEndAccess] = endAccess.millisSince1970
        }

        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard
            let jsonDict = json as? [String: Any],
            let userId = jsonDict[type(of: self).CoderKeyUserId] as? String,
            let accountId = jsonDict[type(of: self).CoderKeyAccountId] as? String,
            let privileges: PrivilegesType = |<(jsonDict[type(of: self).CoderKeyPrivileges] as? [String: Any]) else {
                DDLogWarn("Unable to decode UserAccount.User.SharingAccountAccess: \(String(reflecting: json))")
                return nil
        }
        
        var startAccess: Date? = nil
        
        if let startAccessNum = jsonDict[type(of: self).CoderKeyStartAccess] as? NSNumber {
            startAccess = Date.dateWithMillisSince1970(startAccessNum)
        }
        
        var endAccess: Date? = nil
        
        if let endAccessNum = jsonDict[type(of: self).CoderKeyStartAccess] as? NSNumber {
            endAccess = Date.dateWithMillisSince1970(endAccessNum)
        }
        
        self.init(
            userId: userId,
            accountId: accountId,
            privileges: privileges,
            startAccess: startAccess,
            endAccess: endAccess
        )
    }
}


// MARK: Equatable

public func ==(lhs: UserAccount.User.Credential, rhs: UserAccount.User.Credential) -> Bool {
    return lhs.credentialId == rhs.credentialId
        && lhs.type == rhs.type
        && lhs.lastUsed == rhs.lastUsed
        && lhs.verified == rhs.verified
        && lhs.failedAttempts == rhs.failedAttempts
}


public func ==(lhs: UserAccount.User.SharingAccountAccess, rhs: UserAccount.User.SharingAccountAccess) -> Bool {
    return lhs.userId == rhs.userId &&
        lhs.accountId == rhs.accountId &&
        lhs.privileges == rhs.privileges &&
        lhs.startAccess == rhs.startAccess &&
        lhs.endAccess == rhs.endAccess
}

public func <(lhs: UserAccount.User.SharingAccountAccess, rhs: UserAccount.User.SharingAccountAccess) -> Bool {
    return lhs.privileges < rhs.privileges
}


extension PartnerAccess: AferoJSONCoding {
    
    static let CoderKeyPartner = "partner"
    static let CoderKeyPrivileges = "privileges"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyPartner: partner.JSONDict!,
            type(of: self).CoderKeyPrivileges: privileges.JSONDict!,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard
            let jsonDict = json as? [String: Any],
            let partner: Partner = |<(jsonDict[type(of: self).CoderKeyPartner] as? [String: Any]),
            let privileges: PartnerPrivileges = |<(jsonDict[type(of: self).CoderKeyPrivileges] as? [String: Any]) else {
                DDLogError("Unable to decode PartnerAccess.PartnerPrivileges: \(String(reflecting: json))")
                return nil
        }
        
        self.init(partner: partner, privileges: privileges)
    }
}
extension PartnerAccess.Partner: AferoJSONCoding {

    static let CoderKeyName = "name"
    static let CoderKeyCreatedTimestamp = "createdTimestamp"
    static let CoderKeyPartnerId = "partnerId"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyName: name,
            type(of: self).CoderKeyPartnerId: partnerId,
            type(of: self).CoderKeyCreatedTimestamp: created.millisSince1970,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard
            let jsonDict = json as? [String: Any],
            let name = jsonDict[type(of: self).CoderKeyName] as? String,
            let partnerId = jsonDict[type(of: self).CoderKeyPartnerId] as? String,
            let created = jsonDict[type(of: self).CoderKeyCreatedTimestamp] as? NSNumber else {
                DDLogError("Unable to decode PartnerAccess.Partner: \(String(reflecting: json))")
                return nil
        }
        
        self.init(name: name, partnerId: partnerId, created: Date.dateWithMillisSince1970(created))
    }
}

extension PartnerAccess.PartnerPrivileges: AferoJSONCoding {
    
    static let CoderKeyOwner = "owner"
    static let CoderKeyInviteUsers = "inviteUsers"
    static let CoderKeyManageDeviceProfiles = "manageDeviceProfiles"
    static let CoderKeyViewDeviceInfo = "viewDeviceInfo"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyOwner: owner,
            type(of: self).CoderKeyInviteUsers: inviteUsers,
            type(of: self).CoderKeyManageDeviceProfiles: manageDeviceProfiles,
            type(of: self).CoderKeyViewDeviceInfo: viewDeviceInfo,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        guard
            let jsonDict = json as? [String: Any],
            let owner = jsonDict[type(of: self).CoderKeyOwner] as? NSNumber,
            let inviteUsers = jsonDict[type(of: self).CoderKeyInviteUsers] as? NSNumber,
            let manageDeviceProfiles = jsonDict[type(of: self).CoderKeyManageDeviceProfiles] as? NSNumber,
            let viewDeviceInfo = jsonDict[type(of: self).CoderKeyViewDeviceInfo] as? NSNumber else {
                DDLogError("Unable to decode PartnerAccess.PartnerPrivileges: \(String(reflecting: json))")
                return nil
        }
        self.init(owner: owner.boolValue, inviteUsers: inviteUsers.boolValue, manageDeviceProfiles: manageDeviceProfiles.boolValue, viewDeviceInfo: viewDeviceInfo.boolValue)
    }
    
}

extension UserAccount.User.AccountAccess.Account: AferoJSONCoding {
    
    static let CoderKeyAccountId = "accountId"
    static let CoderKeyType = "type"
    static let CoderKeyDescription = "description"
    static let CoderKeyCreatedTimestamp = "createdTimestamp"
    
    var JSONDict: AferoJSONCodedType? {
        var ret: [String: Any] = [
            Swift.type(of: self).CoderKeyAccountId: accountId,
            Swift.type(of: self).CoderKeyCreatedTimestamp: created.millisSince1970,
            Swift.type(of: self).CoderKeyType: type
        ]
        
        if let accountDescription = accountDescription {
            ret[Swift.type(of: self).CoderKeyDescription] = accountDescription
        }

        return ret
    }
    
    init?(json: AferoJSONCodedType?) {

        guard
            let jsonDict = json as? [String: Any],
            let accountId = jsonDict[Swift.type(of: self).CoderKeyAccountId] as? String,
            let type = jsonDict[Swift.type(of: self).CoderKeyType] as? String,
            let createdMillis = jsonDict[Swift.type(of: self).CoderKeyCreatedTimestamp] as? NSNumber else {
                DDLogError("Unable to decode UserAccount.User.AccountAccess.Account: \(String(reflecting: json))")
                return nil
        }
        
        let accountDescription = jsonDict[Swift.type(of: self).CoderKeyDescription] as? String

        self.init(accountId: accountId, type: type, description: accountDescription, created: Date.dateWithMillisSince1970(createdMillis))
    }
}


extension UserAccount.User.Privileges: AferoJSONCoding {
    
    static let CoderKeyCanWrite = "canWrite"
    static let CoderKeyOwner = "owner"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyCanWrite: canWrite,
            type(of: self).CoderKeyOwner: owner,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if
            let json = json as? [String: Any],
            let canWrite = json[type(of: self).CoderKeyCanWrite] as? NSNumber,
            let owner = json[type(of: self).CoderKeyOwner] as? NSNumber {
                self.init(canWrite: canWrite.boolValue, owner: owner.boolValue)
        } else {
            DDLogError("Unable to decode Privileges: \(String(reflecting: json))")
            return nil
        }
    }
}
