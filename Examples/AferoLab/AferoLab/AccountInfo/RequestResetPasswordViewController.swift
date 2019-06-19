//
//  ResetPasswordViewController.swift
//  AferoLab
//
//  Created by Cora Middleton on 6/11/19.
//  Copyright © 2019 Afero, Inc. All rights reserved.
//

import UIKit
import Afero
import SVProgressHUD
import LKAlertController

class RequestResetPasswordViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTitleLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    
    var email: String? {
        didSet { emailTextField?.text = email }
    }
    
    @IBOutlet weak var requestResetCodeButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    func requestCode(for credentialId: String?) {
        
        guard let credentialId = credentialId, !credentialId.isEmpty else {
            return
        }
        
        guard let appId = Bundle.main.bundleIdentifier else {
            fatalError("Unable to determine appId (bundleIdentifier")
        }

        SVProgressHUD.show(withStatus: NSLocalizedString("Requesting code…", comment: "Request password reset code in progress"))
        
        updateUI()
        
        AFNetworkingAferoAPIClient.default.sendPasswordRecoveryEmail(for: credentialId, appId: appId).then {
            [weak self] () -> Void in
            SVProgressHUD.dismiss()
            self?.showConfirmationAlert(for: credentialId)
            self?.updateUI()
            }.catch {
                [weak self] err in
                SVProgressHUD.dismiss()
                Alert(
                    title: NSLocalizedString(
                        "Error requesting reset code.",
                        comment: "RequestCode PasswordChanged alert title"
                    ),
                    message: String(
                        format: NSLocalizedString(
                            "Reset code request failed with error %@.",
                            comment:"ResetPassword PasswordChanged alert message"
                        ),
                        "\(err.httpStatusCode?.description ?? "-"): \(err.localizedDescription)")
                    ).showOkay()

                self?.updateUI()
        }
        
    }
    
    func updateUI() {
        requestResetCodeButton.isEnabled = !(emailTextField.text?.isEmpty ?? true)
        emailTextField.text = email
    }
    
    func showConfirmationAlert(for emailAddress: String) {
        Alert(
            title: NSLocalizedString(
                "Code Sent",
                comment: "RequestResetPassword code sent title"
            ),
            message:
            String(format:
                NSLocalizedString("A reset code has been sent to %@. Once it arrives, you can reset your password by tapping 'I have a reset code.' below, or on the Sign-In screen.",
                                  comment: "RequestResetPassword code sent message template"),
                   emailAddress)
            ).addAction(
                NSLocalizedString(
                    "I have a reset code.",
                    comment: "RequestResetPassword i have a reset code"
                ),
                style: .default) {
                    [weak self] _ in print("I have a code tapped.")
                    SVProgressHUD.dismiss()
                    self?.performSegue(withIdentifier: "showPasswordResetFromCodeRequest", sender: self)
                    
            }.addAction(
                NSLocalizedString(
                    "Done",
                    comment: "RequestResetPassword done"
                ),
                style: .cancel) {
                    [weak self] _ in
                    print("Cancel tapped.")
                    SVProgressHUD.dismiss()
                    self?.performSegue(withIdentifier: "unwindToSignIn", sender: self)
            }.show()
    }
    
    // MARK: - Actions
    
    @IBAction func requestResetCodeTapped(_ sender: UIButton) {
        emailTextField.resignFirstResponder()
        requestCode(for: emailTextField.text)
    }
    
    @IBAction func emailTextFieldChanged(_ sender: Any) {
        email = emailTextField?.text
        updateUI()
    }
    
    // MARK: - <UITextFieldDelegate>
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
}
