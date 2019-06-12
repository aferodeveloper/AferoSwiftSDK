//
//  ResetPasswordWithCodeViewController.swift
//  AferoLab
//
//  Created by Cora Middleton on 6/11/19.
//  Copyright © 2019 Afero, Inc. All rights reserved.
//

import UIKit
import Afero
import OnePasswordExtension

class ResetPasswordWithCodeViewController: UIViewController {
    
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
        onePasswordButton.isHidden = !OnePasswordExtension.shared().isAppExtensionAvailable()
    }
    
    
}
