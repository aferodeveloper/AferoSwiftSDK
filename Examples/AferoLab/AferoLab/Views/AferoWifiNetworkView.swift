//
//  AferoWifiNetworkView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/11/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import AferoSofthub

@IBDesignable class AferoWifiNetworkView: XibBasedView {

    override var xibName: String { return "AferoWifiNetworkView" }
    
    @IBOutlet weak var rssiView: AferoWifiRSSIView!
    @IBInspectable var rssiIndicatorImageIsHidden: Bool {
        get { return rssiView?.indicatorImageIsHidden ?? false }
        set { rssiView?.indicatorImageIsHidden = newValue}
    }
    
    @IBInspectable var rssiValueIsHidden: Bool {
        get { return rssiView?.valueIsHidden ?? false }
        set { rssiView?.valueIsHidden = newValue }
    }
    
    @IBInspectable var rssiValueTextColor: UIColor? {
        get { return rssiView?.valueTextColor }
        set {
            rssiView?.valueTextColor = newValue
            rssiView?.valueTextColor = newValue
        }
    }

    @IBInspectable var useSmallIcon: Bool {
        get { return rssiView?.useSmallIcon ?? true }
        set { rssiView?.useSmallIcon = newValue }
    }
    
    @IBInspectable var rssi: Int {
        get { return rssiView?.rssi ?? 0 }
        set { rssiView?.rssi = newValue }
    }
    
    var rssiToBarsConverter : AferoWifiRSSIView.RSSIToBars {
        get { return rssiView?.rssiToBarsConverter ?? { _ in return 0 } }
        set { rssiView?.rssiToBarsConverter = newValue }
    }
    
    var rssiBars: AferoWifiRSSIView.RSSIBars {
        return rssiView?.rssiBars ?? .zero
    }
    
    var securityType: AferoWifiRSSIView.WiFiSecurityType {
        get { return rssiView?.securityType ?? .open }
        set { rssiView?.securityType = newValue }
    }
    
    @IBInspectable var isSecure: Bool {
        get { return rssiView?.isSecure ?? false }
        set { rssiView?.isSecure = newValue }
    }
    
    @IBOutlet weak var ssidLabel: UILabel!
    @IBInspectable var ssid: String? {
        get { return ssidLabel?.text }
        set { ssidLabel?.text = newValue }
    }
    
    @IBOutlet weak var connectionStateLabel: UILabel!
    @IBInspectable var connectionStatusString: String? {
        get { return connectionStateLabel?.text }
        set { connectionStateLabel?.text = newValue }
    }
    
    var connectionState: AferoSofthubWifiState = .notConnected {
        didSet { updateUI() }
    }
    
    @IBInspectable var connectionStateRawValue: Int {
        get { return connectionState.rawValue }
        set {
            guard let connectionState = AferoSofthubWifiState(rawValue: newValue) else {
                assert(false, "Invalid connectionStateRawValue: \(newValue)")
                return
            }
            self.connectionState = connectionState
        }
    }
    
    func updateUI() {
        connectionStatusString = connectionState.localizedDescription
    }
    
}

/// A `UITableViewCell` whose content is an `AferoWifiNetworkView`

@IBDesignable class AferoWifiNetworkTableViewCell: UITableViewCell {
    
    private var wifiNetworkView: AferoWifiNetworkView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        guard let wifiNetworkView = aDecoder.decodeObject(forKey: "wifiNetworkView") as? AferoWifiNetworkView else {
            commonInit()
            return
        }
        self.wifiNetworkView = wifiNetworkView
    }
    
    override func encode(with aCoder: NSCoder) {
        aCoder.encode(wifiNetworkView, forKey: "wifiNetworkView")
    }
    
    func commonInit() {
        wifiNetworkView = AferoWifiNetworkView(frame: contentView.bounds)
        contentView.addSubview(wifiNetworkView)
        setupConstraints()
    }
    
    func setupConstraints() {

        wifiNetworkView.translatesAutoresizingMaskIntoConstraints = false
        // We delegate this to the content view, so we'll nuke the wifiNetworkView's margins here.
        wifiNetworkView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let views: [String: Any] = [ "v": wifiNetworkView ]
        let vfl: [String] = [ "H:|-[v]-|", "V:|-[v]-|", ]
        
        let constraints = vfl.flatMap {
            NSLayoutConstraint.constraints(
                withVisualFormat: $0,
                options: [],
                metrics: nil,
                views: views
            )
        }
        
        NSLayoutConstraint.activate(constraints)
    }

    @IBInspectable var rssiIndicatorImageIsHidden: Bool {
        get { return wifiNetworkView?.rssiIndicatorImageIsHidden ?? false }
        set { wifiNetworkView?.rssiIndicatorImageIsHidden = newValue}
    }
    
    @IBInspectable var rssiValueIsHidden: Bool {
        get { return wifiNetworkView?.rssiValueIsHidden ?? false }
        set { wifiNetworkView?.rssiValueIsHidden = newValue }
    }
    
    @IBInspectable var rssiValueTextColor: UIColor? {
        get { return wifiNetworkView?.rssiValueTextColor }
        set {
            wifiNetworkView?.rssiValueTextColor = newValue
            wifiNetworkView?.rssiValueTextColor = newValue
        }
    }
    
    @IBInspectable var useSmallIcon: Bool {
        get { return wifiNetworkView?.useSmallIcon ?? true }
        set { wifiNetworkView?.useSmallIcon = newValue }
    }
    
    @IBInspectable var rssi: Int {
        get { return wifiNetworkView?.rssi ?? 0 }
        set { wifiNetworkView?.rssi = newValue }
    }
    
    var rssiToBarsConverter : AferoWifiRSSIView.RSSIToBars {
        get { return wifiNetworkView?.rssiToBarsConverter ?? { _ in return 0 } }
        set { wifiNetworkView?.rssiToBarsConverter = newValue }
    }
    
    var rssiBars: AferoWifiRSSIView.RSSIBars {
        return wifiNetworkView?.rssiBars ?? .zero
    }
    
    var securityType: AferoWifiRSSIView.WiFiSecurityType {
        get { return wifiNetworkView?.securityType ?? .open }
        set { wifiNetworkView?.securityType = newValue }
    }
    
    @IBInspectable var isSecure: Bool {
        get { return wifiNetworkView?.isSecure ?? false }
        set { wifiNetworkView?.isSecure = newValue }
    }
    
    @IBInspectable var ssid: String? {
        get { return wifiNetworkView?.ssidLabel?.text }
        set { wifiNetworkView?.ssidLabel?.text = newValue }
    }

    @IBInspectable var connectionStatusString: String? {
        get { return wifiNetworkView?.connectionStatusString }
        set { wifiNetworkView?.connectionStatusString = newValue }
    }
    
    var connectionState: AferoSofthubWifiState {
        get { return wifiNetworkView?.connectionState ?? .notConnected }
        set { wifiNetworkView?.connectionState = newValue }
    }
    
    @IBInspectable var connectionStateRawValue: Int {
        get { return wifiNetworkView?.connectionStateRawValue ?? AferoSofthubWifiState.notConnected.rawValue }
        set { wifiNetworkView?.connectionStateRawValue = newValue }
    }

}


extension AferoSofthubWifiState {
    
    public var localizedDescription: String {
        switch self {
        case .notConnected: return NSLocalizedString("Not Connected", comment: "AferoSofthubWifiState .notConnected description")
        case .pending: return NSLocalizedString("Connection Pending", comment: "AferoSofthubWifiState .pending description")
        case .associationFailed: return NSLocalizedString("Association Failed", comment: "AferoSofthubWifiState .associationFailed description")
        case .handshakeFailed: return NSLocalizedString("Handshake Failed", comment: "AferoSofthubWifiState .handshakeFailed description")
        case .echoFailed: return NSLocalizedString("Echo Failed", comment: "AferoSofthubWifiState .echoFailed description")
        case .connected: return NSLocalizedString("Connected", comment: "AferoSofthubWifiState .connected description")
        case .ssidNotFound: return NSLocalizedString("SSID Not Found", comment: "AferoSofthubWifiState .ssidNotFound description")
        case .unknownFailure: return NSLocalizedString("Unknown Failure", comment: "AferoSofthubWifiState .unknownFailure description")
        }
    }

}
