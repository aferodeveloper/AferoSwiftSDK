//
//  ResetPasswordWithCodeViewController.swift
//  AferoLab
//
//  Created by Cora Middleton on 6/11/19.
//  Copyright © 2019 Afero, Inc. All rights reserved.
//

import UIKit
import Afero
import SVProgressHUD
import LKAlertController

//import OnePasswordExtension

class ResetPasswordWithCodeViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var resetCodeLabel: UILabel!
    @IBOutlet weak var resetCodeTextField: UITextField!
    
    @IBOutlet weak var newPasswordLabel: UILabel!
    @IBOutlet weak var newPasswordTextField: UITextField!
    
    @IBOutlet weak var verifyPasswordLabel: UILabel!
    @IBOutlet weak var verifyPasswordTextField: UITextField!
    
    @IBOutlet weak var onePasswordButton: UIButton!
    
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func updateUI() {
        
//        onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
        
        let passwordsMatch = self.passwordsMatch
        let resetCodeComplete = self.resetCodeComplete
        
        print("passwordsMatch: \(passwordsMatch) resetCodeComplete: \(resetCodeComplete)")
        
        changePasswordButton.isEnabled = passwordsMatch && resetCodeComplete
    }
    
    var passwordsMatch: Bool {
        return
            !(newPasswordTextField?.text?.isEmpty ?? true) &&
                !(verifyPasswordTextField?.text?.isEmpty ?? true) &&
                (newPasswordTextField?.text == verifyPasswordTextField?.text)
    }
    
    var resetCodeComplete: Bool {
        return (resetCodeTextField?.text?.count ?? 0) == 6
    }
    

    @IBAction func resetCodeEditingChanged(_ sender: Any) {
        updateUI()
    }
    
    @IBAction func newPasswordEditingChanged(_ sender: Any) {
        updateUI()
    }
    
    @IBAction func verifyPasswordEditingChanged(_ sender: Any) {
        updateUI()
    }
    
    @IBAction func changePasswordTapped(_ sender: Any) {
        
        let appId = "io.afero.AferoLab"

        guard
            let resetCode = resetCodeTextField?.text,
            let password = newPasswordTextField?.text else {
                print("Nothing to do!")
                updateUI()
                return
        }
        
        SVProgressHUD.show(withStatus: NSLocalizedString("Updating password...", comment: "ResetPassword updating password status"))
        AFNetworkingAferoAPIClient.default.updatePassword(with: password, shortCode: resetCode, appId: appId)
            .then {
                () -> Void in
                SVProgressHUD.dismiss()
                Alert(
                    title: NSLocalizedString(
                        "Password changed.",
                        comment: "ResetPassword PasswordChanged alert title"
                    ),
                    message: NSLocalizedString(
                        "Your password has been changed; please sign in with your new password.",
                        comment:"ResetPassword PasswordChanged alert message"
                    )
                    ).addAction(
                        NSLocalizedString(
                            "OK",
                            comment: "ResetPassword password changed alert OK"
                        ),
                        style: .cancel,
                        handler: {
                            [weak self] _ in
                            self?.performSegue(withIdentifier: "unwindToSignInFromResetPassword", sender: self)
                    }).show()
            }.catch {
                err in
                SVProgressHUD.dismiss()
                Alert(
                    title: NSLocalizedString(
                        "Error changing password.",
                        comment: "ResetPassword PasswordChanged alert title"
                    ),
                    message: String(
                        format: NSLocalizedString(
                            "Your password has not been changed due to an error: %@.",
                            comment:"ResetPassword PasswordChanged alert message"
                        ),
                        "\(err.httpStatusCode?.description ?? "-"): \(err.localizedDescription)")
                    ).showOkay()
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let nextTextField: UITextField?
        
        switch(textField) {
        case resetCodeTextField:
            nextTextField = newPasswordTextField
        case newPasswordTextField:
            nextTextField = verifyPasswordTextField
        default:
            nextTextField = nil
            break
        }
        
        textField.resignFirstResponder()
        nextTextField?.becomeFirstResponder()
        return false
        
    }
    
}
