//
//  ConfigureWifiViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/10/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit

import CocoaLumberjack
import ReactiveSwift
import Afero
import SVProgressHUD

@objc class TestWifiNetwork: NSObject, WifiNetworkProto {
    
    let ssid: String
    let rssi: Int
    let rssiBars: Int
    let isSecure: Bool
    let isConnected: Bool
    let sortId: Int = Int(arc4random())
    
    init(ssid: String, rssi: Int, rssiBars: Int, isSecure: Bool, isConnected: Bool) {
        self.ssid = ssid
        self.rssi = rssi
        self.rssiBars = rssiBars
        self.isSecure = isSecure
        self.isConnected = isConnected
    }
    
    override var hashValue: Int { return ssid.hashValue
        ^ rssi.hashValue
        ^ rssiBars.hashValue
        ^ isSecure.hashValue
        ^ isConnected.hashValue
    }
    
    override func isEqual(_ object: Any?) -> Bool {

        guard let rhs = object as? TestWifiNetwork else {
            return false
        }
        
        return self.ssid == rhs.ssid
            && self.rssi == rhs.rssi
            && self.rssiBars == self.rssiBars
            && self.isSecure == rhs.isSecure
            && self.isConnected == rhs.isConnected
            && self.sortId == rhs.sortId

    }
    
    static func ==(lhs: TestWifiNetwork, rhs: TestWifiNetwork) -> Bool {
        return lhs.ssid == rhs.ssid
            && lhs.rssi == rhs.rssi
            && lhs.rssiBars == lhs.rssiBars
            && lhs.isSecure == rhs.isSecure
            && lhs.isConnected == rhs.isConnected
            && lhs.sortId == rhs.sortId
    }
    
    static func testNetworks() -> [TestWifiNetwork] {
        return [
            TestWifiNetwork(ssid: "Test network 1", rssi: -44, rssiBars: 0, isSecure: true, isConnected: true),
            TestWifiNetwork(ssid: "Test network 2", rssi: -50, rssiBars: 0, isSecure: false, isConnected: true),
            TestWifiNetwork(ssid: "Test network 3", rssi: -55, rssiBars: 1, isSecure: true, isConnected: false),
            TestWifiNetwork(ssid: "Test network 4", rssi: -60, rssiBars: 2, isSecure: false, isConnected: true),
            TestWifiNetwork(ssid: "Test network 5", rssi: -65, rssiBars: 3, isSecure: true, isConnected: false),
            TestWifiNetwork(ssid: "Test network 6", rssi: -70, rssiBars: 4, isSecure: false, isConnected: true),
        ]
    }
    
}

@IBDesignable @objcMembers class ScanWifiTableView: UITableView {
    
    var headerStackView: UIStackView!
    
    @IBInspectable var headerSpacing: CGFloat {
        get { return headerStackView?.spacing ?? 0 }
        set { headerStackView?.spacing = newValue }
    }
    
    var headerTitleLabel: UILabel!
    @IBInspectable var headerTitle: String? {
        get { return headerTitleLabel?.text }
        set { headerTitleLabel?.text = newValue }
    }
    
    var headerBodyLabel: UILabel!
    @IBInspectable var headerBody: String? {
        get { return headerBodyLabel?.text }
        set { headerBodyLabel?.text = newValue }
    }
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style: style)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        
        let headerContainerView = UIView()
        headerContainerView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        headerContainerView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        headerStackView = UIStackView()
        headerStackView.alignment = .fill
        headerStackView.distribution = .fill
        headerStackView.axis = .vertical
        headerStackView.spacing = 8
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainerView.addSubview(headerStackView)
        
        let views: [String: Any] = [ "v": headerStackView ]
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
        
        headerTitleLabel = UILabel()
        headerTitleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        headerTitleLabel.numberOfLines = 0
        headerStackView.addArrangedSubview(headerTitleLabel)
        
        headerBodyLabel = UILabel()
        headerBodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        headerBodyLabel.numberOfLines = 0
        headerStackView.addArrangedSubview(headerBodyLabel)
        
        tableHeaderView = headerContainerView
    }
    
}

// MARK: - ScanWifiViewController -

/// A UITableViewController responsible for scanning for available wifi SSID.

class ScanWifiViewController: WifiSetupAwareTableViewController, AferoWifiPasswordPromptDelegate {
    
    // MARK: Reuse Identifiers
    
    enum TableViewHeaderFooterViewReuse {
        
        case sectionHeader
        
        var reuseClass: AnyClass {
            switch self {
            case .sectionHeader: return SectionHeaderTableViewHeaderFooterView.self
            }
        }
        
        var reuseIdentifier: String {
            switch self {
            case .sectionHeader: return "SectionHeaderTableViewHeaderFooterView"
            }
        }
        
        static var allCases: Set<TableViewHeaderFooterViewReuse> {
            return [ .sectionHeader ]
        }
        
    }
    
    enum CellReuse {
        
        case networkCell
        case customNetworkCell
        
        var reuseIdentifier: String {
            switch self {
            case .networkCell: return "WifiNetworkCell"
            case .customNetworkCell: return "CustomSSIDWifiNetworkCell"
            }
        }
        
    }

    enum Section: Int {
        
        case current = 0
        case visible
        
        var title: String {
            switch self {
            case .current: return NSLocalizedString("Current Network", comment: "ConfigureWifiViewController current network section title")
            case .visible: return NSLocalizedString("Visible Networks", comment: "ConfigureWifiViewController visible network section title")
            }
        }
        
        var caption: String? {
            switch self {
                
            case .current: return NSLocalizedString("Your device is currently configured for the following network. Swipe to remove it, or tap to reconfigure it.", comment: "ConfigureWifiViewController current network section caption")
                
            case .visible: return NSLocalizedString("The following networks are currently visible to your device. Select one to connect to it.", comment: "ConfigureWifiViewController current network section caption")
            }
            
        }
        
        var reuse: TableViewHeaderFooterViewReuse {
            return .sectionHeader
        }
        
        static var allCases: Set<Section> {
            return [.current, .visible]
        }
        
        static var count: Int { return allCases.count }
    }
    
    // MARK: Convenience Accessors
    
    var headerTitle: String? {
        get { return (tableView as! ScanWifiTableView).headerTitle }
        set { (tableView as! ScanWifiTableView).headerTitle = newValue }
    }

    var headerBody: String? {
        get { return (tableView as! ScanWifiTableView).headerBody }
        set { (tableView as! ScanWifiTableView).headerBody = newValue }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        TableViewHeaderFooterViewReuse.allCases.forEach {
            tableView.register(
                $0.reuseClass,
                forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier
            )
        }
        
        tableView.estimatedSectionHeaderHeight = 31
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 55
        tableView.rowHeight = UITableViewAutomaticDimension
        
//        scan()
//        updateUI()
//        startWifiSetupManager()
    }

    // Turn the idle timer off when we're in front, so that
    // we don't turn off the softhub.
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - Actions -
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBAction func refreshTapped(_ sender: Any) {
        scan()
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButtonTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
//    func scan() {
//        transitionToScanningState(.scanning)
//        currentNetwork = TestWifiNetwork.testNetworks().first
//        visibleNetworks = TestWifiNetwork.testNetworks().sorted { return $0.sortId < $1.sortId }
//    }
    
    
    // MARK: - General UI Updates -
    
    func updateUI() {
        updateDeviceInfo()
        tableView.reloadData()
    }
    
    func updateDeviceInfo() {
        if modelIsWifiConfigurable {
            headerBody = NSLocalizedString("This device supports Afero Cloud connections via Wi-Fi. Select a network below to connect to it.", comment: "Scan wifi model is configurable header body")
        } else {
            headerBody = NSLocalizedString("This device does not support connections via Wi-Fi", comment: "Scan wifi model is configurable header body")
        }
    }
    
    // MARK: - Model -
    
    var modelIsWifiConfigurable: Bool {
        return deviceModel?.isWifiConfigurable ?? false
    }
    
    typealias WifiNetwork = WifiSetupManaging.WifiNetwork
    typealias WifiNetworkList = WifiSetupManaging.WifiNetworkList
    
    /// The current network for which the device is connectred, if any.
    
    var currentNetwork: WifiNetwork? {
        
        didSet {
            
            guard oldValue != currentNetwork else { return }
            
            tableView.beginUpdates()
            defer { tableView.endUpdates() }
            
            let indexPaths = [IndexPath(row: 0, section: Section.current.rawValue)]
            
            if oldValue == nil && currentNetwork != nil {

                // We're adding.
                tableView.insertRows(at: indexPaths, with: .automatic)
                return
                
            } else if oldValue != nil && currentNetwork == nil {
                
                // we're deleting
                tableView.deleteRows(at: indexPaths, with: .automatic)
                return
                
            } else {
                
                // we're updating
                if oldValue?.ssid == currentNetwork?.ssid {
                    // we're just reconfiguring the existing cell
                    guard let cell = tableView.cellForRow(at: indexPaths[0]) as? AferoWifiNetworkTableViewCell else {
                        return
                    }
                    configure(cell: cell, for: indexPaths[0])
                    return
                    
                } else {
                   tableView.reloadRows(at: indexPaths, with: .automatic)
                }
            }
            
        }
    }
    
    var currentNetworkIndexPath: IndexPath? {
        guard currentNetwork != nil else { return nil }
        return IndexPath(row: 0, section: Section.current.rawValue)
    }
    
    /// Networks that have been returned from a scan operation.
    
    var visibleNetworks: WifiNetworkList = [] {
        didSet {
            let deltas = oldValue.deltasProducing(visibleNetworks)
            tableView.beginUpdates()
            tableView.deleteRows(
                at: deltas.deletions.indexes().map {
                    IndexPath(row: $0, section: Section.visible.rawValue)
                },
                with: .automatic
            )
            tableView.insertRows(at: deltas.insertions.indexes().map {
                IndexPath(row: $0, section: Section.visible.rawValue)
            }, with: .automatic)
            tableView.endUpdates()
        }
    }
    
    // ========================================================================
    // MARK: - Model Accessors
    
    fileprivate var SSIDEntries: WifiNetworkList = []
    
    /// Replace existing SSID entries with new ones, and animate.
    /// - parameter entries: The entries to set
    /// - parameter anmated: Whether or not to animate changes (defaults to `true`)
    /// - parameter completion: A block to execute upon completion of the change and any animations. Defaults to noop.
    ///
    /// - note: `completion` is a `(Bool)->Void`. In this case, the `Bool` refers to whether or not the completion
    ///         should be animated, NOT to whether or not the changes completed.
    
    fileprivate func setSSIDEntries(_ entries: WifiNetworkList) {
        
        if !(refreshControl?.isRefreshing ?? false) {
            refreshControl?.beginRefreshing()
        }
        
        SSIDEntries = entries.filter({ (entry) -> Bool in
            !entry.ssid.trimmingCharacters(in: .whitespaces).isEmpty
        })
        
        refreshControl?.endRefreshing()
        scanningState = .scanned
    }
    
    /// Translate a model index to an indexPath.
    func indexPathForSSIDEntryIndex(_ index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
    
    /// Translate a `WifiNetwork` entry into an indexPath.
    func indexPathForSSIDEntry(_ entry: WifiNetwork?) -> IndexPath? {
        guard let entry = entry else { return nil }
        guard let entryIndex = SSIDEntries.index(of: entry) else { return nil }
        return indexPathForSSIDEntryIndex(entryIndex)
    }
    
    /// Translate an `SSID` into an indexPath.
    func indexPathForSSID(_ ssid: String?) -> IndexPath? {
        guard let ssid = ssid else { return nil }
        guard let entryIndex = SSIDEntries.index(where: { (entry: WifiNetwork) -> Bool in
            return entry.ssid == ssid
        }) else { return nil }
        return indexPathForSSIDEntryIndex(entryIndex)
    }
    
    func cellForSSIDEntry(_ entry: WifiNetwork?) -> UITableViewCell? {
        guard let indexPath = indexPathForSSIDEntry(entry) else { return nil }
        return tableView.cellForRow(at: indexPath)
    }
    
    func cellForSSID(_ SSID: String?) -> UITableViewCell? {
        guard let indexPath = indexPathForSSID(SSID) else { return nil }
        return tableView.cellForRow(at: indexPath)
    }

    /// Translate an indexPath to a model index.
    fileprivate func SSIDEntryIndexForIndexPath(_ indexPath: IndexPath) -> Int? {
        return indexPath.row
    }
    
    /// Get a model value for the given indexPath.
    fileprivate func SSIDEntryForIndexPath(_ indexPath: IndexPath) -> WifiNetwork? {
        guard let entryIndex = SSIDEntryIndexForIndexPath(indexPath) else { return nil }
        return SSIDEntries[entryIndex]
    }
    
    // MARK: - <UITableViewDatasource> -
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard let sectionCase = Section(rawValue: section) else {
            return nil
        }

        guard
            let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: sectionCase.reuse.reuseIdentifier) else {
            return nil
        }

        configure(headerView: headerView, for: sectionCase)

        return headerView
    }

    func configure(headerView: UITableViewHeaderFooterView, for section: Section) {
        
        if let sectionHeaderView = headerView as? SectionHeaderTableViewHeaderFooterView {
            sectionHeaderView.headerText = section.title
            sectionHeaderView.captionText = section.caption
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let sectionCase = Section(rawValue: section) else {
            fatalError("Unrecognized section")
        }
        
        switch sectionCase {
        case .current: return currentNetwork == nil ? 0 : 1
        case .visible: return visibleNetworks.count + 1
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let sectionCase = Section(rawValue: indexPath.section) else {
            fatalError("Unrecognized section")
        }
        
        let cell: UITableViewCell
        
        switch sectionCase {

        case .current:
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuse.networkCell.reuseIdentifier, for: indexPath)
            
        case .visible:
            
            guard indexPath.row < visibleNetworks.count else {
                cell = tableView.dequeueReusableCell(withIdentifier: CellReuse.customNetworkCell.reuseIdentifier, for: indexPath)
                break
            }
            
            cell = tableView.dequeueReusableCell(withIdentifier: CellReuse.networkCell.reuseIdentifier, for: indexPath)

        }

        configure(cell: cell, for: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        
        if let networkCell = cell as? AferoWifiNetworkTableViewCell {
            configure(networkCell: networkCell, for: indexPath)
            return
        }
        
    }
    
    func configure(networkCell cell: AferoWifiNetworkTableViewCell, for indexPath: IndexPath) {

        guard let sectionCase = Section(rawValue: indexPath.section) else {
            fatalError("Unrecognized section")
        }
        
        switch sectionCase {
        
        case .current:
            guard let currentNetwork = currentNetwork else {
                fatalError("No currentNetwork to configure.")
            }
            cell.configure(with: currentNetwork)
            
        case .visible:
            let network = visibleNetworks[indexPath.row]
            cell.configure(with: network)
        }

    }
    
    func configureCell(forWifiNetwork wifiNetwork: WifiNetwork?) {
        
        guard
            let indexPath = indexPathForSSIDEntry(wifiNetwork),
            let cell = tableView.cellForRow(at: indexPath) else { return }
        
        configure(cell: cell, for: indexPath)
    }

    func configureCell(forSSID SSID: String?) {
        
        guard
            let indexPath = indexPathForSSID(SSID),
            let cell = tableView.cellForRow(at: indexPath) else { return }
        
        configure(cell: cell, for: indexPath)
    }

    
    // MARK: - <UITableViewDelegate> -
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
//        <#code#>
//    }
//
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
        guard indexPath == currentNetworkIndexPath else {
            return nil
        }
        
        var ret: [UITableViewRowAction] = []
        ret.append(
            UITableViewRowAction(
                style: .destructive,
                title: NSLocalizedString("Disconnect", comment: "Scan wifi disconnect from network action title"),
                handler: {
                    [weak self] (action, path) in
//                    self?.disconnectFromCurrentNetwork()
                }
            )
        )
        
        return ret
    }
    
    // ========================================================================
    // MARK: - UI State managemnt
    // ========================================================================
    
    /// Whether we've enver scanned, are currently scanning, or have scanned.
    ///
    /// - **`.Unscanned`**: We've never attempted a scan.
    /// - **`.Scanning`**: We're currently scanning.
    /// - **`.Scanned`**: We've scanned at least once.
    
    fileprivate enum ScanningState {
        
        /// We're waiting to be able to transition to scanning state.
        case waiting
        
        /// We've never attempted a scan.
        case unscanned
        
        /// We're currently scanning.
        case scanning
        
        /// We've scanned at least once.
        case scanned
        
        /// Simple state machine: That which has been scanned cannot be unscanned,
        /// but we can toggle between scanning and scanned states.
        var nextState: ScanningState {
            switch self {
            case .waiting: return .unscanned
            case .unscanned: return .scanning
            case .scanning: return .scanned
            case .scanned: return .scanning
            }
        }
        
        func canTransition(_ toState: ScanningState) -> Bool {
            
            switch (self, toState) {
            case (.waiting, .unscanned): fallthrough
            case (.waiting, .scanning): fallthrough
            case (.scanning, .waiting): fallthrough
            case (.unscanned, .scanning): fallthrough
            case (.unscanned, .waiting): fallthrough
            case (.scanning, .scanned): fallthrough
            case (.scanned, .scanning):
                return true
                
            default:
                return false
            }
        }
        
    }
    
    fileprivate func transitionToScanningState(_ toState: ScanningState) {
        
        guard scanningState.canTransition(toState) else {
            fatalError("Invalid state transition from \(scanningState) to \(toState)")
        }
        
        scanningState = toState
    }
    
    /// Our current scanning state. Changes result in an `updateUI()`
    fileprivate var scanningState: ScanningState = .waiting {
        didSet {
            
            if oldValue == scanningState { return }
            
            updateUI()
            
            switch scanningState {
                
            case .scanning:
                scan()
                
            case .waiting:
                cancelScan()
                
            case .scanned: fallthrough
            case .unscanned:
                break
            }
            
        }
    }
    
    // MARK: - WifiSetupManager State Change Handling -
    
    // ========================================================================
    // MARK: - Wifi setup attribute observation
    // ========================================================================
    
    func handleManagerStateChanged(_ newState: WifiSetupManagerState) {
        DDLogInfo("Got new wifi setup manager state: \(newState)", tag: TAG)
        
        switch newState {
        case .ready:
            transitionToScanningState(.scanning)
        case .notReady:
            transitionToScanningState(.waiting)
        case .managing:
            break
            
        case .completed:
            break
        }
    }
    
    func handleWifiSetupError(_ error: Error) {
        
        let completion: ()->Void = {
            
            let msg = String(
                format: NSLocalizedString("Unable to complete wifi setup: %@",
                                          comment: "wifi setup error template"
                ),
                error.localizedDescription
            )
            
            SVProgressHUD.showError(withStatus: msg)
        }
        
        if let _ = presentedViewController {
            dismiss(animated: true, completion: completion)
            return
        }
        
        completion()
    }
    
    // MARK: - Wifi Config -
    
    // MARK: SSID Scanning
    
    /// Start a scan for SSIDs (In the sim, this just causes us to reload some sample SSIDs.)
    
    fileprivate func scan() {
        do {
            try wifiSetupManager?.scan()
        } catch {
            DDLogError("Error thrown attempting to scan for wifi SSIDs: \(String(describing: error))", tag: TAG)
            handleWifiSetupError(error)
        }
    }
    
    /// Cancel a previous scan request.
    
    func cancelScan() {
        do {
            try wifiSetupManager?.cancelScan()
        } catch {
            DDLogError("Error thrown attempting to cancel scan for wifi SSIDs: \(String(describing: error))", tag: TAG)
            handleWifiSetupError(error)
        }
    }
    
    /// Handle receipt of scan results.
    func handleSSIDListChanged(_ newList: WifiSetupManaging.WifiNetworkList) {
        DDLogInfo("Device \(deviceModel!.deviceId) got new SSID list: \(String(describing: newList))", tag: TAG)
        setSSIDEntries(newList)
    }
    
    // MARK: Association/Authentication
    
    /// Forward an SSID/password pair to Hubby to attempt association.
    
    func attemptAssociate(_ ssidEntry: WifiNetwork, password: String) {
        do {
            try wifiSetupManager?.attemptAssociate(ssidEntry.ssid, password: password)
        } catch {
            DDLogError("Error thrown attempting to associate SSID \(String(describing: ssidEntry)): \(String(describing: error))", tag: TAG)
        }
    }
    
    /// Cancel a previous association request.
    func cancelAttemptAssociate() {
        do {
            try wifiSetupManager?.cancelAttemptAssociate()
        } catch {
            DDLogError("Error thrown attempting cancel SSID association: \(String(describing: error))", tag: TAG)
        }
    }

    /// The credentials were successfully sent to the device; it will proceed to attempt to associate
    /// with the given wifi network.
    
    func handlePasswordCommitted() {
        DDLogInfo("Device \(deviceModel!.deviceId) committed password", tag: TAG)
    }
    
    /// Association with the wifi network succeeded (we were able to establish a pre-authentication connection)
    func handleAssociateSucceeded() {
        DDLogInfo("Device \(deviceModel!.deviceId) associate succeeded (default impl)", tag: TAG)
    }

    /// Association with the wifi network failed. This is likely unrecoverable.
    func handleAssociateFailed() {
        DDLogError("Device \(deviceModel!.deviceId) associate failed (default impl)", tag: TAG)
    }
    
    /// Handshake succeeded; we were able to authenticate to the network and get an IP address.
    func handleHandshakeSucceeded() {
        DDLogInfo("Device \(deviceModel!.deviceId) handshake succeeded (default impl)", tag: TAG)
    }
    
    /// Handshake failed. The *may* be due to a bad password, and so may be recoverable through a retry.
    func handleHandshakeFailed() {
        DDLogError("Device \(deviceModel!.deviceId) handshake failed (default impl)", tag: TAG)
    }
    
    /// We were able to connect to the network and get an IP address, but we were unable to see the
    /// Afero cloud from this network. This is likely due to a configuration or connectivity issue
    /// with the network itself.
    func handleEchoFailed() {
        DDLogError("Device \(deviceModel!.deviceId) echo failed (unable to ping Afero cloud) (default impl)", tag: TAG)
    }

    /// We were unable to find a network with the given SSID.
    func handleSSIDNotFound() {
        DDLogError("Device \(deviceModel!.deviceId) SSID not found (default impl)", tag: TAG)
    }
    

    // MARK: <AferoWifiPasswordPromptViewDelegate
    
    func wifiPasswordPromptView(_ promptView: AferoWifiPasswordPromptView, attemptAssociateWith ssid: String, usingPassword: String?, connectionStatusChangeHandler: @escaping (WifiSetupManaging.WifiState) -> Void) {
//        <#code#>
    }
    
    func cancelAttemptAssociation(for promptView: AferoWifiPasswordPromptView) {
//        <#code#>
    }
    
    

    
}

