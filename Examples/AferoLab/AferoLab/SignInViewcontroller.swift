//
//  SignInViewcontroller.swift
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
import SVProgressHUD

// MARK: - SignIn -

class SignInViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.text = UserDefaults.standard.emailAddress
        emailTextField.delegate = self
        passwordTextField.delegate = self
        updateSignInButtonEnabledState()
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBAction func emailChanged(_ sender: Any) {
        updateSignInButtonEnabledState()
    }
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBAction func passwordChanged(_ sender: Any) {
        updateSignInButtonEnabledState()
    }
    
    // MARK: <UITextFieldDelegate>
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField == emailTextField {
            textField.resignFirstResponder()
            passwordTextField.becomeFirstResponder()
        }
        
        if textField == passwordTextField {
            textField.resignFirstResponder()
            beginSignin()
        }
        
        return false
    }
    
    var canAttemptSignin: Bool {
        guard !(emailTextField.text?.isEmpty ?? true),
        !(passwordTextField.text?.isEmpty ?? true) else {
            return false
        }
        return true
    }
    
    func updateSignInButtonEnabledState() {
        signInButton.isEnabled = canAttemptSignin
        passwordTextField.enablesReturnKeyAutomatically = true
    }
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBAction func signInTapped(_ sender: Any) {
        beginSignin()
    }
    
    func beginSignin() {
        
        guard
            canAttemptSignin,
            let email = emailTextField.text,
            let password = passwordTextField.text else {
                return
        }
        
        activityIndicator.startAnimating()
        AFNetworkingAferoAPIClient.default.signIn(username: email, password: password)
            .then {
                ()->Void in
                UserDefaults.standard.emailAddress = email
                self.activityIndicator.stopAnimating()
                self.returnToAccountController(self)
            }.catch {
                DDLogError("Error signinig in: \($0.localizedDescription)")
                SVProgressHUD.showError(withStatus: "Unable to sign in (\($0.localizedDescription))")
            }.always {
                self.activityIndicator.stopAnimating()
        }
    }
    
    @IBAction func returnToAccountController(_ sender: Any) {
        performSegue(withIdentifier: "unwindToAccountController", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
}

extension UserDefaults {
    
    var emailAddress: String? {
        get { return string(forKey: "emailAddress") }
        set { set(newValue, forKey: "emailAddress") }
    }
    
}
