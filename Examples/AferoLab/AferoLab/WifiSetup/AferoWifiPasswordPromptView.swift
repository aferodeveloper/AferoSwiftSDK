//
//  AferoWifiPasswordPromptView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/13/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import Afero

@objc protocol AferoWifiPasswordPromptDelegate: class {

    /// The password view has requested an association attempt to the given ssid, with the given password.
    /// The receiver should call `connectionStatusHandler` with any connection status changes that arrive
    /// during the association process.
    
    func wifiPasswordPromptView(_ promptView: AferoWifiPasswordPromptView, attemptAssociateWith ssid: String, usingPassword: String?, connectionStatusChangeHandler: @escaping (WifiSetupManaging.WifiState)->Void)
    
    func cancelAttemptAssociation(for promptView: AferoWifiPasswordPromptView)

}

@objc @IBDesignable class LengthCheckedUITextField: UITextField {
    
    @IBInspectable var minimumLength: Int = 0
    @IBInspectable var maximumLength: Int = Int.max
    
    override var hasText: Bool {
        guard let text = text else { return super.hasText }
        return (minimumLength...maximumLength).contains(text.count)
    }
    
}

@objc @IBDesignable class AferoWifiPasswordPromptView: XibBasedView, UITextFieldDelegate {

    override var xibName: String { return "AferoWifiPasswordPromptView" }
    
    @IBInspectable var validTextColor: UIColor = .darkText {
        didSet { updateUI() }
    }
    
    @IBInspectable var invalidTextColor: UIColor = .lightGray {
        didSet { updateUI() }
    }

    @IBOutlet weak var contentStack: UIStackView!
    
    // MARK: Activity and Status
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var wifiStateLabel: UILabel!
    
    // MARK: SSID
    @IBOutlet weak var ssidGroup: UIView!

    @IBOutlet weak var ssidTextField: UITextField!

    @IBInspectable var ssid: String? {
        get { return ssidTextField?.text }
        set { ssidTextField?.text = newValue }
    }
    
    @IBInspectable var ssidIsHidden: Bool {
        get { return ssidGroup?.isHidden ?? true }
        set { ssidGroup.isHidden = newValue }
    }
    
    // MARK: Password
    @IBOutlet weak var passwordGroup: UIStackView!
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var showPasswordButton: UIButton!
    
    @IBInspectable var password: String? {
        get { return passwordTextField?.text }
        set { passwordTextField?.text = newValue }
    }
    
    @IBInspectable var passwordIsHidden: Bool {
        get { return passwordGroup?.isHidden ?? true }
        set { passwordGroup.isHidden = newValue }
    }
    
    @IBInspectable var passwordIsEnabled: Bool {
        get { return passwordTextField?.isEnabled ?? false }
        set { passwordTextField?.isEnabled = newValue }
    }
    
    // MARK: UI Sync
    
    func updateUI() {
        ssidTextField.textColor = (ssidTextField?.text?.isValidSSID ?? false) ? validTextColor : invalidTextColor
        
        if passwordTextField?.text?.isValidWPA2Password ?? false {
            passwordTextField.textColor = validTextColor
        } else {
            
        }
        passwordTextField.textColor = (passwordTextField?.text?.isValidWPA2Password ?? false) ? validTextColor : invalidTextColor
        
        let showPasswordTitle = passwordTextField.isSecureTextEntry ? NSLocalizedString("Show", comment: "Show password button title") : NSLocalizedString("Hide", comment: "Hide password button title")
        
        showPasswordButton.setTitle(showPasswordTitle, for: .normal)
    }
    
    // MARK: Actions
    
    @IBAction func showPasswordTapped(_ sender: Any) {
        passwordTextField.isSecureTextEntry = !passwordTextField.isSecureTextEntry
        updateUI()
    }
    
    @IBAction func ssidEditingChanged(_ sender: Any) {
        updateUI()
    }
    
    @IBAction func passwordEditingChanged(_ sender: Any) {
        updateUI()
    }

    // MARK: <UITextFieldDelegate>
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let newValue = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)

        switch textField {
        case ssidTextField: return newValue.isValidSSID
        case passwordTextField: return (0...63).contains(newValue.count)
        default: return true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
            
        case ssidTextField:
            passwordTextField.becomeFirstResponder()
            
        case passwordTextField:
            passwordTextField.resignFirstResponder()
            attemptAssociation()
            
        default: break
            
        }
        
        return false
    }
    
    // MARK: Delegate
    
    @IBOutlet weak var delegate: AferoWifiPasswordPromptDelegate?
    
    /// Attempt association with the currently-configured network.
    private func attemptAssociation() {
        
        guard let delegate = delegate else {
            print("No delegate, not attempting association.")
            return
        }
        
        guard let ssid = ssidTextField.text else {
            print("No SSID, not attempting association.")
            return
        }
        
        delegate.wifiPasswordPromptView(self, attemptAssociateWith: ssid, usingPassword: passwordTextField?.text) {
            
            [weak self] wifiState in
            asyncMain {
                self?.wifiStateLabel?.text = wifiState.localizedDescription
            }
        }
    }
    
    /// Cancel any pending association attempt.
    private func cancelConnectionAttempt() {

        guard let delegate = delegate else {
            print("No delegate, not attempting cancel association.")
            return
        }
        delegate.cancelAttemptAssociation(for: self)

    }
    
}

extension String {
    
    /// Whether or not this string can be used as an SSID. Technically SSIDs are
    /// 32-element byte arrays, so we need to ensure that (a) the string encodes
    /// and (b) the resulting byte array is between 0 and 32 bytes long.
    
    var isValidSSID: Bool {
        guard let count = self.data(using: .utf8)?.count else { return false }
        return (0...32).contains(count)
    }
    
    /// Whether or not this string is a valid WPA2 password (between 8 an 63 bytes long).
    
    var isValidWPA2Password: Bool {
        return (8...63).contains(self.data(using: .ascii)?.count ?? 0)
    }
    
}
