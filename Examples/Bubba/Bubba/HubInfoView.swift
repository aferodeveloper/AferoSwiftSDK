//
//  HubInfoView.swift
//  Bubba
//
//  Created by Justin Middleton on 2/13/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit

fileprivate extension Optional where Wrapped: Collection {
    
    var isEmpty: Bool {
        return self?.isEmpty ?? true
    }
    
}

@objc protocol HubControlViewDelegate: class {
    
    /// The user has indicated that the hub should or should not be enabled.
    func hubEnabledValueChanged(to enabled: Bool, for hubControlView: HubControlView)
    
    func hubResetRequested(for hubControlView: HubControlView)
    
}

@IBDesignable class HubControlView: XibBasedView {
    
    @IBOutlet weak var delegate: HubControlViewDelegate!
    
    override var xibName: String { return "HubControlView" }
    
    @IBOutlet private weak var deviceIdContainer: UIStackView!
    @IBOutlet private weak var deviceIdTitleLabel: UILabel!
    @IBOutlet private weak var deviceIdValueLabel: UILabel!
    
    @IBOutlet private weak var statusContainer: UIStackView!
    @IBOutlet private weak var statusTitleLabel: UILabel!
    @IBOutlet private weak var statusValueLabel: UILabel!
    
    @IBOutlet weak var completionReasonContainer: UIStackView!
    @IBOutlet private weak var completionReasonTitleLabel: UILabel!
    @IBOutlet private weak var completionReasonValueLabel: UILabel!
    
    @IBOutlet weak var messageContainer: UIStackView!
    @IBOutlet private weak var messageTitleLabel: UILabel!
    @IBOutlet private weak var messageValueLable: UILabel!
    
    @IBOutlet weak var enabledSwitchContainer: UIStackView!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet private weak var enabledTitleLabel: UILabel!
    @IBOutlet private weak var enabledSwitch: UISwitch!
    private var enabledSwitchObs: NSKeyValueObservation?
    
    @IBOutlet private var emptyableLabels: [UILabel]!
    private var emptyableLabelObs: [NSKeyValueObservation] = []
    
    override func initializeView() {
        super.initializeView()

        emptyableLabelObs = emptyableLabels.map {
            $0.observe(\.text, options: [.initial]) {
                obj, chg in
                obj.superview?.isHidden = obj.text.isEmpty
            }
        }
        
    }
    
    // MARK: Properties
    
    /// The text to show in the Device ID value label.
    @IBInspectable var deviceId: String? {
        get { return deviceIdValueLabel?.text }
        set { deviceIdValueLabel?.text = newValue }
    }
    
    /// The text to show in the Status label.
    @IBInspectable var status: String? {
        get { return statusValueLabel?.text }
        set { statusValueLabel?.text = newValue }
    }

    /// The completion reason text, if any, to show
    @IBInspectable var completionReason: String? {
        get { return completionReasonValueLabel?.text }
        set { completionReasonValueLabel?.text = newValue }
    }
    
    /// Any additional message to show
    @IBInspectable var message: String? {
        get { return messageValueLable?.text }
        set { messageValueLable?.text = newValue }
    }
    
    @IBAction func enabledValueChanged(_ sender: Any) {
        delegate?.hubEnabledValueChanged(to: enabledSwitch.isOn, for: self)
    }
    
    @IBAction func resetTapped(_ sender: Any) {
        delegate?.hubResetRequested(for: self)
    }
}


