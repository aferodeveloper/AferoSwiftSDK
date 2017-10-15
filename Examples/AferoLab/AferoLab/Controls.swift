//
//  Controls.swift
//  AferoLab
//
//  Created by Justin Middleton on 10/13/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import Afero
import ReactiveSwift
import CocoaLumberjack

enum AferoAttributeTextSource: String {

    case attributeId = "attributeId"
    case attributeName = "attributeName"
    case attributeType = "attributeType"
    case attributeValue = "attributeValue"
    case attributeLabel = "attributeLabel"
    case attributeLastUpdated = "attributeLastUpdated"
    
}

protocol AferoAttributeTextProducing {
    var attributeTextSource: AferoAttributeTextSource { get }
    func text(for attribute: DeviceModelable.Attribute) -> String?
}

extension AferoAttributeTextProducing where Self: AttributeEventObserving {
    
    func text(for attribute: DeviceModelable.Attribute) -> String? {
        switch attributeTextSource {
        case .attributeId: return attributeIdStringValue
        case .attributeName: return attributeNameStringValue
        case .attributeType: return attributeTypeStringValue
        case .attributeValue: return attributeValueStringValue
        case .attributeLabel: return attributeLabelDisplayValue
        case .attributeLastUpdated: return attributeLastUpdatedStringValue
        }
    }

}

@IBDesignable class AferoAttributeUILabel: UILabel, DeviceModelableObserving, AttributeEventObserving, AferoAttributeTextProducing {
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }
    
    // MARK: <AferoAttributeTextProducing>

    var attributeTextSource: AferoAttributeTextSource = .attributeValue

    @IBInspectable var attributeTextSourceName: String {
        
        get {
            return attributeTextSource.rawValue
        }
        
        set {
            guard let source = AferoAttributeTextSource(rawValue: newValue) else {
                fatalError("Unknown text source name: \(newValue)")
            }
            guard source != attributeTextSource else {
                return
            }
            attributeTextSource = source
        }
    }
    
    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        isEnabled = newState.isAvailable
    }

    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        guard let attribute = attribute else { return }
        self.text = text(for: attribute)
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        
        guard let text = text(for: attribute), self.text != text else {
            return
        }
        
        UIView.transition(
            with: self,
            duration: 0.25,
            options: .transitionFlipFromTop,
            animations: {
                self.text = text
        },
            completion: nil
        )

    }

}

@IBDesignable class AferoAttributeUITextView: UITextView, DeviceModelableObserving, AttributeEventObserving, AferoAttributeTextProducing {

    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }

    // MARK: <AferoAttributeTextProducing>
    var attributeTextSource: AferoAttributeTextSource = .attributeValue
    @IBInspectable var attributeTextSourceName: String {
        
        get {
            return attributeTextSource.rawValue
        }
        
        set {
            guard let source = AferoAttributeTextSource(rawValue: newValue) else {
                fatalError("Unknown text source name: \(newValue)")
            }
            guard source != attributeTextSource else {
                return
            }
            attributeTextSource = source
        }
    }

    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?

    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        isEditable = newState.isAvailable
    }
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        guard let attribute = attribute else { return }
        self.text = text(for: attribute)
    }

    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        
        if isFirstResponder { return }
        
        let newValue = attributeValueStringValue
        
        guard self.text != newValue else {
            return
        }
        
        UIView.transition(
            with: self,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                self.text = newValue
            },
            completion: nil
        )
        
    }
    
}

// MARK: - AferoAttributeUITextView -

@IBDesignable class AferoAttributeUITextField: UITextField, DeviceModelableObserving, AttributeEventObserving, UITextFieldDelegate {
    
    @IBInspectable var standardTextColor: UIColor = .black
    @IBInspectable var invalidValueTextColor: UIColor = .red
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        delegate = self
        addTarget(
            self,
            action: #selector(textFieldEditingChanged(sender:)),
            for: .editingChanged
        )
    }
    
    func updateUI() {
        if isFirstResponder { return }
        
        isEnabled = deviceModelable?.isAvailable ?? false
        
        let newValue = attributeValueStringValue
        
        guard text != newValue else {
            return
        }

        UIView.transition(
            with: self,
            duration: 0.25,
            options: .transitionFlipFromTop,
            animations: {
                self.text = newValue
                self.textColor = self.standardTextColor
        },
            completion: nil
        )

    }
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
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
            updateUI()
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

    @objc func textFieldEditingChanged(sender: UITextField) {
        guard let _ = attributeValue(for: sender.text) else {
            sender.textColor = invalidValueTextColor
            return
        }
        sender.textColor = standardTextColor
    }

    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?

    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        updateUI()
    }
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        self.text = attributeValueStringValue
    }

    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        updateUI()
    }

}

// MARK: - AferoAttributeUISwitch -

class AferoAttributeUISwitch: UISwitch, DeviceModelableObserving, AttributeEventObserving {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }

    func configure() {
        addTarget(self, action: #selector(valueChangedInteractively(sender:)), for: .valueChanged)
    }
    
    @objc func valueChangedInteractively(sender: UISwitch) {

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
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }

    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        isEnabled = newState.isAvailable
    }
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?

    func initializeAttributeObservation() {
        guard let attribute = attribute else {
            self.isOn = false
            self.isEnabled = false
            return
        }
        isOn = attribute.value.boolValue
        isEnabled = true
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        guard isOn != attribute.value.boolValue else { return }
        isOn = attribute.value.boolValue
    }

}

// MARK: - AferoAttributeUISlider

/// A UISlider bound to an Afero device and attribute.

class AferoAttributeUISlider: UISlider, DeviceModelableObserving, AttributeEventObserving {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        addTarget(self, action: #selector(valueChangedInteractively(sender:)), for: .valueChanged)
        isContinuous = false
    }
    
    @objc func valueChangedInteractively(sender: UISlider) {
        
        let TAG = self.TAG
        
        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else {
                DDLogWarn("No deviceModel or attribute configured; bailing.", tag: TAG)
                return
        }

        guard let rangeSubscriptor = attributeRangeSubscriptor else {
            DDLogWarn("No rangeOptions for \(deviceModelable.deviceId).\(attributeId); bailing.", tag: TAG)
            return
        }
        
        guard let idx = rangeSubscriptor.indexOf(value) else {
            DDLogError("No quantized range index for \(value) in \(String(reflecting: attributeRangeOptions)); bailing.", tag: TAG)
            return
        }
        
        guard let newValue = rangeSubscriptor[idx] else {
            return
        }
        
        let deviceId = deviceModelable.deviceId
        
        deviceModelable.set(value: newValue, forAttributeId: attributeId).then {
            newValue -> Void in
            DDLogVerbose("Successfully set \(deviceId).\(attributeId) to \(String(reflecting: newValue))", tag: TAG)
            }.catch {
                error in
                DDLogError("Unable to set \(deviceId).\(attributeId) to \(String(reflecting: newValue)): \(String(reflecting: error))", tag: TAG)
        }

    }
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }

    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?

    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        isEnabled = newState.isAvailable
    }
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        guard let attribute = attribute else {
            params = (0, 1.0, 0)
            isEnabled = false
            return
        }
        params = sliderParams(for: attribute)
        isEnabled = true
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        if isTracking { return }
        params = sliderParams(for: attribute)
    }
    
    typealias SliderParams = (min: Float, max: Float, value: Float)

    var params: SliderParams {
        get { return (minimumValue, maximumValue, value) }
        set {
            minimumValue = newValue.min
            maximumValue = newValue.max
            setValue(newValue.value, animated: true)
        }
    }

    func sliderParams(for attribute: DeviceModelable.Attribute) -> SliderParams {

        let floatValue = attribute.value.floatValue ?? 0.0
        
        var min = floatValue < 0.0 ? floatValue : 0.0
        var max = floatValue > 0.0 ? floatValue : 0.0
        
        if
            let rangeOptions = attribute.config.presentation?.rangeOptions,
            let maybeMin = rangeOptions.min.floatValue,
            let maybeMax = rangeOptions.max.floatValue {
            min = maybeMin
            max = maybeMax
        }
        
        return (min: min, max: max, value: floatValue)
    }
    
}

// MARK: - AferoAttributeUIPickerView -

class AferoAttributeUIPickerView: UIPickerView, DeviceModelableObserving, AttributeEventObserving, UIPickerViewDelegate, UIPickerViewDataSource {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        delegate = self
        dataSource = self
        reloadAllComponents()
        updateUI()
    }
    
    func updateUI() {
        
        guard let attribute = attribute else {
            return
        }
        
        guard let index = attribute.config.presentation?.valueOptions.index(where: {
            valueOption in return valueOption.match == attribute.value.stringValue
        }) else {
            DDLogError("Unrecognized value for picker (== \(String(describing: attribute)); bailing.", tag: TAG)
            return
        }
        
        selectRow(index, inComponent: 0, animated: true)
    }
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }
    
    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        updateUI()
    }
    
    func handleDeviceProfileUpdateEvent() {
        configure()
    }
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        configure()
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        updateUI()
    }

    // MARK: <UIPickerViewDataSource>
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        // todo
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return attributeValueOptions?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let valueOptions = attributeValueOptions else { return nil }
        
        var label = "-"
        if let maybeLabel = valueOptions[row].apply["label"] as? String { label = maybeLabel }
        
        let value = valueOptions[row].match
        
        return "\(label) (\(value))"
    }
    
    // MARK: <UdIPickerViewDelegate>
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        let TAG = self.TAG
        
        guard let deviceModelable = deviceModelable, let attributeId = attributeId else {
            DDLogWarn("No device or attribute to update; bailing.", tag: TAG)
            return
        }
        
        guard let valueOptions = attributeValueOptions else {
            // We should never get here, since we need valueOptions to
            // create our rows
            fatalError("No valueOptions present.")
        }
        
        guard let newValue = attributeValue(for: valueOptions[row].match) else {
            DDLogError("Unable to create attributeValue for \(valueOptions[row].match); bailing.", tag: TAG)
            return
        }
        
        let deviceId = deviceModelable.deviceId
        
        deviceModelable.set(value: newValue, forAttributeId: attributeId).then {
            newValue -> Void in
            DDLogVerbose("Successfully set \(deviceId).\(attributeId) to \(String(reflecting: newValue))", tag: TAG)
            }.catch {
                error in
                self.updateUI()
                DDLogError("Unable to set \(deviceId).\(attributeId) to \(String(reflecting: newValue)): \(String(reflecting: error))", tag: TAG)
        }

    }

}
