//
//  AferoWifiRSSIView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/8/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import Afero
import AferoSofthub
import CocoaLumberjack

@IBDesignable class AferoWifiRSSIView: XibBasedView {
    
    override var xibName: String { return "AferoWifiRSSIView" }

    @IBOutlet weak var rssiIndicatorImageView: UIImageView!
    
    @IBInspectable var indicatorImageIsHidden: Bool {
        get { return rssiIndicatorImageView.isHidden }
        set { rssiIndicatorImageView.isHidden = newValue}
    }
    
    @IBOutlet weak var labelContainer: UIView!
    @IBOutlet weak var rssiValueLabel: UILabel!
    
    @IBInspectable var valueIsHidden: Bool {
        get { return labelContainer.isHidden }
        set { labelContainer.isHidden = newValue }
    }
    
    @IBInspectable var valueTextColor: UIColor? {
        get { return rssiValueLabel.textColor }
        set {
            rssiValueLabel.textColor = newValue
            rssiUnitLabel.textColor = newValue
        }
    }
    
    @IBOutlet weak var rssiUnitLabel: UILabel!

    func updateUI() {
        rssiValueLabel.text = numberFormatter.string(from: NSNumber(value: rssi))
        rssiIndicatorImageView.image = rssiBars.wifiIndicatorImage(for: securityType, iconSize: iconSize, in: Bundle(for: type(of: self)))
    }
    
    /// The number formatter to use for displaying RSSI.
    lazy private(set) public var numberFormatter: NumberFormatter = {
        let ret = NumberFormatter()
        ret.allowsFloats = false
        return ret
    }()
    
    enum IconSize: String {
        case small = "Small"
        case large = "Large"
    }
    
    var iconSize: IconSize = .small
    
    @IBInspectable var useSmallIcon: Bool {
        get { return iconSize == .small }
        set { iconSize = newValue ? .small : .large }
    }
    
    // MARK: RSSI
    
    /// The RSSI value, in `dB`, to display.
    @IBInspectable var rssi: Int = -55 {
        didSet { updateUI() }
    }
    
    @IBInspectable var rssiBarCount: Int {
        get { return rssiBars.rawValue }
        set { rssiBars = RSSIBars(barCount: newValue) }
    }
    
    /// The `RSSIBars` case associated with the current `rssi`.
    
    var rssiBars: RSSIBars = .zero {
        didSet { updateUI() }
    }
    
    enum RSSIBars: Int {
        
        case zero = 0
        case one = 1
        case two = 2
        case three = 3
        case four = 4
        
        func wifiIndicatorImage(for securityType: WiFiSecurityType, iconSize: IconSize, in bundle: Bundle? = nil, compatibleWith traitCollection: UITraitCollection? = nil) -> UIImage {
            let name = "WiFiRSSI\(rawValue)-\(securityType.rawValue)-\(iconSize.rawValue)"
            guard let image = UIImage(named: name, in: bundle, compatibleWith: traitCollection) else {
                fatalError("No image named \(name) found in bundle.")
            }
            return image
        }
        
        init(barCount: RawValue) {
            self = RSSIBars(rawValue: ((RSSIBars.zero.rawValue)...(RSSIBars.four.rawValue)).clamp(value: barCount))!
        }
        
    }
    
    // MARK: Security Type
    
    enum WiFiSecurityType: String {
        case open = "Open"
        case secure = "Secure"
    }
    
    var securityType: WiFiSecurityType = .open {
        didSet { updateUI() }
    }
    
    @IBInspectable var isSecure: Bool {
        get { return securityType != .open }
        set { securityType = newValue ? .secure : .open }
    }
    
}
