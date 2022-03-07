//
//  StartViewController.swift
//  AferoLab
//
//  Created by Martin Arnberg on 2/16/22.
//  Copyright © 2022 Afero, Inc. All rights reserved.
//

import Foundation

import AuthenticationServices
import SafariServices
import AppAuth

import UIKit
import Afero
import ReactiveSwift
import Result
import PromiseKit
import CocoaLumberjack
import SVProgressHUD
import LKAlertController

// MARK: - SignIn -


class StartViewController: UIViewController, ASWebAuthenticationPresentationContextProviding {

    @IBOutlet weak var signInButton: UIButton!
    
    @IBAction func signInTapped(_ sender: Any) {
        beginSignin()
    }
    
    @available(iOS 13, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
    
    
    func getPlist() -> [String: Any] {
        guard let plist = Bundle.main.path(forResource: AFNetworkingAferoAPIClient.DefaultAFNetworkingAPIClientConfig, ofType: "plist") else {
            fatalError("Unable to find plist '\(AFNetworkingAferoAPIClient.DefaultAFNetworkingAPIClientConfig).plist' in main bundle; can't create API client.")
        }
        
        guard let plistData = FileManager.default.contents(atPath: plist) else {
            fatalError("Unable to read plist '\(AFNetworkingAferoAPIClient.DefaultAFNetworkingAPIClientConfig).plist' in main bundle.")
        }
        let plistDict: [String: Any]
        
        do {
            guard let maybePlistDict = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
                fatalError("plist data is not a dict.")
            }
            plistDict = maybePlistDict
            
        } catch {
            fatalError("Unable to read dictionary from plistData: \(String(reflecting: error))")
        }
        return plistDict
    }
    
    func beginSignin() {
        
        let plist = getPlist()
        var maybeTokenEndpoint: URL? = nil
        if let maybeOAuthTokenUrlString = plist["OAuthTokenURL"] as? String {
            maybeTokenEndpoint = URL(string:maybeOAuthTokenUrlString)
        }
        
        var maybeAuthorizationEndpoint: URL? = nil
        if let maybeOAuthAuthUrlString = plist["OAuthAuthURL"] as? String {
            maybeAuthorizationEndpoint = URL(string:maybeOAuthAuthUrlString)
        }
        
        var maybeRedirectURI: URL? = nil
        if let maybeRedirectURIString = plist["OAuthRedirectURL"] as? String {
            maybeRedirectURI = URL(string:maybeRedirectURIString)
        }
        
        
        guard let authorizationEndpoint = maybeAuthorizationEndpoint else {
            fatalError("Missing AuthorizationEndpoint")
        }
        
        
        guard let tokenEndpoint = maybeTokenEndpoint else {
            fatalError("Missing TokenEndpoint")
        }
        
        
        guard let clientID = plist["OAuthClientId"] as? String else {
            fatalError("Missing OAuthClientId")
        }
        
        
        guard let redirectURI = maybeRedirectURI else {
            fatalError("Missing OAuthRedirectURL")
        }
        
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
  
        
        // builds authentication request
        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientID,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile],
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)

        // performs authentication request
        print("Initiating authorization request with scope: \(request.scope ?? "nil")")

        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        appDelegate.currentAuthorizationFlow =
            OIDAuthState.authState(byPresenting: request, presenting: self) { authState, error in
          if let authState = authState {
            print("Got authorization tokens. Access token: " +
                  "\(authState.lastTokenResponse?.accessToken ?? "nil")")
              guard let accessToken = authState.lastTokenResponse?.accessToken else {
                  return
              }
              guard let refreshToken = authState.lastTokenResponse?.refreshToken else {
                  return
              }
              
              AFNetworkingAferoAPIClient.default.signIn(oAuthToken: accessToken, refreshToken: refreshToken)
                  .then {
                      ()->Void in
                      SVProgressHUD.dismiss()
                      self.returnToAccountController(self)
                  }.catch {
                      DDLogError("Error signinig in: \($0.localizedDescription)")
                      SVProgressHUD.showError(withStatus: "Unable to sign in:  (\($0.localizedDescription))")
              }
              
              
          } else {
            print("Authorization error: \(error?.localizedDescription ?? "Unknown error")")
          }
        }
        
        

        }
    
    
    @IBAction func returnToAccountController(_ sender: Any) {
        performSegue(withIdentifier: "unwindToAccountController2", sender: self)
    }


}
