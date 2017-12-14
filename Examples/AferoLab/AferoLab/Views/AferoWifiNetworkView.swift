//
//  AferoWifiNetworkView.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/11/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import AferoSofthub
import Afero

protocol WifiNetwork: Hashable {
    var ssid: String { get }
    var rssi: Int { get }
    var rssiBars: Int { get }
    var isSecure: Bool { get }
    var isConnected: Bool { get }
}

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
    
    var rssiBars: AferoWifiRSSIView.RSSIBars {
        return rssiView?.rssiBars ?? .zero
    }
    
    @IBInspectable var rssiBarCount: Int {
        get { return rssiView?.rssiBarCount ?? 0 }
        set { rssiView?.rssiBarCount = newValue }
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
    
    @IBOutlet weak var connectionStateImageView: UIImageView!
    
    @IBInspectable var connectionStateIsHidden: Bool {
        get { return connectionStateImageView?.isHidden ?? true }
        set { connectionStateImageView?.isHidden = newValue}
    }
    
    var connectionState: AferoSofthubWifiState = .notConnected {
        didSet { updateUI() }
    }
    
    @IBInspectable var isConnected: Bool {
        get { return connectionState == .connected }
        set { connectionState = newValue ? .connected : .notConnected }
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
        connectionStateImageView.image = connectionState.iconImage(in: Bundle(for: type(of: self)))
    }
    
}

extension AferoWifiNetworkView {
    
    func configure<T: WifiNetwork>(with network: T) {
            rssi = network.rssi
            rssiBarCount = network.rssiBars
            ssid = network.ssid
            isSecure = network.isSecure
            isConnected = network.isConnected
    }
    
}


@IBDesignable @objcMembers class StackViewContentTableViewCell: UITableViewCell {
    
    private(set) var contentStackView: UIStackView!
    
    @IBInspectable var contentSpacing: CGFloat {
        get { return contentStackView?.spacing ?? 0 }
        set { contentStackView?.spacing = newValue }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        
        contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStackView)
        setupConstraints()
    }
    
    func setupConstraints() {
        
        let views: [String: Any] = [ "v": contentStackView ]
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

}

/// A `UITableViewCell` whose content is an `AferoWifiNetworkView`

@IBDesignable @objcMembers class AferoWifiNetworkTableViewCell: StackViewContentTableViewCell {
    
    fileprivate var wifiNetworkView: AferoWifiNetworkView!
    
    override func commonInit() {
        
        super.commonInit()
        
        wifiNetworkView = AferoWifiNetworkView(frame: contentView.bounds)
        wifiNetworkView.translatesAutoresizingMaskIntoConstraints = false
        wifiNetworkView.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentStackView.addArrangedSubview(wifiNetworkView)
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
    
    @IBInspectable var rssi: Int {
        get { return wifiNetworkView?.rssi ?? 0 }
        set { wifiNetworkView?.rssi = newValue }
    }
    
    @IBInspectable var rssiBarCount: Int {
        get { return wifiNetworkView?.rssiBarCount ?? 0 }
        set { wifiNetworkView?.rssiBarCount = newValue }
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
    
    @IBInspectable var useSmallNetworkStatusIcon: Bool {
        get { return wifiNetworkView?.useSmallIcon ?? true }
        set { wifiNetworkView?.useSmallIcon = newValue }
    }
    
    @IBInspectable var ssid: String? {
        get { return wifiNetworkView?.ssidLabel?.text }
        set { wifiNetworkView?.ssidLabel?.text = newValue }
    }
    
    @IBInspectable var connectionStateIsHidden: Bool {
        get { return wifiNetworkView?.connectionStateIsHidden ?? true }
        set { wifiNetworkView?.connectionStateIsHidden = newValue}
    }

    @IBInspectable var isConnected: Bool {
        get { return wifiNetworkView?.isConnected ?? false }
        set { wifiNetworkView?.isConnected = newValue }
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


extension AferoWifiNetworkTableViewCell {

    func configure<T: WifiNetwork>(with network: T) {
        wifiNetworkView.configure(with: network)
    }

}

@IBDesignable @objcMembers class AferoAssociatingWifiNetworkTableViewCell: AferoWifiNetworkTableViewCell {
    
    var passwordPromptView: AferoWifiPasswordPromptView!
    
    override func commonInit() {
        super.commonInit()
        passwordPromptView = AferoWifiPasswordPromptView()
        contentStackView.addArrangedSubview(passwordPromptView)
        passwordPromptView.isHidden = true
        passwordPromptView.ssidIsHidden = true
    }

    @IBInspectable var validTextColor: UIColor {
        get { return passwordPromptView.validTextColor }
        set { passwordPromptView.validTextColor = newValue }
    }
    
    @IBInspectable var invalidTextColor: UIColor {
        get { return passwordPromptView.invalidTextColor }
        set { passwordPromptView.invalidTextColor = newValue }
    }
    
    @IBInspectable override var ssid: String? {
        get { return super.ssid }
        
        set {
            super.ssid = newValue
            updateUI()
        }
    }
    
    func updateUI() {
        passwordPromptView.ssid = ssid
    }
    
    @IBInspectable var ssidIsHidden: Bool {
        get { return passwordPromptView.ssidIsHidden }
        set { passwordPromptView.ssidIsHidden = newValue }
    }

    @IBInspectable var password: String? {
        get { return passwordPromptView.password }
        set { passwordPromptView.password = newValue }
    }
    
    @IBInspectable var passwordIsHidden: Bool {
        get { return passwordPromptView.passwordIsHidden }
        set { passwordPromptView.passwordIsHidden = newValue }
    }
    
    @IBInspectable var passwordIsEnabled: Bool {
        get { return passwordPromptView.passwordIsEnabled }
        set { passwordPromptView.passwordIsEnabled = newValue }
    }
    
    @IBInspectable var passworPromptStatusIsHidden: Bool {
        get { return passwordPromptView.statusIsHidden }
        set { passwordPromptView.statusIsHidden = newValue }
    }
    
    @IBInspectable var passwordPromptIsHidden: Bool {
        get { return passwordPromptView?.isHidden ?? true }
        set { passwordPromptView?.isHidden = newValue }
    }
    
    @IBOutlet weak var passwordPromptDelegate: AferoWifiPasswordPromptDelegate? {
        get { return passwordPromptView?.delegate }
        set { passwordPromptView.delegate = newValue }
    }
    
}

@IBDesignable @objcMembers class AferoCustomSSIDAssociatingWifiNetworkTableViewCell: StackViewContentTableViewCell {
    
    var titleLabel: UILabel!
    
    var passwordPromptView: AferoWifiPasswordPromptView!
    
    override func commonInit() {

        super.commonInit()
        
        titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        contentStackView.addArrangedSubview(titleLabel)
        
        passwordPromptView = AferoWifiPasswordPromptView()
        contentStackView.addArrangedSubview(passwordPromptView)
    }
    
    @IBInspectable var titleText: String? {
        get { return titleLabel?.text }
        set { titleLabel?.text = newValue }
    }
    
    @IBInspectable var validTextColor: UIColor {
        get { return passwordPromptView.validTextColor }
        set { passwordPromptView.validTextColor = newValue }
    }
    
    @IBInspectable var invalidTextColor: UIColor {
        get { return passwordPromptView.invalidTextColor }
        set { passwordPromptView.invalidTextColor = newValue }
    }
    
    @IBInspectable var ssid: String? {
        get { return passwordPromptView.ssid }
        set { passwordPromptView.ssid = newValue }
    }
    
    @IBInspectable var ssidIsHidden: Bool {
        get { return passwordPromptView.ssidIsHidden }
        set { passwordPromptView.ssidIsHidden = newValue }
    }
    
    @IBInspectable var password: String? {
        get { return passwordPromptView.password }
        set { passwordPromptView.password = newValue }
    }
    
    @IBInspectable var passwordIsHidden: Bool {
        get { return passwordPromptView.passwordIsHidden }
        set { passwordPromptView.passwordIsHidden = newValue }
    }
    
    @IBInspectable var passwordIsEnabled: Bool {
        get { return passwordPromptView.passwordIsEnabled }
        set { passwordPromptView.passwordIsEnabled = newValue }
    }
    
    @IBInspectable var statusIsHidden: Bool {
        get { return passwordPromptView.statusIsHidden }
        set { passwordPromptView.statusIsHidden = newValue }
    }
    
    @IBInspectable var passwordPromptIsHidden: Bool {
        get { return passwordPromptView?.isHidden ?? true }
        set { passwordPromptView?.isHidden = newValue }
    }
    
    @IBOutlet weak var passwordPromptDelegate: AferoWifiPasswordPromptDelegate? {
        get { return passwordPromptView?.delegate }
        set { passwordPromptView.delegate = newValue }
    }
    
}


extension WifiSetupManaging.WifiState {
    
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
    
    public var iconName: String? {
        
        switch self {
        case .pending: return "PendingSmall"
        case .connected: return "CheckmarkSmall"
        case .notConnected: return nil
        default: return "ErrorSmall"
        }
        
    }
    
    func iconImage(in bundle: Bundle? = nil, compatibleWith traitCollection: UITraitCollection? = nil) -> UIImage? {
        guard let name = iconName else { return nil }
        return UIImage(named: name, in: bundle, compatibleWith: traitCollection)
    }


}
