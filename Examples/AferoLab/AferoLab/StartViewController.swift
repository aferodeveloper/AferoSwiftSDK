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
    
    
    
    
    func beginSignin() {
//        let oAuthTokenURL = AFNetworkingAferoAPIClient.default.oAuthTokenURL
//        var oAuthBaseUrl: URL?
//        if let scheme = oAuthTokenURL?.scheme,let host = oAuthTokenURL?.host {
//            oAuthBaseUrl = URL(string: "\(scheme)://\(host)");
//        }
//        print ("path \(oAuthBaseUrl?.description)")
//
//        return
        
        
        let authorizationEndpoint = URL(string: "https://accounts.hubspaceconnect.com/auth/realms/thd/protocol/openid-connect/auth")!
        let tokenEndpoint = URL(string: "https://accounts.hubspaceconnect.com/auth/realms/thd/protocol/openid-connect/token")!
        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint,
                                                    tokenEndpoint: tokenEndpoint)
        let clientID = "hubspace_ios"
        let redirectURI = URL(string: "hubspace-internal://loginredirect")!

        
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
//            self.setAuthState(authState)
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
//            self.setAuthState(nil)
          }
        }
        
        

        }
    
    
    @IBAction func returnToAccountController(_ sender: Any) {
        performSegue(withIdentifier: "unwindToAccountController2", sender: self)
    }


}
