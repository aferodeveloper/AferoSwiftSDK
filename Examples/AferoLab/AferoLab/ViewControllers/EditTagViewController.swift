//
//  EditTagViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/6/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import Afero

class EditTagViewController: UIViewController, UITextFieldDelegate {

    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = view.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        updateUI()
    }
    
    func updateUI() {
        
        guard
            let titleLabel = titleLabel,
            let valueTextField = valueTextField,
            let keyTextField = keyTextField,
            let saveButton = saveButton,
            let deleteButton = deleteButton else { return }
        
        titleLabel.text = titleText
        
        if !valueTextField.isFirstResponder {
            valueTextField.text = workingTag.value
        }
        
        if !keyTextField.isFirstResponder {
            keyTextField.text = workingTag.key
        }
        
        saveButton.setTitle(saveButtonTitle, for: .normal)
        saveButton.isEnabled = saveButtonShouldBeEnabled
        
        deleteButton.isHidden = deleteButonShouldBeHidden
    }
    
    // MARK: Model
    
    var deviceTagCollection: DeviceTagCollection!
    
    var tag: AferoDeviceTag? {
        didSet {
            resetModel()
            updateUI()
        }
    }
    
    lazy var workingTag: AferoMutableDeviceTag! = {
        return tag?.mutableCopy() as! AferoMutableDeviceTag
    }()
    
    func resetModel() {
        workingTag = tag?.mutableCopy() as! AferoMutableDeviceTag
    }
    
    // MARK: - UI
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Title
    
    @IBOutlet weak var titleLabel: UILabel!
    var titleText: String {
        if workingTag?.id == nil {
            return NSLocalizedString("Add Tag", comment: "Edit tag title label add")
        }
        return NSLocalizedString("Edit Tag", comment: "Edit tag title label update")
    }
    
    // MARK: Save Button
    
    @IBOutlet weak var saveButton: UIButton!
    var saveButtonShouldBeEnabled: Bool {
        if (valueTextField.text?.isEmpty ?? true) { return false }
        if workingTag == tag { return false }
        return true
    }
    
    var saveButtonTitle: String {
        if workingTag?.id == nil {
            return NSLocalizedString("Add", comment: "Edit tag save button title add")
        }
        return NSLocalizedString("Update", comment: "Edit tag save button title update")
    }
    
    // MARK: Delete Button
    @IBOutlet weak var deleteButton: UIButton!
    var deleteButonShouldBeHidden: Bool {
        return workingTag?.id == nil
    }
    
    // MARK: UITextFieldDelegate
    
    @IBOutlet weak var keyTextField: UITextField!
    @IBAction func keyTextChanged(_ sender: UITextField) {
        workingTag.key = keyTextField.text
        updateUI()
    }
    
    @IBOutlet weak var valueTextField: UITextField!
    @IBAction func valueTextChanged(_ sender: UITextField) {
        guard let valueText = valueTextField.text else { return }
        workingTag.value = valueText
        updateUI()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        save()
        return false
    }
    
    // MARK: Actions
    
    func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func deleteTapped(_ sender: UIButton) {
        guard let tagId = tag?.id else { return }
        activityIndicator.startAnimating()
        deviceTagCollection.deleteTag(identifiedBy: tagId) {
            [weak self] _, _ in
            print("Deleted tag with id: \(tagId)")
            self?.activityIndicator.stopAnimating()
            self?.close()
        }
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        save()
    }
    
    func save() {
        guard let workingTag = workingTag else { return }
        
        deviceTagCollection.addOrUpdate(tag: workingTag) {
            [weak self] tag, _ in
            print("Saved \(workingTag)")
            self?.activityIndicator.stopAnimating()
            self?.close()
        }
    }
    

    
}

