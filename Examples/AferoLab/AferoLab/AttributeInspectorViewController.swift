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
 
    /// A collection of references to views which will be configured
    /// for attribute/devie observing when `configureObservers()` is called.
    
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
    
    // MARK: <DeviceModelableObserving>
    
    weak var deviceModelable: DeviceModelable! {
        didSet {
            startObservingDeviceEvents()
            configureObservers()
        }
    }
    
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceDeletedEvent() {
        close()
    }
    
    // MARK: <AttributeEventObserving>
    
    var attributeId: Int? {
        didSet {
            configureObservers()
        }
    }
    
    var attributeEventDisposable: Disposable?
    
}

class TextViewAttributeInspectorViewController: BaseAttributeInspectorViewController, UITextViewDelegate {
    
    @IBOutlet weak var attributeStringValueTextView: AferoAttributeUITextView!
    @IBOutlet weak var attributeValueTextViewHeightConstraint: NSLayoutConstraint!
    
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

class PickerAttributeInspectorViewController: TextFieldAttributeInspectorViewController {
    
    @IBOutlet weak var attributeValuePickerView: UIPickerView!
}


