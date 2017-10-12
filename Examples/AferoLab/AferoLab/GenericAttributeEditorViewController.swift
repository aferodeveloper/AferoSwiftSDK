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
    @IBOutlet weak var bodyView: UIView!
    
    @IBOutlet var backgroundTapGestureRecognizer: UITapGestureRecognizer!
    
    @IBOutlet weak var attributeIdLabel: UILabel!
    @IBOutlet weak var attributeNameLabel: UILabel!
    
    @IBOutlet weak var dataTypeHeaderLabel: UILabel!
    @IBOutlet weak var dataTypeValueLabel: UILabel!
    
    @IBOutlet weak var lastUpdatedHeaderLabel: UILabel!
    @IBOutlet weak var lastUpdatedValueLabel: UILabel!
    
    @IBOutlet weak var attributeValueHeaderLabel: UILabel!
    @IBOutlet weak var attributeStringValueLabel: UILabel!
    @IBOutlet weak var attributeStringValueTextView: UITextView!
    
    @IBOutlet weak var attributeValueTextViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
       super.viewDidLoad()
        attributeStringValueTextView.delegate = self
        attributeStringValueTextView.textContainer.lineFragmentPadding = 0
        attributeStringValueTextView.textContainerInset = .zero
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
        attributeStringValueLabel?.text = attributeStringValue
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

