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
import CocoaLumberjack
import PromiseKit

//import OnePasswordExtension

class CreateAccountViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    public var email: String? { return emailTextField?.text }
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    public var password: String? { return passwordTextField?.text }
    
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
    
    @IBAction func createTapped(_ sender: Any) {
        
        guard
            let credentialId = emailTextField?.text,
            let password = passwordTextField?.text,
            let firstName = firstNameTextField?.text,
            let lastName = lastNameTextField?.text else {
                print("Missing email, password, firstname or lastname.")
                return
        }
        
        createAccount(credentialId: credentialId, password: password, firstName: firstName, lastName: lastName)
    }
    
    func createAccount(credentialId: String, password: String, firstName: String = "", lastName: String = "") {
        
        guard !credentialId.isEmpty && !password.isEmpty else {
            DDLogError("Neither credentialId nor password can be empty.")
            return
        }
        
        SVProgressHUD.show(
            withStatus: NSLocalizedString(
                "Creating account…",
                comment: "Create account creating account status.")
        )
        
        AFNetworkingAferoAPIClient.default.createAccount(credentialId, password: password, firstName: firstName, lastName: lastName)
            .then {
                _ -> Void in
                SVProgressHUD.showSuccess(withStatus: NSLocalizedString("Done!", comment: "CreateAccount done"))
                self.performSegue(withIdentifier: "signInFromCreateAccount", sender: self)
        }.catch {
                err in
                SVProgressHUD.dismiss()
                Alert(
                    title: NSLocalizedString(
                        "Error creating account",
                        comment: "CreateAccount failure alert title"),
                    message: String(
                        format: NSLocalizedString(
                            "There was an error creating account %@: %@",
                            comment: "CreateAccount failure alert message template"), credentialId, String(describing: err))
                    ).showOkay()
                
        }
    }
    
    
}
