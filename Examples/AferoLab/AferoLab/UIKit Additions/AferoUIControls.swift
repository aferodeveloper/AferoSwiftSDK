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

/// Identfies whence an attribute-observing view will determine its text value.
///
/// * `attributeId`: The view should reflect its attribute's integer id.
///
/// * `attributeName`: The view should reflect its attribute's name.
///   > **NOTE**: `attributeName` is derived from the profile's `semanticType` value.
///
/// * `attributeType`: : The view should reflect the attriute's type.
///
/// * `attributeValue`: The view should reflect the attribute's value.
///
/// * `attributeLabel`: The view should reflect the `label` field of an attribute's
/// `valueOptions` `apply` block, for any given value.
///
/// * `attributeLastUpdated`: The view should reflect the attribute's `last updated` value.
///   > **NOTE**: `attributeLastUpdated` to be implemented; currently returns "-".

enum AferoAttributeTextSource: String {

    /// The view should reflect its attribute's integer id.
    case attributeId = "attributeId"
    
    /// The view should reflect its attribute's name.
    /// - note: name is derived from the profile's `semanticType` value.
    case attributeName = "attributeName"
    
    /// The view should reflect the attriute's type.
    case attributeType = "attributeType"
    
    /// The view should reflect the attribute's value.
    case attributeValue = "attributeValue"
    
    /// The view should reflect the `label` field of an attribute's
    /// `valueOptions` `apply` block, for any given value.
    case attributeLabel = "attributeLabel"
    
    /// The view should reflect the attribute's `last updated` value.
    /// - note: to be implemented; currently returns "-".
    case attributeLastUpdated = "attributeLastUpdated"
    
}

/// Implementors of this protocol use `attributeTextSource` to determine
/// the characteristic of their associated attribute to display.
protocol AferoAttributeTextProducing {
    
    /// The source of the attribute value to display.
    var attributeTextSource: AferoAttributeTextSource { get }
    
    /// A defaulted method for etracting a `String` value from
    /// an attribute.
    func text(for attribute: DeviceModelable.Attribute) -> String?
}

extension AferoAttributeTextProducing where Self: AttributeEventObserving {
    
    /// Returns a value for an attribute based upon the given source.
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

// MARK: - AferoAttributeUILabel -

/// A `UILabel` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance. Changes to the attribute's value are reflected in the label's text.
/// The source of the text is determined by the value of `attributeTextSource`.
///
/// # Interface Builder Note
///
/// `attributeTextSourceName` can be configured in Interface Builder by populating
/// the *Attribute Text Source Name* field in the Attributes inspector, or
/// the keypath `attributeTextSourceName` in the Identity inspector,
/// with the `rawValue` of the desired `AferoAttributeTextSource`.

@IBDesignable class AferoAttributeUILabel: UILabel, DeviceModelableObserving, AttributeEventObserving, AferoAttributeTextProducing {
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }
    
    // MARK: <AferoAttributeTextProducing>

    /// The source of the attribute value to display.
    var attributeTextSource: AferoAttributeTextSource = .attributeValue

    /// The name of the source of the attribute value to display.
    /// Reflected in IB by the `Attribute Text Source Name` field in
    /// the Attributes inspector, or the `attribtueTextSourceName`
    /// key in the Identity inspector.
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

// MARK: - AferoAttributeUITextView -

/// A `UITextView` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance. Changes to the attribute's value are reflected in the `textView.text`.
/// The source of the text is determined by the value of `attributeTextSource`.
///
/// Note that this `UITextView` is its own delegate. 
///
/// # Interface Builder Note
///
/// `attributeTextSourceName` can be configured in Interface Builder by populating
/// the *Attribute Text Source Name* field in the Attributes inspector, or
/// the keypath `attributeTextSourceName` in the Identity inspector,
/// with the `rawValue` of the desired `AferoAttributeTextSource`.

@IBDesignable class AferoAttributeUITextView: UITextView, DeviceModelableObserving, AttributeEventObserving, AferoAttributeTextProducing, UITextViewDelegate {

    /// The color to use when this text view reflects a valid value.
    @IBInspectable var standardTextColor: UIColor = .black

    /// The color to use when this text view reflects an invalid (during editing).
    @IBInspectable var invalidValueTextColor: UIColor = .red
    
    /// An `@IBInspectable` proxy value for `textContainer.lineFragmentPadding`
    @IBInspectable var lineFragmentPadding: CGFloat {
        get { return textContainer.lineFragmentPadding }
        set { textContainer.lineFragmentPadding = newValue }
    }
    
    /// An `@IBInspectable` proxy value for `textContainerInset.bottom`
    @IBInspectable public var bottomTextContainerInset: CGFloat {
        get { return textContainerInset.bottom }
        set { textContainerInset.bottom = newValue }
    }
    
    /// An `@IBInspectable` proxy value for `textContainerInset.left`
    @IBInspectable public var leftTextContainerInset: CGFloat {
        get { return textContainerInset.left }
        set { textContainerInset.left = newValue }
    }
    
    /// An `@IBInspectable` proxy value for `textContainerInset.right`
    @IBInspectable public var rightTextContainerInset: CGFloat {
        get { return textContainerInset.right }
        set { textContainerInset.right = newValue }
    }
    
    /// An `@IBInspectable` proxy value for `textContainerInset.top`
    @IBInspectable public var topTextContainerInset: CGFloat {
        get { return textContainerInset.top }
        set { textContainerInset.top = newValue }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    func configure() {
        delegate = self
    }

    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }
    
    override var intrinsicContentSize: CGSize {
        return sizeThatFits(
            CGSize(width: frame.size.width, height: .infinity)
        )
    }
    
    // MARK: <AferoAttributeTextProducing>
    
    /// The source of the attribute value to display.
    ///
    /// - note: This `textView` will will not be editable if
    ///         `attributeTextSource ≠ .attributeValue`.
    var attributeTextSource: AferoAttributeTextSource = .attributeValue
    
    /// The name of the source of the attribute value to display.
    /// Reflected in IB by the `Attribute Text Source Name` field in
    /// the Attributes inspector, or the `attribtueTextSourceName`
    /// key in the Identity inspector.
    ///
    /// - note: This `textView` will will not be editable if
    ///         `attributeTextSourceName ≠ "attributeValue"`.
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
    
    func updateUI() {
        
        if isFirstResponder { return }
        
        isEditable = shouldBeEditable
        isSelectable = shouldBeSelectable

        guard
            let attribute = attribute,
            let newValue = text(for: attribute)
            else { return }

        guard text != newValue else { return }
        
        UIView.transition(
            with: self,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                self.text = newValue
                self.textColor = self.standardTextColor
        },
            completion: nil
        )
        
        invalidateIntrinsicContentSize()
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
        updateUI()
    }

    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
       updateUI()
    }
    
    var shouldBeSelectable: Bool { return true }
    
    var shouldBeEditable: Bool {
        if attributeTextSource != .attributeValue { return false }
        if !(deviceModelable?.isAvailable ?? false) { return false }
        if !attributeIsWritable { return false }
        return true
    }
    
    // MARK: <UITextViewDelegate>
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return shouldBeEditable
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        DDLogDebug("Began editing", tag: TAG)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        guard let attribute = attribute else {
            DDLogWarn("Not replacing text, because we don't have an attribute.", tag: TAG)
            return false
        }
        guard let replacementText = (textView.text as NSString?)?.replacingCharacters(in: range, with: text) else {
            DDLogError("Unable to repace text with nil value.", tag: TAG)
            return false
        }
        
        if let _ = attributeValue(forStringValue: replacementText) {
            textView.textColor = standardTextColor
        } else {
            DDLogDebug("'\(replacementText)' is not a valid value for \(attribute.config.dataDescriptor.dataType)", tag: TAG)
            textView.textColor = invalidValueTextColor
        }
        
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        invalidateIntrinsicContentSize()
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {

        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else { return }
        
        guard let newValue = attributeValue(forStringValue: textView.text) else {
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
    
}

// MARK: - AferoAttributeUITextView -

/// A `UITextField` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance. Changes to the attribute's value are reflected in the `textField.text`.
/// The source of the text is determined by the value of `attributeTextSource`.
///
/// Note that this `UITextField` is its own delegate.

@IBDesignable class AferoAttributeUITextField: UITextField, DeviceModelableObserving, AttributeEventObserving, UITextFieldDelegate {
    
    /// The color to use when this text view reflects a valid value.
    @IBInspectable var standardTextColor: UIColor = .black
    
    /// The color to use when this text view reflects an invalid (during editing).
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
        
        isEnabled = (deviceModelable?.isAvailable ?? false) && attributeIsWritable
        
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
        
        guard let attribute = attribute else {
            DDLogWarn("Not replacing text, because we don't have an attribute.", tag: TAG)
            return false
        }
        guard let replacementText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) else {
            DDLogError("Unable to repace text with nil value.", tag: TAG)
            return false
        }

        if let _ = attributeValue(forStringValue: replacementText) {
            textField.textColor = standardTextColor
        } else {
            DDLogDebug("'\(replacementText)' is not a valid value for \(attribute.config.dataDescriptor.dataType)", tag: TAG)
            textField.textColor = invalidValueTextColor
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
        
        guard let newValue = attributeValue(forStringValue: textField.text) else {
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
        guard let _ = attributeValue(forStringValue: sender.text) else {
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

/// A `UISwitch` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance.
///
/// * Changes to the attribute's `boolValue` are reflected in the `switch.isOn`.
/// * Interactive changes to the control's state actuat the bound attribute.

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

    func updateUI() {

        isEnabled = (deviceModelable?.isAvailable ?? false) && attributeIsWritable

        guard let attribute = attribute else {
            self.isOn = false
            self.isEnabled = false
            return
        }

        guard isOn != attribute.value?.boolValue else { return }
        isOn = attribute.value?.boolValue ?? false
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
        updateUI()
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
    }

}

// MARK: - <AferoUISegmentedControl> -

class AferoAttributeUISegmentedControl: UISegmentedControl, DeviceModelableObserving, AttributeEventObserving {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    deinit {
        stopObservingDeviceEvents()
        stopObservingAttributeEvents()
    }
    
    func configure() {
        addTarget(self, action: #selector(valueChangedInteractively(sender:)), for: .valueChanged)
        reloadAllSegments()
        updateUI()
    }
    
    func updateUI() {
        
        guard let attribute = attribute else {
            return
        }
        
        isEnabled = (deviceModelable?.isAvailable ?? false) && attributeIsWritable
        
        guard let index = attributeValueOptions?.index(where: {
            valueOption in return valueOption.match == attribute.value?.stringValue
        }) else {
            DDLogError("Unrecognized value for segmentedControl (== \(String(describing: attribute)); bailing.", tag: TAG)
            return
        }
        
        selectedSegmentIndex = index
    }

    
    @objc func valueChangedInteractively(sender: UISegmentedControl) {

        let TAG = self.TAG
        
        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else {
                DDLogWarn("No deviceModel or attribute configured; bailing.", tag: TAG)
                return
        }
        
        guard let valueOptions = attributeValueOptions else {
            // We should never get here, since we need valueOptions to
            // create our rows
            fatalError("No valueOptions present.")
        }
        
        let idx = sender.selectedSegmentIndex

        guard let newValue = attributeValue(forStringValue: valueOptions[idx].match) else {
            DDLogError("Unable to create attributeValue for \(valueOptions[idx].match); bailing.", tag: TAG)
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
        reloadAllSegments()
        updateUI()
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        updateUI()
    }
    
    // MARK: UI Management
    
    func reloadAllSegments(animated: Bool = false) {
        
        guard let valueOptions = attributeValueOptions else {
            return
        }
        
        removeAllSegments()
        
        valueOptions.reversed().enumerated().forEach {
            
            if
                let imageName = $1.apply["imageName"] as? String,
                let image = UIImage(named: imageName) {
                insertSegment(with: image, at: 0, animated: animated)
                return
            }
            
            if let title = $1.apply["label"] as? String {
                insertSegment(withTitle: title, at: 0, animated: animated)
                return
            }
            
            insertSegment(withTitle: $1.match, at: 0, animated: animated)
        }
        
    }
    
}

// MARK: - AferoAttributeUIProgressView -

/// A `UIProgressView` bound to an Afero device attribute. Its `progress` is calculated
/// the attribute's value vis a vis its `rangeOptions`.

class AferoAttributeUIProgressView: UIProgressView, DeviceModelableObserving, AttributeEventObserving {

    func updateUI() {
        progress = proportion(for: attribute?.value)
    }
    
    deinit {
        stopObservingAttributeEvents()
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
        updateUI()
    }

    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        updateUI()
    }
    
    func progress(for attribute: DeviceModelable.Attribute?) -> Float? {
        return proportion(for: attribute?.value)
    }
    
}

// MARK: - AferoOTAProgressView -

@IBDesignable class AferoOTAProgressView: UIProgressView, DeviceModelableObserving {
    
    // MARK: IBInspectables
    
    @IBInspectable var hidesWhenInactive: Bool = true {
        didSet {
            guard oldValue != isOTAInProgress else { return }
            guard !isOTAInProgress else { return }
            isHidden = hidesWhenInactive
        }
    }

    // MARK: Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    deinit {
        stopObservingDeviceEvents()
    }
    
    // MARK: <NSCoding>
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        hidesWhenInactive = aDecoder.decodeBool(forKey: "hidesWhenInactive")
    }

    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(hidesWhenInactive, forKey: "hidesWhenInactive")
    }
    
    // MARK: <DeviceModelableObserving>
    var deviceModelable: DeviceModelable!
    var deviceEventSignalDisposable: Disposable?
    
    private(set) var isOTAInProgress: Bool = false {
        didSet {
            guard oldValue != isOTAInProgress else { return }
            if isOTAInProgress {
                isHidden = false
                return
            }
            isHidden = hidesWhenInactive
        }
    }
    
    func handleDeviceOtaStartEvent() {
        isHidden = false
    }
    
    func handleDeviceOtaProgressEvent(with proportion: Float) {
        progress = proportion
    }
    
    func handleDeviceOtaFinishEvent() {
        progress = 0
        isHidden = hidesWhenInactive
    }

}

// MARK: - AferoAttributeUIStepper -

class AferoAttributeUIStepper: UIStepper, DeviceModelableObserving, AttributeEventObserving {
    
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
    
    func updateUI() {
        isEnabled = (deviceModelable?.isAvailable ?? false) && attributeIsWritable
        value = attribute?.value?.doubleValue ?? 0.0
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
    
    // MARK: <AttributeEventObserving>
    var attributeId: Int?
    var attributeEventDisposable: Disposable?
    
    func initializeAttributeObservation() {
        updateUI()
    }
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        updateUI()
    }
    
    // MARK: Actions
    
    @objc func valueChangedInteractively(sender: UIStepper) {
        let TAG = self.TAG
        
        guard
            let deviceModelable = deviceModelable,
            let attributeId = attributeId else {
                DDLogWarn("No deviceModel or attribute configured; bailing.", tag: TAG)
                return
        }
        
        guard let newValue = attributeValue(forDoubleValue: value) else {
            DDLogError("Unable to derive attributeValue for \(value); bailing.", tag: TAG)
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

}

// MARK: - AferoAttributeUISlider -

/// A `UISlider` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance.
///
/// * `minimumValue`, `maximumValue` are determinded by the `attribute`'s `RangeOptions` value, if any.
/// * `value` is determined by the `attribute`'s `floatValue`, if any.
/// * Interactive changes to the slider's `value` actuate the bound attribute.

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

        let floatValue = attribute.value?.floatValue ?? 0.0
        
        var min = floatValue < 0.0 ? floatValue : 0.0
        var max = floatValue > 0.0 ? floatValue : 0.0
        
        if
            let rangeOptions = attribute.config.presentationDescriptor?.rangeOptions,
            let maybeMin = rangeOptions.minValue?.floatValue,
            let maybeMax = rangeOptions.maxValue?.floatValue {
            min = maybeMin
            max = maybeMax
        }
        
        return (min: min, max: max, value: floatValue)
    }
    
}

// MARK: - AferoAttributeUIPickerView -

/// A `UIPickerView` subclass that's bound to an attribute on an Afero `DeviceModelable`
/// instance.
///
/// * The view has a single component. Its `title` is determined by the associated
///   attribute values `ValueOption.apply["label"]`.
/// * Changes to the value are reflected in the control
/// * Interactive changes to the picker's `selectedRow` actuate the bound attribute.
///
/// - note: `AferoAttributeUIPickerView` is its own delegate.

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
        
        guard let index = attribute.config.presentationDescriptor?.valueOptions.index(where: {
            valueOption in return valueOption.match == attribute.value?.stringValue
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
        
        guard let newValue = attributeValue(forStringValue: valueOptions[row].match) else {
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
