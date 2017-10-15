//
//  GenericAttributeEditorViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 10/10/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import Afero
import ReactiveSwift
import CocoaLumberjack

class BaseAttributeInspectorViewController: UIViewController, DeviceModelableObserving, AttributeEventObserving {

    // MARK: - UI Management -
    @IBOutlet weak var bodyView: UIView!
    
    @IBOutlet var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var attributeIdLabel: AferoAttributeUILabel!
    @IBOutlet weak var attributeNameLabel: AferoAttributeUILabel!
    
    @IBOutlet weak var dataTypeHeaderLabel: UILabel!
    @IBOutlet weak var dataTypeValueLabel: AferoAttributeUILabel!
    
    @IBOutlet weak var lastUpdatedHeaderLabel: UILabel!
    @IBOutlet weak var lastUpdatedValueLabel: AferoAttributeUILabel!
    
    @IBOutlet weak var attributeValueHeaderLabel: UILabel!
    
    // MARK: Lifecycle
    
    typealias Observing = AttributeEventObserving & DeviceModelableObserving
 
    @IBOutlet var allObservers: [UIView] = []
    
    func configureObservers() {
        allObservers.forEach {
            {
                maybeObserving in
                maybeObserving?.attributeEventSignaling = deviceModelable
                maybeObserving?.attributeId = attributeId
                maybeObserving?.startObservingAttributeEvents()
                maybeObserving?.startObservingDeviceEvents()
            }($0 as? Observing)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureObservers()
        updateUI()
    }
    
    deinit { stopObservingDeviceEvents() }
    
    // MARK: Navigation
    
    func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    @IBAction func backgroundTapped(_ sender: Any) {
        close()
    }
    
    var attributeId: Int? {
        didSet { updateUI() }
    }
    
    // MARK: UI Updates
    
    func updateUI() { }
    
    func updateTextValues() { }
    
    // MARK: <DeviceModelableObserving>
    
    weak var deviceModelable: DeviceModelable! {
        didSet {
            startObservingDeviceEvents()
            configureObservers()
            updateUI()
        }
    }
    
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceDeletedEvent() {
        close()
    }
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        updateUI()
    }
    
    // MARK: <AttributeEventObserving>
    
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        // nothing
    }
}

class TextViewAttributeInspectorViewController: BaseAttributeInspectorViewController, UITextViewDelegate {
    
    @IBOutlet weak var attributeStringValueTextView: AferoAttributeUITextView!
    @IBOutlet weak var attributeValueTextViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attributeStringValueTextView.delegate = self
        attributeStringValueTextView.textContainer.lineFragmentPadding = 0
        attributeStringValueTextView.textContainerInset = .zero
        updateUI()
    }
    
    override func updateTextValues() {
        super.updateTextValues()
        updateTextViewHeightConstraint()
    }
    
    func updateTextViewHeightConstraint() {
        guard let tv = attributeStringValueTextView else { return }
        let newSize = tv.sizeThatFits(
            CGSize(width: tv.frame.size.width, height: .infinity)
        )
        attributeValueTextViewHeightConstraint?.constant = newSize.height
        bodyView.invalidateIntrinsicContentSize()
        view.invalidateIntrinsicContentSize()
        view.setNeedsLayout()
    }
    
    // MARK: <UITextViewDelegate>
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // todo
        return false
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // todo
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // todo
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        // todo
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        // todo
        return false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // todo
    }

    // MARK: Actions
    
    
}

class TextFieldAttributeInspectorViewController: BaseAttributeInspectorViewController, UITextFieldDelegate {
    @IBOutlet weak var attributeValueTextField: AferoAttributeUITextField!
    @IBOutlet weak var attributeDisplayLabelValueLabel: AferoAttributeUILabel!
}

/// Provides an inspector for attributes whose values can can be within a ceiling
/// and a floor.

class SliderAttributeInspectorViewController: TextFieldAttributeInspectorViewController {
    @IBOutlet weak var attributeValueSlider: AferoAttributeUISlider!
}

/// Provides an inspector for attributes whose values can take one of two values,
/// which can be interpreted as "on" or "off".

class SwitchAttributeInspectorViewController: TextFieldAttributeInspectorViewController {
    @IBOutlet weak var attributeValueSwitch: AferoAttributeUISwitch!
}

/// Provides an inspector for attributes whose values an take on an enumeration
/// of values. Values are presented in a `UIPickerView`, based upon the attribute's
/// `valueOptions` definition.

class PickerAttributeInspectorViewController: TextFieldAttributeInspectorViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var attributeValuePickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attributeValuePickerView.delegate = self
    }
    
    override func updateTextValues() {
        super.updateTextValues()
        updatePickerViewSelectedRow()
    }
    
    func updatePickerViewSelectedRow() {
        
    }
    
    // MARK: <UIPickerViewDataSource>

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // todo
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // todo
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // todo
        return nil
    }
    
    // MARK: <UdIPickerViewDelegate>
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // todo
    }
}


