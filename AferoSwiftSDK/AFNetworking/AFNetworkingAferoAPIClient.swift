//
//  AferoAPIClient.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import AFNetworking
import AFOAuth2Manager
import PromiseKit

public class AFNetworkingAferoAPIClient {

    public struct Config {
        
        let oauthClientId: String
        let oauthClientSecret: String
        let apiBaseURL: URL
        
        public init(apiBaseURL: URL = URL(string: "https://api.afero.io/")!, oauthClientId: String, oauthClientSecret: String) {
            self.apiBaseURL = apiBaseURL
            self.oauthClientId = oauthClientId
            self.oauthClientSecret = oauthClientSecret
        }
        
        static let OAuthClientIdKey = "OAuthClientId"
        static let OAuthClientSecretKey = "OAuthClientSecret"
        static let APIBaseURLKey = "APIBaseURL"
        
        init(with plistData: Data) {
            
            let plistDict: [String: Any]
            
            do {
                guard let maybePlistDict = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
                    fatalError("plist data is not a dict.")
                }
                plistDict = maybePlistDict
                
            } catch {
                fatalError("Unable to read dictionary from plistData: \(String(reflecting: error))")
            }
            
            let clientIdKey = type(of: self).OAuthClientIdKey
            let clientSecretKey = type(of: self).OAuthClientSecretKey
            
            guard let oauthClientId = plistDict[clientIdKey] as? String else {
                fatalError("No string keyed by \(clientIdKey) found in \(String(describing: plistDict))")
            }
            
            guard let oauthClientSecret = plistDict[clientSecretKey] as? String else {
                fatalError("No string keyed by \(clientSecretKey) found in \(String(describing: plistDict))")
            }
            
            var apiBaseURL: URL = URL(string: "https://api.afero.io/")!
            if let maybeApiBaseURLString = plistDict[type(of: self).APIBaseURLKey] as? String {
                
                guard let overrideURL = URL(string: maybeApiBaseURLString) else {
                    fatalError("Invalid url: \(maybeApiBaseURLString)")
                }
                
                apiBaseURL = overrideURL
                NSLog("Overriding apiBaseUrl with \(apiBaseURL)")
            }
            
            self.init(apiBaseURL: apiBaseURL, oauthClientId: oauthClientId, oauthClientSecret: oauthClientSecret)
        }
        
        init(withPlistNamed plistName: String) {
            
            guard let plist = Bundle.main.path(forResource: plistName, ofType: "plist") else {
                fatalError("Unable to find plist '\(plistName).plist' in main bundle; can't create API client.")
            }
            
            guard let plistData = FileManager.default.contents(atPath: plist) else {
                fatalError("Unable to read plist '\(plistName).plist' in main bundle.")
            }
            
            self.init(with: plistData)
        }
        
    }

    let TAG = "AferoAPIClient"

    var apiBaseURL: URL { return config.apiBaseURL }
    var oauthClientId: String { return config.oauthClientId }
    var oauthClientSecret: String { return config.oauthClientSecret }
    
    let config: Config
    
    public init(config: Config) {
        self.config = config
    }
    
    public convenience init(withPlistNamed plistName: String) {
        self.init(config: Config(withPlistNamed: plistName))
    }

    // MARK: - Session Manager... management -
    lazy fileprivate var sessionManager: AFHTTPSessionManager! = {

        let manager = AFHTTPSessionManager(baseURL: self.apiBaseURL)

        manager.responseSerializer = AferoAFJSONResponseSerializer()
        manager.requestSerializer = AferoAFJSONRequestSerializer()
        manager.requestSerializer.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")

        if let credential = self.oauthCredential {
            manager.requestSerializer.setAuthorizationHeaderFieldWith(credential)
        }

        return manager
    }()

}

// MARK: - OAuth -

public extension AFNetworkingAferoAPIClient {

    var oauthCredentialIdentifier: String { return apiBaseURL.host! }

    var oauthCredential: AFOAuthCredential? {
        get {
            return AFOAuthCredential.retrieveCredential(withIdentifier: self.oauthCredentialIdentifier)
        }
    }

    static let OAUTH_TOKEN_PATH = "/oauth/token"

    /// Attempt to obtain a valid OAUTH2 token from the service.
    /// - parameter username: The "username" (currently email address) to use to authenticate to the service.
    /// - parameter password: The password to use for authentication
    /// - parameter scope: Should always be `account` (the default)
    /// - returns: A Promise<Void> which fulfills once the OAUTH2 token has been successfully retrieved and stored,
    ///            and rejects on any failure.

    func signIn(username: String, password: String, scope: String = "account") -> Promise<Void> {

        let clientTokenPath = type(of: self).OAUTH_TOKEN_PATH

        return Promise {

            fulfill, reject in

            let oauthManager = AFOAuth2Manager(
                baseURL: self.apiBaseURL,
                clientID: self.oauthClientId,
                secret: self.oauthClientSecret
            )

            _ = oauthManager.authenticateUsingOAuth(
                withURLString: clientTokenPath,
                username: username,
                password: password,
                scope: scope,

                success: {
                    credential in

                    DispatchQueue.main.async {

                        AFOAuthCredential.store(
                            credential,
                            withIdentifier: self.oauthCredentialIdentifier,
                            withAccessibility: kSecAttrAccessibleAfterFirstUnlock
                        )

                        self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWith(credential)
                        fulfill()
                    }
            },

                failure: reject
            )
        }
    }

    func signOut(_ error: Error? = nil) -> Promise<Void> {
        return Promise { fulfill, _ in self.doSignOut(error: error) { fulfill() } }
    }
    
}

extension AFNetworkingAferoAPIClient: AferoAPIClientProto {

    public func doSignOut(error: Error?, completion: @escaping ()->Void) {
        sessionManager.requestSerializer.clearAuthorizationHeader()
        AFOAuthCredential.delete(withIdentifier: oauthCredentialIdentifier)
        completion()
    }
    
    public func doRefreshOAuth(passthroughError: Error? = nil, success: @escaping ()->Void, failure: @escaping (Error)->Void) {
        
        NSLog("Requesting oauth refresh")
        
        guard let credential = oauthCredential else {
            NSLog("No credential; bailing on refresh attempt")
            asyncMain { failure(passthroughError ?? "No credential.") }
            return
        }
        
        let oauthManager = AFOAuth2Manager(
            baseURL: apiBaseURL,
            clientID: oauthClientId,
            secret: oauthClientSecret
        )
        
        oauthManager.authenticateUsingOAuth(
            withURLString: type(of: self).OAUTH_TOKEN_PATH,
            refreshToken: credential.refreshToken,
            success: {
                credential in
                AFOAuthCredential.store(
                    credential,
                    withIdentifier: self.oauthCredentialIdentifier,
                    withAccessibility: kSecAttrAccessibleAfterFirstUnlock
                )
                self.sessionManager.requestSerializer.setAuthorizationHeaderFieldWith(credential)
                success()
        },
            failure: {
                err in failure(err)
        })
        
    }
    
    public func doGet(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask? {
        
        return sessionManager.get(
            urlString,
            parameters: parameters,
            progress: nil,
            success: { (task, result) -> Void in
                asyncGlobalDefault {
                    success(task, result)
                }
        }) { (task, error) -> Void in
            asyncGlobalDefault {
                failure(task, error)
            }
        }

    }
    
    public func doPut(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask? {
        
        return sessionManager.put(
            urlString,
            parameters: parameters,
            success: { (task, result) -> Void in
                asyncGlobalDefault {
                    success(task, result)
                }
        }) { (task, error) -> Void in
            asyncGlobalDefault {
                failure(task, error)
            }
        }

    }
    
    public func doPost(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask? {
        
        return sessionManager.post(
            urlString,
            parameters: parameters,
            progress: nil,
            success: { (task, result) -> Void in
                asyncGlobalDefault {
                    success(task, result)
                }
        }) { (task, error) -> Void in
            asyncGlobalDefault {
                failure(task, error)
            }
        }

    }
    
    public func doDelete(urlString: String, parameters: Any?, success: @escaping AferoAPIClientProtoSuccess, failure: @escaping AferoAPIClientProtoFailure) -> URLSessionDataTask? {
        
        return sessionManager.delete(
            urlString,
            parameters: parameters,
            success: { (task, result) -> Void in
                asyncGlobalDefault {
                    success(task, result)
                }
        }) { (task, error) -> Void in
            asyncGlobalDefault {
                failure(task, error)
            }
        }

    }
    

}

// MARK: - Logging and Debugging Support -

class AferoAFJSONResponseSerializer: AFJSONResponseSerializer {

    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {

        var bodyString = "<empty>"

        if let prettyJson = data?.prettyJSONValue, !prettyJson.isEmpty {
            bodyString = prettyJson
        }

        NSLog("Response: <body>\(bodyString)</body>")
        return super.responseObject(for: response, data: data, error: error) as AnyObject?
    }

}

class AferoAFJSONRequestSerializer: AFJSONRequestSerializer {

    override func request(bySerializingRequest request: URLRequest, withParameters parameters: Any?, error: NSErrorPointer) -> URLRequest? {
        let request = super.request(bySerializingRequest: request, withParameters: parameters, error: error)

        var bodyString = "<empty>"

        if let maybeBody = request?.httpBody?.prettyJSONValue {
            bodyString = maybeBody
        }

        NSLog("Request: <body>\(bodyString)</body>")
        return request
    }

}

