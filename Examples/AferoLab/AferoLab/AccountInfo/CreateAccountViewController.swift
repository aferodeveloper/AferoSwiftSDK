//
//  CreateAccountViewController.swift
//  AferoLab
//
//  Created by Cora Middleton on 6/12/19.
//  Copyright © 2019 Afero, Inc. All rights reserved.
//

import Foundation

import UIKit
import Afero
import SVProgressHUD
import LKAlertController

import OnePasswordExtension

class CreateAccountViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    @IBOutlet weak var onePasswordButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    
    func updateUI() {
        
        onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
        
        let passwordsMatch = self.passwordsMatch
        
        print("passwordsMatch: \(passwordsMatch)")
        
        createButton.isEnabled = passwordsMatch && emailIsValid
    }
    
    var passwordsMatch: Bool {
        return
            !(passwordTextField?.text?.isEmpty ?? true) &&
                !(verifyPasswordTextField?.text?.isEmpty ?? true) &&
                (passwordTextField?.text == verifyPasswordTextField?.text)
    }
    
    var emailIsValid: Bool {
        return !(emailTextField?.text?.isEmpty ?? true)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: Any) {
        updateUI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let maybeNextResponder: UITextField?
        
        switch textField {
        case firstNameTextField:
            maybeNextResponder = lastNameTextField
        case lastNameTextField:
            maybeNextResponder = emailTextField
        case emailTextField:
            maybeNextResponder = passwordTextField
        case passwordTextField:
            maybeNextResponder = verifyPasswordTextField
        default:
            maybeNextResponder = nil
        }
        
        guard let nextResponder = maybeNextResponder else {
            textField.resignFirstResponder()
            return false
        }
        
        nextResponder.becomeFirstResponder()
        return false
        
    }
    
    
    
}
