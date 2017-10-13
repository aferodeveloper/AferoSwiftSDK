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

class BaseAttributeInspectorViewController: UIViewController, DeviceModelableObserving {

    // MARK: - UI Management -
    @IBOutlet weak var bodyView: UIView!
    
    @IBOutlet var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var attributeIdLabel: UILabel!
    @IBOutlet weak var attributeNameLabel: UILabel!
    
    @IBOutlet weak var dataTypeHeaderLabel: UILabel!
    @IBOutlet weak var dataTypeValueLabel: UILabel!
    
    @IBOutlet weak var lastUpdatedHeaderLabel: UILabel!
    @IBOutlet weak var lastUpdatedValueLabel: UILabel!
    
    @IBOutlet weak var attributeValueHeaderLabel: UILabel!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
       super.viewDidLoad()
        updateAttributeDisplay()
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
    
    @IBAction func cancelTapped(_ sender: Any) {
        close()
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        close()
    }
    
    var attributeId: Int? {
        didSet { updateAttributeDisplay() }
    }
    
    // MARK: UI Updates
    
    func updateAttributeDisplay() {
        attributeIdLabel?.text = attributeIdStringValue
        attributeNameLabel?.text = attributeNameStringValue
        dataTypeValueLabel?.text = attributeTypeStringValue
        lastUpdatedValueLabel?.text = lastUpdatedStringValue
    }
    
    // MARK: <DeviceModelableObserving>
    
    var deviceModelable: DeviceModelable! {
        didSet {
            startObservingDeviceEvents()
            updateAttributeDisplay()
        }
    }
    
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceDeletedEvent() {
        close()
    }
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        updateAttributeDisplay()
    }
    
    // MARK: Convenience Accessors
    
    /// A tuple containing the attribute's data type and display
    /// information, as well as its current value
    var attribute: DeviceModelable.Attribute? {
        guard let attributeId = attributeId else { return nil }
        return deviceModelable?.attribute(for: attributeId)
    }
    
    var attributeIdStringValue: String {
        guard let attributeId = attributeId else { return "-" }
        return "\(attributeId)"
    }
    
    var attributeNameStringValue: String {
        return attribute?.config.descriptor.semanticType ?? "-"
    }
    
    var attributeTypeStringValue: String {
        return attribute?.config.descriptor.dataType.stringValue ?? "-"
    }
    
    var attributeIsWritable: Bool {
        return attribute?.config.descriptor.isWritable ?? false
    }
    
    var lastUpdatedStringValue: String {
        // TODO: Implement last updated
        return "-"
    }
    
    var attributeValueStringValue: String {
        return attribute?.value.stringValue ?? "-"
    }
    
}

class TextViewAttributeInspectorViewController: BaseAttributeInspectorViewController, UITextViewDelegate {
    
    @IBOutlet weak var attributeStringValueTextView: UITextView!
    @IBOutlet weak var attributeValueTextViewHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        attributeStringValueTextView.delegate = self
        attributeStringValueTextView.textContainer.lineFragmentPadding = 0
        attributeStringValueTextView.textContainerInset = .zero
        updateAttributeDisplay()
    }
    
    override func updateAttributeDisplay() {
        super.updateAttributeDisplay()
        attributeStringValueTextView?.text = attributeValueStringValue
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

    @IBOutlet weak var attributeValueTextField: UITextField!

    @IBOutlet weak var attributeDisplayLabelValueLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        attributeValueTextField.delegate = self
    }
    
    override func updateAttributeDisplay() {
        super.updateAttributeDisplay()
        
        guard
            let attributeValueTextField = attributeValueTextField,
            let attributeDisplayLabelValueLabel = attributeDisplayLabelValueLabel else {
                return
        }
        
        if (attributeValueTextField.text == attributeValueStringValue) &&
            (attributeDisplayLabelValueLabel.text == attributeLabelDisplayValue) {
            return
        }

        attributeValueTextField.resignFirstResponder()
        attributeValueTextField.text = attributeValueStringValue
        attributeValueTextField.textColor = .black
        attributeDisplayLabelValueLabel.text = attributeLabelDisplayValue
        
        UIView.animate(
            withDuration: 0.125,
            delay: 0.0,
            options: .curveEaseInOut,
            animations: {
                let bounceScale = CGAffineTransform(scaleX: 1.15, y: 1.15)
                attributeValueTextField.layer.setAffineTransform(bounceScale)
                attributeDisplayLabelValueLabel.layer.setAffineTransform(bounceScale)
        }) {
            completed in
            UIView.animate(
                withDuration: 0.125,
                delay: 0.0,
                options: .curveEaseOut,
                animations: {
                    attributeValueTextField.layer.setAffineTransform(.identity)
                    attributeDisplayLabelValueLabel.layer.setAffineTransform(.identity)
            },
                completion: nil)
        }
    }
    
    // MARK: Convenience Accessors
    
    var attributeLabelDisplayValue: String? {
        return attribute?.displayParams?["label"] as? String
    }
    
    var attributeRangeOptions: DeviceProfile.Presentation.AttributeOption.RangeOptions? {
        return attribute?.config.presentation?.rangeOptions
    }
    
    var attributeRangeSubscriptor: RangeOptionsSubscriptor? {
        guard let dataType = attribute?.config.descriptor.dataType else {
            return nil
        }
        return attributeRangeOptions?.subscriptor(dataType)
    }
    
    typealias ValueOption = DeviceProfile.Presentation.AttributeOption.ValueOption
    var attributeValueOptions: [ValueOption]? {
        return attribute?.config.presentation?.valueOptions
    }

    var attributeValueOptionsMap: ValueOptionsMap? {
        guard let attribute = attribute else { return nil }
        return attribute.config.presentation?.valueOptions.valueOptionsMap
    }
    
    func attributeValue(for stringValue: String?) -> AttributeValue? {
        
        guard let stringValue = stringValue else { return nil }
        
        guard let attribute = attribute else {
            return nil
        }
        
        guard let value = attribute.config.descriptor.valueForStringLiteral(stringValue) else {
            return nil
        }
        
        if let rangeOptions = attributeRangeSubscriptor {
            guard rangeOptions.steps.contains(value) else {
                return nil
            }
        }

        if let valueOptionsMap = attributeValueOptionsMap {
            guard valueOptionsMap.keys.contains(stringValue) else {
                return nil
            }
        }
        
        return value
    }
    
    // MARK: <UITextFieldDelegate>
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return attributeIsWritable
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DDLogDebug("textField did begin editing", tag: TAG)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let replacementText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)

        if let _ = attributeValue(for: replacementText) {
            textField.textColor = .black
        } else {
            DDLogDebug("'\(replacementText)' is not a valid value for \(attribute?.config.descriptor.dataType)", tag: TAG)
            textField.textColor = .red
        }
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else { return }

        guard let newValue = attributeValue(for: textField.text) else {
            updateAttributeDisplay()
            return
        }
        
        let deviceId = deviceModelable.deviceId
        let TAG = self.TAG
        
        deviceModelable.set(value: newValue, forAttributeId: attributeId)
            .then {
                value in
                DDLogInfo("Set \(attributeId) to \(String(reflecting: value)) on \(deviceId)", tag: TAG)
            }.catch {
                error in
                DDLogError("Error setting \(attributeId) to \(newValue) on \(deviceId)", tag: TAG)
        }

    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    // MARK: Actions
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        guard let _ = attributeValue(for: sender.text) else {
            sender.textColor = .red
            return
        }
        sender.textColor = .black
    }
    

}

/// Provides an inspector for attributes whose values can can be within a ceiling
/// and a floor.

class SliderAttributeInspectorViewController: TextFieldAttributeInspectorViewController {
    
    @IBOutlet weak var attributeValueSlider: UISlider!
    
    // MARK: Actions
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
    }
}


/// Provides an inspector for attributes whose values can take one of two values,
/// which can be interpreted as "on" or "off".

class SwitchAttributeInspectorViewController: TextFieldAttributeInspectorViewController {
    
    @IBOutlet weak var attributeValueSwitch: UISwitch!
    
    override func updateAttributeDisplay() {
        super.updateAttributeDisplay()
        attributeValueSwitch?.isEnabled = attributeIsWritable
        attributeValueSwitch?.isOn = attribute?.value.boolValue ?? false
    }
    
    // MARK: Actions
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        
        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else { return }
        
        let newValue = sender.isOn
        let deviceId = deviceModelable.deviceId
        let TAG = self.TAG
        
        deviceModelable.set(value: .boolean(newValue), forAttributeId: attributeId)
            .then {
                value in
                DDLogInfo("Set \(attributeId) to \(String(reflecting: value)) on \(deviceId)", tag: TAG)
            }.catch {
                error in
                DDLogError("Error setting \(attributeId) to \(newValue) on \(deviceId)", tag: TAG)
        }
    }
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
    
    override func updateAttributeDisplay() {
        super.updateAttributeDisplay()
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


