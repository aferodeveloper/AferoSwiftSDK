//
//  ServiceSelectionView.swift
//  Bubba
//
//  Created by Justin Middleton on 2/14/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import Afero

@objc protocol ServiceSelectionViewDelegate: class {

    @objc func numberOfServices(for selectionView: ServiceSelectionView) -> Int
    @objc func titleForService(at index: Int, in selectionView: ServiceSelectionView) -> String
    
    @objc optional func selectedIndexChanged(to index: Int, in selectionView: ServiceSelectionView)
    @objc optional func nextTapped(in selectionView: ServiceSelectionView)
    
}

@objcMembers class ServiceSelectionView: XibBasedView, UIPickerViewDelegate, UIPickerViewDataSource , ServiceSelectionViewDelegate{
    
    override var xibName: String { return "ServiceSelectorView" }
    
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var servicePickerView: UIPickerView!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var delegate: ServiceSelectionViewDelegate!
    
    // MARK: Intervace Builder Preview
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        delegate = self
    }
    
    private var previewServices: [String] = [
        "Production",
        "Development",
    ]
    
    func numberOfServices(for selectionView: ServiceSelectionView) -> Int {
        return previewServices.count
    }
    
    func titleForService(at index: Int, in selectionView: ServiceSelectionView) -> String {
        return previewServices[index]
    }
    
    // MARK: UIPickerViewDelegate
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return delegate?.numberOfServices(for: self) ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return delegate?.titleForService(at: row, in: self)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        delegate?.selectedIndexChanged?(to: row, in: self)
    }
    
    // MARK: Actions
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        delegate?.nextTapped?(in: self)
    }
    
}

