//
//  ViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import AppAuth
import UIKit
import Afero
import ReactiveSwift
import Result
import PromiseKit
import CocoaLumberjack

// MARK: - Root VC -

class AferoLabNavigationController: UINavigationController {
    
    
    // property of the containing class
    private var authState: OIDAuthState?
    
    func presentSignin() {
        
        if (AFNetworkingAferoAPIClient.default.oAuthAuthURL != nil) {
            guard let _ = presentedViewController else {
                performSegue(withIdentifier: "PresentStart", sender: self)
                return
            }

            dismiss(animated: true) {
                [weak self] in self?.performSegue(withIdentifier: "PresentStart", sender: self)
            }
            
        } else {
            guard let _ = presentedViewController else {
                performSegue(withIdentifier: "PresentSignin", sender: self)
                return
            }

            dismiss(animated: true) {
                [weak self] in self?.performSegue(withIdentifier: "PresentSignin", sender: self)
            }
        }
        
    }
    
    var accountController: AccountViewController {
        return viewControllers[0] as! AccountViewController
    }
}

extension UIViewController {
    
    var labNavigationController: AferoLabNavigationController {
        return UIApplication.shared.keyWindow?.rootViewController as! AferoLabNavigationController
    }
    
}

