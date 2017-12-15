//
//  AccountInfoTableViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import PromiseKit
import CocoaLumberjack
import Afero
import SVProgressHUD

import QRCodeReader
import AVFoundation
import HTTPStatusCodes

import LKAlertController

typealias APIClient = AFNetworkingAferoAPIClient

// MARK: - AccountViewController -

class AccountInfoCell: UITableViewCell {
    
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var networkStatusLabel: UILabel!
    @IBOutlet weak var softhubSwitch: UISwitch!
    @IBAction func softhubSwitchValueChanged(_ sender: Any) {
    }
    
}

enum AccountInfoHeaderFooterViewReuse {
    
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
    
    static var allCases: Set<AccountInfoHeaderFooterViewReuse> {
        return [ .sectionHeader ]
    }
    
}


enum AccountInfoSection: Int {
    
    case accountInfo = 0
    case devices = 1
    
    var title: String {
        switch self {
        case .accountInfo: return NSLocalizedString("Account Info", comment: "Account info header title")
        case .devices: return NSLocalizedString("Devices", comment: "Devices header title")
        }
    }
    
    var caption: String? {
        switch self {
        case .devices: return NSLocalizedString("The following devices are associated with your account.", comment: "Devices header title")
        case .accountInfo: return nil
        }
    }

    
    var cellIdentifier: String {
        switch self {
        case .accountInfo: return "AccountInfo"
        case .devices: return "Device"
        }
    }
    
    static let Count = AccountInfoSection.devices.rawValue + 1
}

fileprivate extension IndexPath {
    
    var accountInfoSection: AccountInfoSection? {
        return AccountInfoSection(rawValue: section)
    }
}

class AccountViewController: UITableViewController {
    
    var userId: String? {
        get { return UserDefaults.standard.userId }
        set { UserDefaults.standard.userId = newValue }
    }
    
    // MARK: Lifecycle
    
    var zeroStateView: AccountInfoZeroStateView {
        return tableView.backgroundView as! AccountInfoZeroStateView
    }
    
    func updateBackgroundVisibility(animated: Bool = true, delay: TimeInterval = 0.0) {

        if shouldShowTableContent {
            _ = zeroStateView.hideImage(animated: animated, delay: delay).then {
                ()->Void in
                self.navigationController?.setNavigationBarHidden(false, animated: animated)
                self.tableView.separatorStyle = .singleLine
            }
            return
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
        _ = zeroStateView.showImage(animated: animated, delay: delay)
        tableView.separatorStyle = .none
        
    }
    
    override func loadView() {
        super.loadView()
        tableView.backgroundView = AccountInfoZeroStateView.loadFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        
        tableView.estimatedSectionHeaderHeight = 25
        tableView.sectionHeaderHeight = UITableViewAutomaticDimension

        AccountInfoHeaderFooterViewReuse.allCases.forEach {
            tableView.register($0.reuseClass, forHeaderFooterViewReuseIdentifier: $0.reuseIdentifier)
        }

        updateBackgroundVisibility(animated: false)
        refreshAccountAccess()
    }
    
    // MARK: Outlets and Actions
    
    @IBOutlet weak var signOutButton: UIBarButtonItem!
    @IBAction func signOutTapped(_ sender: Any) {
        _ = APIClient.default.signOut().then {
            self.user = nil
        }
    }
    
    @IBAction func unwindFromSignIn(segue: UIStoryboardSegue) {
        refreshAccountAccess()
    }
    
    @IBAction func unwindFromDeviceInspector(segue: UIStoryboardSegue) {
        
    }
    
    // MARK: The fun begins
    
    @discardableResult
    func refreshAccountAccess() -> Promise<Void> {
        return APIClient.default.fetchAccountInfo()
            .then {
                user in self.user = user
            }.catch {
                err in self.user = nil
        }
    }
    
    // MARK: Conclave event stream observation
    
    var user: UserAccount.User? {
        didSet {
            conclaveAccess = nil
            if user == nil {
                userId = nil
                networkStatus = .notConnected
                title = "AferoLab"
                
                labNavigationController.presentSignin()
                return
            }

            userId = user?.userId
            title = accountAccess?.accountDescription
            networkStatus = .connecting
            
            if let accountId = accountId {
                authConclave(accountId: accountId)
            }
            
        }
    }
    
    var accountAccess: UserAccount.User.AccountAccess? {
        return user?.accountAccess?.first
    }

    var accountId: String? {
        return accountAccess?.accountId
    }
    
    var conclaveAccess: ConclaveAccess? {

        willSet {
            model = nil
        }
        
        didSet {
            guard
                conclaveAccess != nil,
                let accountId = accountId,
                let userId = userId else { return }

            let deviceCollection = DeviceCollection(
                apiClient: APIClient.default,
                conclaveAuthable: self,
                accountId: accountId,
                userId: userId,
                mobileDeviceId: UserDefaults.standard.clientIdentifier
            )
            
            model = DeviceCollectionDeviceCollator(deviceCollection: deviceCollection)
            deviceCollection.start()
        }
        
    }
    
    // MARK: Model
    
    enum NetworkStatus: CustomStringConvertible {

        case notConnected
        case connecting
        case connected
        
        var description: String {
            switch self {
            case .notConnected: return NSLocalizedString("Not Connected", comment: "Not connected network status title")
            case .connecting: return NSLocalizedString("Connecting", comment: "Connecting network status title")
            case .connected: return NSLocalizedString("Connected", comment: "Connected network status title")
            }
        }
        
    }
    
    var networkStatus: NetworkStatus = .notConnected {
        didSet {
            let indexPath = IndexPath(row: 0, section: AccountInfoSection.accountInfo.rawValue)
            guard let cell = tableView.cellForRow(  at: indexPath ) else { return }
            configure(cell: cell, for: indexPath)
        }
    }
    
    var TAG: String { return "AccountViewController" }
    
    private var softhubEnabled: Bool = false {
        didSet {
            UserDefaults.standard.enableSofthub = softhubEnabled
            if softhubEnabled {
                guard let accountId = accountId else {
                    DDLogWarn("No accountId; bailing on softhub start.")
                    return
                }
                
                do {
                    try SofthubMinder.sharedInstance.start(withAccountId: accountId) {
                        associationId in
                        _ = APIClient.default.associateDevice(with: associationId, to: accountId)
                            .then {
                                device in
                                DDLogDebug("Associated device: \(String(describing: device))", tag: self.TAG)
                            }.catch {
                                err in
                                DDLogError("Unable to associate device: \(String(reflecting: err))", tag: self.TAG)
                        }
                    }
                } catch {
                    DDLogWarn("Error attempting to start softhub: \(String(describing: error))")
                }
                
            } else {
                SofthubMinder.sharedInstance.stop()
            }
        }
    }
    
    var modelDisposable: Disposable? {
        willSet { modelDisposable?.dispose() }
    }
    
    var deviceCollectionStateDisposable: Disposable? {
        willSet { deviceCollectionStateDisposable?.dispose() }
    }

    func subscribeToDeviceCollectionStateUpdates() {
        deviceCollectionStateDisposable = model?.deviceCollection?.stateSignal.observeValues {
            [weak self] event in self?.updateLoadingProgressForState(event)
        }
    }
    
    func unsubscribeFromDeviceCollectionUpdates() {
        deviceCollectionStateDisposable = nil
    }
    
    func updateLoadingProgressForState(_ state: DeviceCollection.State?) {
        
        guard let state = state else { return }
        
        switch(state) {
        case .unloaded: networkStatus = .notConnected
        case .loaded: networkStatus = .connected
        case .loading: networkStatus = .connecting
        case .error(let error):
            networkStatus = .notConnected
            DDLogError("Device collection error: \(String(reflecting: error))")        }
    }

    
    var model: DeviceCollectionDeviceCollator? {
        didSet {

            updateBackgroundVisibility(delay: 0.25)
            
            let indices = IndexSet([AccountInfoSection.devices.rawValue, AccountInfoSection.accountInfo.rawValue])
            tableView.reloadSections(indices, with: .automatic)
            
            modelDisposable = model?.collatorEventSignal.observe(on: QueueScheduler.main).observeValues {
                [weak self] event in switch event {
                case .collationUpdated(let deltas): self?.modelDidUpdate(deltas)
                }
            }

            guard model != nil else {
                unsubscribeFromDeviceCollectionUpdates()
                return
            }
            
            subscribeToDeviceCollectionStateUpdates()
        }
    }
    
    func modelDidUpdate(_ deltas: IndexDeltas) {
        
        if deltas.empty { return }
        
        tableView.beginUpdates()
        
        tableView.deleteRows(at: deltas.deletions.indexes().map {
            IndexPath( row: $0, section: AccountInfoSection.devices.rawValue)
            }, with: .automatic)

        tableView.insertRows(at: deltas.insertions.indexes().map {
            IndexPath( row: $0, section: AccountInfoSection.devices.rawValue)
        }, with: .automatic)
        
        tableView.reloadSections(IndexSet(integer: AccountInfoSection.accountInfo.rawValue), with: .automatic)
        tableView.endUpdates()
        
        tableView.indexPathsForVisibleRows?.forEach {
            guard let cell = tableView.cellForRow(at: $0) else { return }
            self.configure(cell: cell, for: $0)
        }
        
        updateBackgroundVisibility(animated: true)

    }
    
    func indexPath(forDevice device: DeviceModelable) -> IndexPath {
        
        guard let model = model else {
            fatalError("nil model")
        }
        
        guard let index = model.indexForDeviceId(device.deviceId) else {
            fatalError("No device with id \(device.deviceId)")
        }
        
        return IndexPath(row: index, section: AccountInfoSection.devices.rawValue)
    }
    
    func indexPath(forDeviceIndex index: Int) -> IndexPath {
        return IndexPath(item: index, section: AccountInfoSection.devices.rawValue)
    }
    
    func device(at indexPath: IndexPath) -> DeviceModelable? {
        
        guard indexPath.accountInfoSection == .devices else { return nil }
        
        guard let model = model else {
            fatalError("nil model")
        }
    
        guard (0..<model.numberOfDevices()).contains(indexPath.item) else { return nil }
        
        return model.deviceForIndex(indexPath.item)
    }
    
    // MARK: <UITableViewDataSource>
    
    var shouldShowTableContent: Bool {
        return true
//        return (model?.numberOfDevices() ?? 0) > 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return AccountInfoSection.Count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if !shouldShowTableContent { return nil }
        
        guard let section = AccountInfoSection(rawValue: section) else {
            return nil
        }
        
        let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: AccountInfoHeaderFooterViewReuse.sectionHeader.reuseIdentifier
            ) as! SectionHeaderTableViewHeaderFooterView
        configure(headerView: headerView, for: section)
        return headerView
    }
    
    func configure(headerView: SectionHeaderTableViewHeaderFooterView, for section: AccountInfoSection) {
        headerView.headerText = section.title
        headerView.captionText = section.caption
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if !shouldShowTableContent { return 0 }
        
        guard let s = AccountInfoSection(rawValue: section) else {
            fatalError("Unknown section \(section)")
        }
        
        switch s {
        case .accountInfo: return 1
        case .devices: return model?.numberOfDevices() ?? 0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let s = indexPath.accountInfoSection else {
            fatalError("Unrecognized section \(indexPath.section)!")
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: s.cellIdentifier, for: indexPath)
        configure(cell: cell, for: indexPath)
        return cell
        
    }
    
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        
        guard let s = indexPath.accountInfoSection else {
            fatalError("Unrecognized section \(indexPath.section)!")
        }
        
        switch s {
        case .accountInfo:
            guard let accountCell = cell as? AccountInfoCell else {
                fatalError("Expected AccountInfoCell; got \(cell)")
            }
            
            accountCell.accountNameLabel.text = user?.credentialId
            accountCell.networkStatusLabel.text = String(describing: networkStatus)
            accountCell.softhubSwitch.isOn = softhubEnabled
            accountCell.softhubSwitch.removeTarget(nil, action: nil, for: .valueChanged)
            accountCell.softhubSwitch.addTarget(self, action: #selector(softhubSwitchValueChanged(_:)), for: .valueChanged)
            
        case .devices:
            guard let device = self.device(at: indexPath) else {
                cell.textLabel?.text = "<unknown>"
                break
            }
            cell.textLabel?.text = device.displayName
            
            var detailText = device.deviceId
            if device.isLocalSofthub {
                detailText = detailText + " (Local Softhub)"
            }
            cell.detailTextLabel?.text = detailText
            
            
        }
        
        cell.selectionStyle = .none
        
    }
    
    @objc func softhubSwitchValueChanged(_ sender: Any) {
        softhubEnabled = (sender as? UISwitch)?.isOn ?? false
    }
    
    // MARK: <UITableViewDelegate>
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        guard let _ = self.device(at: indexPath) else { return [] }
        
        return [
            UITableViewRowAction(
            style: .destructive,
            title: NSLocalizedString("Disassociate", comment: "Disassociate device table row action titile")) {
                [weak self] action, indexPath in
                _ = self?.disassociateDevice(at: indexPath)
                },
        ]
        
    }
    
    // MARK: Actions
    
    @IBOutlet weak var associateDeviceButtonItem: UIBarButtonItem!

    @IBAction func associateDeviceTapped(_ sender: UIBarButtonItem) {
        #if (arch(i386) || arch(x86_64)) && os(iOS) // simulator
            presentManualAssociationIdEntry()
        #else
            presentQRCodeReader()
        #endif
    }
    
    func presentManualAssociationIdEntry() {

        var textField = UITextField()
        textField.keyboardType = .asciiCapable
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 9.0
        textField.placeholder = NSLocalizedString("e.g, '5bf1fffff649'", comment: "Manual add device placeholder text")
        textField.clearButtonMode = .always
        textField.textAlignment = .center

        Alert(
            title: NSLocalizedString("Add Device", comment: "Manual add device alert title"),
            message: NSLocalizedString("Enter the association ID for the device you'd like to add:", comment: "Manual add device alert message")
            )
            .addTextField(&textField)

            .addAction(
                NSLocalizedString("Add", comment: "Manual add device add action title"),
                style: UIAlertActionStyle.default) {
                    [weak self] action in
                    DDLogInfo("Add tapped; association id: \(String(describing: textField.text))")
                    guard let associationId = textField.text else {
                        return
                    }
                    _ = self?.associateDevice(with: associationId)
            }
            
            .addAction(
                NSLocalizedString("Cancel", comment: "Manual add device cancel button title"),
                style: UIAlertActionStyle.cancel) {
                    action in
                    DDLogInfo("Cancel tapped.")
            }
            .show()
    }
        
    func presentQRCodeReader() {
        readerVC.delegate = self
        readerVC.modalPresentationStyle = .popover
        present(readerVC, animated: true, completion: nil)
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [AVMetadataObject.ObjectType(rawValue: AVMetadataObject.ObjectType.qr.rawValue)], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
            
        case "ShowDeviceInspector":
            
            guard let selectedIndex = tableView.indexPathForSelectedRow else {
                DDLogError("No selection for device inspector segue.", tag: TAG)
                return
            }
            
            guard let deviceModel = device(at: selectedIndex) else {
                DDLogError("No device at index \(String(describing: selectedIndex))", tag: TAG)
                return
            }
            
            guard let inspector = segue.destination as? DeviceInspectorViewController else {
                DDLogError("Unexpected type (\(String(describing: type(of: segue.destination))).", tag: TAG)
                return
            }
            
            inspector.deviceModelable = deviceModel
            
        default:
            DDLogWarn("No configuration for \(segue.identifier ?? "<nil segue id>")", tag: TAG)
        }
    }
    
}

// MARK: - Device Association <QRCodeReaderDelegate> -

extension AccountViewController {
    
    func associateDevice(with associationId: String) -> Promise<Void> {
        
        guard let deviceCollection = model?.deviceCollection else {
            return Promise { _, reject in reject("No model/deviceCollection.") }
        }

        let trimmedAssociationId = associationId.trimmed.replacingOccurrences(of: "-", with: "")
        
        SVProgressHUD.show(
            withStatus: String(
                format: NSLocalizedString(
                    "Associating %@",
                    comment: "Assocating device status fmt"
                ), trimmedAssociationId
            )
        )
        
        return deviceCollection
            .addDevice(with: associationId)
            .then {
                device -> Void in
                DDLogDebug("Successfully associated associationId \(trimmedAssociationId); device: \(String(reflecting: device))")
                SVProgressHUD.showSuccess(
                    withStatus: String(
                        format: NSLocalizedString(
                            "Done!",
                            comment: "Associate device Done! message"
                        )
                    )
                )
            }.catch {
                error in
                
                DDLogError("Error associating associationId \(trimmedAssociationId): \(error.localizedDescription)", tag: self.TAG)
                
                let messageTmplGeneric = NSLocalizedString("Problem associating %@ (no additional info).", comment: "Add device generic error message format")
                let messageTmplCode = NSLocalizedString("Problem associating %@ (HTTP status %@)", comment: "Add device code error message format")
                let messageTmplDetail = NSLocalizedString("Problem associating %@. %@ (HTTP status %@)", comment: "Add device detail error message format")

                var message = String(format: messageTmplGeneric, associationId)
                
                switch error.httpStatusCodeValue {
                    
                case .some(.badRequest):
                    message = String(
                        format: messageTmplDetail,
                        associationId,
                        NSLocalizedString("Please check the association id and try again.", comment: "check association id and try again error message"),
                        HTTPStatusCode.badRequest.description
                    )
                case .some(let code):
                    message = String(format: messageTmplCode, associationId, code.description)

                default: break
                }
                
                SVProgressHUD.showError( withStatus: message, maskType: .gradient)
                
        }
        
    }
    
    func disassociateDevice(at indexPath: IndexPath) -> Promise<Void> {
        
        guard let device = self.device(at: indexPath) else {
            return Promise { _, reject in reject("No device at \(indexPath)") }
        }
        
        guard let deviceCollection = model?.deviceCollection else {
            return Promise { _, reject in reject("No model/deviceCollection.") }
        }
        
        SVProgressHUD.show(
            withStatus: NSLocalizedString(
                "Disassociating…",
                comment: "Disassociate device status hud message"),
            maskType: .clear
        )
        
        return deviceCollection.removeDevice(with: device.deviceId).then {
            deviceId -> Void in
            DDLogDebug("Disassociated device \(String(describing: deviceId))", tag: self.TAG)
            SVProgressHUD.showSuccess(
                withStatus: String(
                    format: NSLocalizedString(
                        "Done!",
                        comment: "Associate device Done! message"
                    )
                )
            )
            }.catch {
                error in
                SVProgressHUD.showError(
                    withStatus: String(
                        format: NSLocalizedString(
                            "Unable to disassociate device: %@",
                            comment: "Disassociate device failure"
                        ),
                        error.localizedDescription
                    ),
                    maskType: .clear
                )
        }
    }

}

extension AccountViewController: QRCodeReaderViewControllerDelegate {
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
        DDLogDebug("Got QRCodeReaderResult \(String(describing: result))", tag: TAG)
        _ = associateDevice(with: result.value)
    }
    
    func reader(_ reader: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
        DDLogDebug("Switching capturing to: \(newCaptureDevice.device.localizedName)", tag: TAG)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - <ConclaveAuthable> -

extension AccountViewController: ConclaveAuthable {
    
//    var conclaveMobileDeviceId: String {
//        return UserDefaults.standard.clientIdentifier
//    }
    
    var conclaveClientVersion: String { return "AferoLabIOS/1.0" }
    
    var conclaveClientType: String { return "ios" }
    
    @discardableResult
    func authConclave(accountId: String) -> Promise<ConclaveAccess> {
        
        if let conclaveAccess = conclaveAccess {
            return Promise { fulfill, _ in fulfill(conclaveAccess) }
        }
        
        return APIClient.default.authConclave(accountId: accountId)
            .then {
                conclaveAccess -> ConclaveAccess in
                self.conclaveAccess = conclaveAccess
                return conclaveAccess
        }
    }

    func authConclave(accountId: String, onDone: @escaping AuthConclaveOnDone) {
        authConclave(accountId: accountId)
            .then {
                onDone($0, nil)
            }.catch {
                err in onDone(nil, err)
        }
    }
    
}

extension UserDefaults {
    

    var userId: String? {
        get { return string(forKey: "userId") }
        set { set(newValue, forKey: "userId") }
    }
    
    var clientIdentifier: String! {
        
        get {
            
            if let ret = string(forKey: "clientIdentifier") {
                return ret
            }
            
            let ret = NSUUID().uuidString
            set(ret, forKey: "clientIdentifier")
            synchronize()
            return ret
        }
        
        set {
            set(newValue, forKey: "clientIdentifier")
        }
        
    }

}
