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

class GenericAttributeEditorViewController: UIViewController, DeviceModelableObserving {

    // MARK: - UI Management -
    
    @IBOutlet weak var attributeIdLabel: UILabel!
    @IBOutlet weak var attributeNameLabel: UILabel!
    
    @IBOutlet weak var dataTypeHeaderLabel: UILabel!
    @IBOutlet weak var dataTypeValueLabel: UILabel!
    
    @IBOutlet weak var lastUpdatedHeaderLabel: UILabel!
    @IBOutlet weak var lastUpdatedValueLabel: UILabel!
    
    @IBOutlet weak var valueDataSelector: UISegmentedControl!
    @IBOutlet weak var attributeStringValueTextView: UITextView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    override func viewDidLoad() {
        attributeStringValueTextView.delegate = self
        updateAttributeDisplay()
    }
    
    deinit { stopObservingDeviceEvents() }
    
    var isEditingEnabled: Bool = false {
        didSet {
            attributeStringValueTextView.isEditable = isEditingEnabled
        }
    }
    
    func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
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
        
        var attributeIdValue = "-"
        var attributeNameValue = "-"
        var attributeTypeValue = "-"
        var attributeLastUpdatedValue = "-"
        var attributeStringValue = "-"
        var attributeDataValue = "-"
        
        if
            let attributeId = attributeId,
            let attribute = deviceModelable?.attribute(for: attributeId) {
            
            attributeIdValue = "\(attributeId)"
            attributeNameValue = attribute.config.descriptor.semanticType ?? "-"
            attributeTypeValue = attribute.config.descriptor.dataType.stringValue!
            attributeStringValue = attribute.value.stringValue ?? "-"
            attributeDataValue = attribute.value.byteArray.description
            
        }
        
        attributeIdLabel?.text = attributeIdValue
        attributeNameLabel?.text = attributeNameValue
        dataTypeValueLabel?.text = attributeTypeValue
        lastUpdatedValueLabel?.text = attributeLastUpdatedValue
        attributeStringValueTextView?.text = attributeStringValue
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
    
}

extension GenericAttributeEditorViewController: UITextViewDelegate {

}

