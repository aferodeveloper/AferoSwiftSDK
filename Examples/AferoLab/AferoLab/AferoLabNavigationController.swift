//
//  ViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import Afero
import ReactiveSwift
import Result
import PromiseKit
import CocoaLumberjack

// MARK: - Root VC -

class AferoLabNavigationController: UINavigationController {
    
    func presentSignin() {
        guard let _ = presentedViewController else {
            performSegue(withIdentifier: "PresentSignin", sender: self)
            return
        }
        
        dismiss(animated: true) {
            [weak self] in self?.performSegue(withIdentifier: "PresentSignin", sender: self)
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

