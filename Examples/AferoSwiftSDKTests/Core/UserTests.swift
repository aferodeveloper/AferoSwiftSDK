//
//  UserTests.swift
//  iTokui
//
//  Created by Justin Middleton on 5/10/17.
//  Copyright © 2017 Kiban Labs, Inc. All rights reserved.
//

import Foundation
import Quick
import Nimble
@testable import Afero


class UserTests: QuickSpec {
    
    override func spec() {

        let janeDoe: UserAccount.User
        let johnSmith: UserAccount.User
        
        do {
            
            guard
                let janeDoeJSON = try readJson("userJaneDoe"),
                let jdo: UserAccount.User = |<janeDoeJSON else {
                    throw "Read userJaneDoe, but empty result."
            }
            
            janeDoe = jdo
            
            guard
                let johnSmithJSON = try readJson("userJohnSmith"),
                let jso: UserAccount.User = |<johnSmithJSON else {
                    throw "Read userJohnSmith, but empty result."
            }
            
            johnSmith = jso
            
        } catch {
            fatalError("Unable to read fixtures: \(String(reflecting: error))")
        }
        

        describe("When performing UserAccount.User equality checks") {

            it("should show correctly test equality") {

                expect(janeDoe) == janeDoe
                expect(janeDoe) != johnSmith
                
                expect(johnSmith) == johnSmith
                expect(johnSmith) != janeDoe
            }
            
            it("should compare differently if account names change") {

                var janeDoe2 = janeDoe
                
                expect(janeDoe2) == janeDoe
                expect(janeDoe) == janeDoe2

                expect(janeDoe2.accountAccess).toNot(beNil())
                expect(janeDoe2.accountAccess?.count) > 0

                let newAccountName = "I write a rhyme melt in yo mouth like M&Ms"
                expect(janeDoe.accountAccess?[0].accountDescription) != newAccountName
                expect(janeDoe2.accountAccess?[0].accountDescription) != newAccountName
                
                janeDoe2.accountAccess?[0].account.accountDescription = newAccountName
                expect(janeDoe2.accountAccess?[0].accountDescription) == newAccountName
                
                expect(janeDoe2) != janeDoe
                expect(janeDoe) != janeDoe2
                
            }
        }
        
    }
}

class AccountAccessTests: QuickSpec {
    
    override func spec() {

        let cdate = Date()
        
        let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "plunk", created: cdate)
        let u1 = "userid1"
        let p1 = UserAccount.User.Privileges(canWrite: false, owner: false)
        let sa1 = cdate
        let ea1 = sa1.addingTimeInterval(10.0)
        let aa1 = UserAccount.User.AccountAccess(account: a1, userId: u1, privileges: p1, startAccess: sa1, endAccess: ea1)
        
        let a2 = UserAccount.User.AccountAccess.Account(accountId: "bar", type: "poop", description: "flunk", created: cdate)
        let u2 = "userid2"
        let p2 = UserAccount.User.Privileges(canWrite: true, owner: false)
        let sa2 = ea1.addingTimeInterval(10.0)
        let ea2 = ea1.addingTimeInterval(10.0)
        let aa2 = UserAccount.User.AccountAccess(account: a2, userId: u2, privileges: p2, startAccess: sa2, endAccess: ea2)

        
        let a3 = UserAccount.User.AccountAccess.Account(accountId: "tar", type: "doop", description: "crunk", created: cdate)
        let u3 = "userid3"
        let p3 = UserAccount.User.Privileges(canWrite: false, owner: true)
        let sa3 = ea2.addingTimeInterval(10.0)
        let ea3 = ea2.addingTimeInterval(10.0)
        let aa3 = UserAccount.User.AccountAccess(account: a3, userId: u3, privileges: p3, startAccess: sa3, endAccess: ea3)
        
        let a4 = UserAccount.User.AccountAccess.Account(accountId: "bar", type: "doop", description: "junk", created: cdate)
        let u4 = "userid4"
        let p4 = UserAccount.User.Privileges(canWrite: true, owner: true)
        let sa4 = ea3.addingTimeInterval(10.0)
        let ea4 = ea3.addingTimeInterval(10.0)
        let aa4 = UserAccount.User.AccountAccess(account: a4, userId: u4, privileges: p4, startAccess: sa4, endAccess: ea4)
        
        
        describe("When checking accountAccess for equality") {
            
            it("Should compare as expected") {

                expect(aa1) == aa1
                expect(aa1) != aa2
                expect(aa1) != aa3
                expect(aa1) != aa4
                
                expect(aa2) != aa1
                expect(aa2) == aa2
                expect(aa2) != aa3
                expect(aa2) != aa4
                
                expect(aa3) != aa1
                expect(aa3) != aa2
                expect(aa3) == aa3
                expect(aa3) != aa4
                
                expect(aa4) != aa1
                expect(aa4) != aa2
                expect(aa4) != aa3
                expect(aa4) == aa4
                
            }
        }
        
        describe("When sorting accountAccess") {
            
            it("should sort by owner, then account") {
                expect([aa1, aa2, aa3, aa4].sorted()) == [aa3, aa4, aa1, aa2]
                expect([aa4, aa3, aa2, aa1].sorted()) == [aa3, aa4, aa1, aa2]
            }
            
        }
        
    }
}

class PrivilegesSpec: QuickSpec {
    
    override func spec() {
        
        let p1 = UserAccount.User.Privileges(canWrite: false, owner: false)
        let p2 = UserAccount.User.Privileges(canWrite: true, owner: false)
        let p3 = UserAccount.User.Privileges(canWrite: false, owner: true)
        let p4 = UserAccount.User.Privileges(canWrite: true, owner: true)

        describe("When checking for equality") {
        
            it("should compare as expected") {
                
                expect(p1) == p1
                expect(p1) != p2
                expect(p1) != p3
                expect(p1) != p4

                expect(p2) != p1
                expect(p2) == p2
                expect(p2) != p3
                expect(p2) != p4

                expect(p3) != p1
                expect(p3) != p2
                expect(p3) == p3
                expect(p3) != p4

                expect(p4) != p1
                expect(p4) != p2
                expect(p4) != p3
                expect(p4) == p4

            }
        }
        
        describe("When sorting") {
            expect([p1, p2, p3, p4].sorted()) == [p4, p3, p2, p1]
        }
        
    }
}

class AccountSpec: QuickSpec  {

    override func spec() {

        let cdate = Date()
        let cdate2 = Date.dateWithMillisSince1970(0)
        
        describe("When checking accounts for equality") {
            
            it("Accounts should be inequal if accountIds differ") {
                let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: nil, created: cdate)
                let a2 = UserAccount.User.AccountAccess.Account(accountId: "bar", type: "moop", description: nil, created: cdate)
                expect(a1) != a2
            }

            it("Accounts should be inequal if types differ") {
                let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "toop", description: nil, created: cdate)
                let a2 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: nil, created: cdate)
                expect(a1) != a2
            }

            it("Accounts should be inequal if descriptions differ") {
                let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "rundy", created: cdate)
                let a2 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "tundy", created: cdate)
                expect(a1) != a2
            }

            it("Accounts should be equal even if creation dates differ") {
                let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "rundy", created: cdate)
                let a2 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "rundy", created: cdate2)
                expect(a1) == a2
            }

        }
        
        describe("When sorting accounts") {

            it("Should sort accounts by type, then description, then accountid") {

                let a1 = UserAccount.User.AccountAccess.Account(accountId: "foo", type: "moop", description: "plunk", created: cdate)
                let a2 = UserAccount.User.AccountAccess.Account(accountId: "bar", type: "poop", description: "flunk", created: cdate)
                let a3 = UserAccount.User.AccountAccess.Account(accountId: "tar", type: "doop", description: "crunk", created: cdate)
                let a4 = UserAccount.User.AccountAccess.Account(accountId: "bar", type: "doop", description: "junk", created: cdate)
                let a5 = UserAccount.User.AccountAccess.Account(accountId: "car", type: "doop", description: "junk", created: cdate)
                
                expect([a1, a2, a3, a4, a5].sorted()) == [a3, a4, a5, a1, a2]
                
            }
        }
    }
    
}
