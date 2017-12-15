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

extension WifiSetupManaging.WifiNetwork : WifiNetworkProto { }

class ScanWifiViewController: UITableViewController {
    
    // MARK: Section and Cell Config
    
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
    
    
//    @IBOutlet weak var tableView: UITableView!
    
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
        
        tableView.layer.cornerRadius = 10
        
        tableView.reloadData()

        startWifiSetupManager()
    }
    
    // MARK: - Actions -
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBAction func refreshTapped(_ sender: Any) {
        rescan()
    }
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBAction func doneButtonTapped(_ sender: Any) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func rescan() {
        currentNetwork = TestWifiNetwork.testNetworks().first
//        visibleNetworks = TestWifiNetwork.testNetworks().sorted { return $0.sortId < $1.sortId }
    }
    
    // MARK: - Model -
    
    typealias WifiNetwork = TestWifiNetwork
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
                    self?.disconnectFromCurrentNetwork()
                }
            )
        )
        
        return ret
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    // MARK: Network Interaction
    
    var wifiSetupManager: WifiSetupManaging?
    var wifiSetupDisposable: Disposable? {
        willSet { wifiSetupDisposable?.dispose() }
    }
    
    func startWifiSetupManager() {
        wifiSetupDisposable = wifiSetupManager?
            .wifiSetupEventSignal
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] event in switch event {
                case .value(let setupEvent): self?.handleWifiSetupEvent(event: setupEvent)
                case .completed: self?.handleWifiSetupCompleted()
                case .interrupted: self?.handleWifiSetupInterrupted()
                }
        }
        wifiSetupManager?.start()
    }
    
    func handleWifiSetupEvent(event: WifiSetupEvent) {
        switch event {
     
        case .managerStateChange(let newState):
            handleWifiSetupManagerStateChanged(to: newState)
            
        case .ssidListChanged(let l): self.visibleNetworks = l
        default: break
        }
    }
    
    
    func handleWifiSetupManagerStateChanged(to newState: WifiSetupManagerState) {
        
    }
    
    func handleWifiSetupCompleted() {
        
    }
    
    func handleWifiSetupInterrupted() {
        
    }
    
    func disconnectFromCurrentNetwork() {
        currentNetwork = nil
    }
    
    func scanForNetworks() {
        try? wifiSetupManager?.scan()
    }
    
    func connectToNetwork(at indexPath: IndexPath) {
        DDLogWarn("connect to network not implemented!")
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
