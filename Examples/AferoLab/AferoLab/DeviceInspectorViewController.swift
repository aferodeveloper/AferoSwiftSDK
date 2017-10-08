//
//  DeviceInspectorViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 10/2/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import CocoaLumberjack
import Afero
import SVProgressHUD

class DeviceInspectorDeviceInfoCell: UITableViewCell {
    
    @IBOutlet weak var deviceTypeLabel: UILabel!
    var deviceType: String? {
        get { return deviceTypeLabel.text }
        set { deviceTypeLabel.text = newValue }
    }
    
    @IBOutlet weak var deviceIdHeaderLabel: UILabel!
    @IBOutlet weak var deviceIdValueLabel: UILabel!
    var deviceId: String? {
        get { return deviceIdValueLabel.text }
        set { deviceIdValueLabel.text = newValue }
    }
    
    @IBOutlet weak var deviceTypeIdHeaderLabel: UILabel!
    @IBOutlet weak var deviceTypeIdValueLabel: UILabel!
    var deviceTypeId: String? {
        get { return deviceTypeIdValueLabel.text }
        set { deviceTypeIdValueLabel.text = newValue }
    }
    
    @IBOutlet weak var profileIdHeaderLabel: UILabel!
    @IBOutlet weak var profileIdValueLabel: UILabel!
    var profileId: String? {
        get { return profileIdValueLabel.text }
        set { profileIdValueLabel.text = newValue }
    }

}

/// A cell which displays a single attribute. To configure,
/// simply set the `attribute` property.

class DeviceInspectorGenericAttributeCell: UITableViewCell {
    
    @IBOutlet weak var attributeNameLabel: UILabel!
    @IBOutlet weak var attributeIdLabel: UILabel!
    @IBOutlet weak var attributeTypeLabel: UILabel!
    @IBOutlet weak var attributeStringValueLabel: UILabel!
    @IBOutlet weak var attributeByteValueLabel: UILabel!

    /// The (compound) value which is used to populate all fields.
    
    var attribute: DeviceModelable.Attribute? {
        
        didSet {
            
            guard let attribute = attribute else {
                attributeNameLabel.text = nil
                attributeIdLabel.text = nil
                attributeTypeLabel.text = nil
                attributeStringValueLabel.text = nil
                attributeByteValueLabel.text = nil
                return
            }
            
            attributeNameLabel.text = attribute.config.descriptor.semanticType
            attributeIdLabel.text = "\(attribute.config.descriptor.id)"
            attributeTypeLabel.text = attribute.config.descriptor.dataType.stringValue ?? "<unknown>"
            attributeStringValueLabel.text = attribute.value.stringValue ?? "<empty>"
            attributeByteValueLabel.text = attribute.value.byteArray.description
        }
    }
    
}

class DeviceInspectorViewController: UITableViewController {
    
    var TAG: String { return "\(type(of: self))" }
    
    enum Reuse {
        
        case empty
        case deviceInfo
        case genericAttribute
        
        var reuseClass: AnyClass {
            switch self {
            case .empty: return UITableViewCell.self
            case .deviceInfo: return DeviceInspectorDeviceInfoCell.self
            case .genericAttribute: return DeviceInspectorGenericAttributeCell.self
            }
        }
        
        var reuseIdentifier: String {
            switch self {
            case .empty: return "DeviceInspectorEmptySectionCell"
            case .deviceInfo: return "DeviceInspectorDeviceInfoCell"
            case .genericAttribute: return "DeviceInspectorGenericAttributeCell"
            }
        }
        
        static var allCases: Set<Reuse> {
            return [ .empty, .deviceInfo, .genericAttribute ]
        }
        
    }
    
    enum Section: Int, CustomDebugStringConvertible {
        
        case deviceInfo = 0
        case mcuApplicationSpecificAttributes
        case gpioAttributes
        case aferoVersionsAttributes
        case mcuVersionsAttributes
        case aferoApplicationSpecificAttributes
        case aferoHubSpecificAttributes
        case aferoCloudProvidedAttributes
        case aferoOfflineSchedulesAttributes
        case aferoSystemSpecificAttributes
        
        static let all: [Section] = [
            .deviceInfo,
            .mcuApplicationSpecificAttributes,
            .gpioAttributes,
            .aferoVersionsAttributes,
            .mcuVersionsAttributes,
            .aferoApplicationSpecificAttributes,
            .aferoHubSpecificAttributes,
            .aferoCloudProvidedAttributes,
            .aferoOfflineSchedulesAttributes,
            .aferoSystemSpecificAttributes,
        ]
        
        static var count: Int { return all.count }

        var description: String {
            let name: String
            switch self {
            case .deviceInfo: name = "Device Info"
            case .mcuApplicationSpecificAttributes: name = "MCU Application Attributes"
            case .gpioAttributes: name = "GPIO Attributes"
            case .aferoVersionsAttributes: name = "Afero Versions"
            case .mcuVersionsAttributes: name = "MCU Versions"
            case .aferoApplicationSpecificAttributes: name = "Afero Application-Specific"
            case .aferoHubSpecificAttributes: name = "Softhub Attributes"
            case .aferoCloudProvidedAttributes: name = "Cloud-Provided Attributes"
            case .aferoOfflineSchedulesAttributes: name = "Offline Schedules"
            case .aferoSystemSpecificAttributes: name = "Afero System-Specific"
            }
            return name
        }
        
        var debugDescription: String {
            
            let name: String
            switch self {
            case .deviceInfo: name = "Section.deviceInfo"
            case .mcuApplicationSpecificAttributes: name = "Section.mcuApplicationSpecificAttributes"
            case .gpioAttributes: name = "Section.gpioAttributes"
            case .aferoVersionsAttributes: name = "Section.aferoVersionsAttributes"
            case .mcuVersionsAttributes: name = "Section.mcuVersionsAttributes"
            case .aferoApplicationSpecificAttributes: name = "Section.aferoApplicationSpecificAttributes"
            case .aferoHubSpecificAttributes: name = "Section.aferoHubSpecificAttributes"
            case .aferoCloudProvidedAttributes: name = "Section.aferoCloudProvidedAttributes"
            case .aferoOfflineSchedulesAttributes: name = "Section.aferoOfflineSchedulesAttributes"
            case .aferoSystemSpecificAttributes: name = "Section.aferoSystemSpecificAttributes"
            }
            
            return "\(name) (\(rawValue))"
        }
        
        var localizedName: String {
            let name: String
            switch self {

            case .deviceInfo:
                name = NSLocalizedString(
                    "Device Info",
                    comment: "DeviceInspectorViewController Section.deviceInfo name"
                )
                
            case .mcuApplicationSpecificAttributes:
                name = NSLocalizedString(
                    "MCU Application Attributes",
                    comment: "DeviceInspectorViewController Section.mcuApplicationSpecificAttributes name"
                )
                
            case .gpioAttributes:
                name = NSLocalizedString(
                    "GPIO Attributes",
                    comment: "DeviceInspectorViewController Section.gpioAttributes name"
                )
                
            case .aferoVersionsAttributes:
                name = NSLocalizedString(
                    "Afero Versions",
                    comment: "DeviceInspectorViewController Section.aferoVersionsAttributes name"
                )
                
            case .mcuVersionsAttributes: name = NSLocalizedString(
                "MCU Versions",
                comment: "DeviceInspectorViewController Section.mcuVersionsAttributes name"
                )
                
            case .aferoApplicationSpecificAttributes:
                name = NSLocalizedString(
                    "Afero Application-Specific",
                    comment: "DeviceInspectorViewController Section.aferoApplicationSpecificAttributes name"
                )
                
            case .aferoHubSpecificAttributes:
                name = NSLocalizedString(
                    "Softhub Attributes",
                    comment: "DeviceInspectorViewController Section.aferoHubSpecificAttributes name"
                )
                
            case .aferoCloudProvidedAttributes:
                name = NSLocalizedString(
                    "Cloud-Provided Attributes",
                    comment: "DeviceInspectorViewController Section.aferoCloudProvidedAttributes name"
                )
                
            case .aferoOfflineSchedulesAttributes:
                name = NSLocalizedString(
                    "Offline Schedules",
                    comment: "DeviceInspectorViewController Section.aferoOfflineSchedulesAttributes name"
                )
                
            case .aferoSystemSpecificAttributes:
                name = NSLocalizedString(
                    "Afero System-Specific",
                    comment: "DeviceInspectorViewController Section.aferoSystemSpecificAttributes name"
                )
                
            }
            
            return name
        }
        
        var localizedDescription: String {
            return String(
                format: NSLocalizedString(
                    "%1$@ (%2$i)",
                    comment: "DeviceInspectorViewController Section localizedDescription template"
                ),
                localizedName,
                rawValue
            )
        }
        
    }
    
    // MARK: Lifecyle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsMultipleSelection = false
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 55
        tableView.rowHeight = UITableViewAutomaticDimension
        
        startObservingDeviceModel()
    }
    
    deinit {
        stopObservingDeviceModel()
    }

    /// The `disposable`, which is our handle to DeviceEventSignal
    /// observation.
    
    private var deviceEventDisposable: Disposable? {
        willSet { deviceEventDisposable?.dispose() }
    }
    
    // MARK: - Device Event Observation
    
    private func startObservingDeviceModel() {

        let TAG = self.TAG

        guard let deviceModel = deviceModel else {
            DDLogWarn("No deviceModel to observe; bailing", tag: TAG)
            return
        }
        
        deviceModel.eventSignal
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] signalEvent in switch signalEvent {

                case let .value(event):
                    self?.handle(event: event)

                case .completed:
                    self?.teardown()
                    
                case let .failed(err):
                    // NOTE: Shown for completeness; .failed(_) messages are never sent.
                    DDLogError("Device model error: \(err.localizedDescription)", tag: TAG)
                    
                case .interrupted:
                    // NOTE: Shown for completeness; .interrupted messages are never sent.
                    DDLogWarn("Device event stream interrupted", tag: TAG)
                }
        }
        
        
        updateVisibleCells()
        updateDeviceStateIndicator()

    }
    
    private func stopObservingDeviceModel() {
        deviceEventDisposable = nil
    }
    
    // MARK: - Device Event Handling
    
    func handle(event: DeviceModelEvent) {
        switch event {
            
        case .deleted:
            teardown()
            
        case .error(let err):
            handle(deviceError: err)
            
        case .errorResolved(let status):
            resolveDeviceErrors(with: status)
            
        case .profileUpdate:
            reloadAllSections()
            
        case .muted(let timeout):
            startMuteTimer(with: timeout)
            
        case .otaStart:
            otaProgress = 0
            
        case .otaProgress(let progress):
            otaProgress = progress
            
        case .otaFinish:
            otaProgress = nil
            
        case .stateUpdate:
            updateVisibleCells()
            updateDeviceStateIndicator()
            
        case .writeStateChange:
            updateWriteStateIndicator()
        }
    }
    
    // MARK: - Display Updates
    
    func updateErrorDisplay() {
        fatalError("updateErrorDisplay not implmeneted")
    }
    
    private var currentErrors: [DeviceErrorStatus: [DeviceError]] = [:] {
        didSet { updateErrorDisplay() }
    }
    
    func handle(deviceError: DeviceError) {
        var errs: [DeviceError] = []
        if let maybeErrs = currentErrors[deviceError.status] {
            errs = maybeErrs
        }
        errs.append(deviceError)
        currentErrors[deviceError.status] = errs
    }
    
    func resolveDeviceErrors(with status: DeviceErrorStatus) {
        currentErrors[status] = nil
    }
    
    func reloadAllSections() {
        let sectionIndices = IndexSet(Section.all.map { $0.rawValue })
        tableView.reloadSections(sectionIndices, with: .automatic)
    }
    
    func updateVisibleCells() {
        tableView.indexPathsForVisibleRows?.flatMap {
            indexPath -> (cell: UITableViewCell, indexPath: IndexPath)? in
            guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
            return (cell: cell, indexPath: indexPath)
            }.forEach {
                configure(cell: $0.cell, for: $0.indexPath)
        }
    }
    
    func updateDeviceStateIndicator() {
        
        var prompt: String?
        
        if deviceModel.isAvailable {
            prompt = NSLocalizedString("Available", comment: "DeviceInspector device state available indicator")
        } else if deviceModel.isLinked {
            prompt = NSLocalizedString("Linked", comment: "DeviceInspector device state linked indicator")
        } else if deviceModel.isVisible {
            prompt = NSLocalizedString("Visible", comment: "DeviceInspector device state visible indicator")
        } else if deviceModel.isConnected {
            prompt = NSLocalizedString("Connected", comment: "DeviceInspector device state connected indicator")
        } else if deviceModel.isLinked {
            prompt = NSLocalizedString("Linked", comment: "DeviceInspector device state linked indicator")
        } else if deviceModel.isDirty {
            prompt = NSLocalizedString("Dirty", comment: "DeviceInspector device state dirty indicator")
        } else if deviceModel.isConnectable {
            prompt = NSLocalizedString("Connectable", comment: "DeviceInspector device connectable available indicator")
        } else if deviceModel.isDirect {
            prompt = NSLocalizedString("Direct", comment: "DeviceInspector device state direct indicator")
        } else if deviceModel.isRebooted {
            prompt = NSLocalizedString("Rebooted", comment: "DeviceInspector device state rebooted indicator")
        }
        
        navigationItem.prompt = prompt

    }
    
    func startMuteTimer(with timeout: TimeInterval) {
        fatalError("startMuteTimer not implemented")
    }
    
    func updateMutedIndicator() {
        fatalError("updateMutedIndicator not implemented")
    }
    
    func updateWriteStateIndicator() {
        DDLogDebug("Device write state now: \(deviceModel.writeState)", tag: TAG)
    }
    
    var otaProgress: Float? {
        didSet {
            // TODO: if non-nil, show the OTA progress indicator, with progress
            // indicated by value.
            // if nil, hid the OTA progress indicator.
        }
    }

    func teardown() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Navigation
    
    func unwindToAccountController() {
        performSegue(withIdentifier: "unwindToAccountController", sender: self)
    }
    
    // MARK: - Model
    
    /// The DeviceModel that this inspector will observe.
    ///
    /// - note: This is `weak` because it's canonically held by the
    ///         `DeviceCollection`.
    
    weak var deviceModel: DeviceModelable! {
        willSet { deviceEventDisposable = nil }
        didSet {
            title = deviceModel?.displayName
        }
    }
    
    // MARK: Attribute Range Visibility Management
    
    var visibleSections: [Section] = Section.all {
        didSet {
            let deltas = oldValue.deltasProducing(visibleSections)
            tableView.beginUpdates()
            tableView.deleteSections(deltas.deletions, with: .automatic)
            tableView.insertSections(deltas.insertions, with: .automatic)
            tableView.endUpdates()
        }
    }
    
    // MARK: Section ↔ Platform Attribute Range translation
    
    func section(for attributeRange: AferoPlatformAttributeRange?) -> Section? {
        
        guard let attributeRange = attributeRange else {
            return nil
        }
        
        guard visibleSections.contains(attributeRange.deviceInspectorSection) else {
            return nil
        }
        
        return attributeRange.deviceInspectorSection
    }
    
    func platformAttributeRange(for section: Section) -> AferoPlatformAttributeRange? {
        return section.platformAttributeRange
    }
    
    // MARK: Attribute Id ↔ Row translation
    
    private typealias SectionAttributeConfigMap = [Section: [DeviceProfile.AttributeConfig]]
    
    private var _sectionAttributeConfigMap: SectionAttributeConfigMap?
    private var sectionAttributeConfigMap: SectionAttributeConfigMap {
        
        if let ret = _sectionAttributeConfigMap { return ret }
        
        guard let deviceModel = deviceModel else { return [:] }
        
        let ret = Section.all.reduce([:]) {
            
            accumulated, section -> SectionAttributeConfigMap in
            
            guard
                let range = section.platformAttributeRange else { return accumulated }
            
            guard let attributes = deviceModel.attributeConfigs(withIdsIn: range) else { return accumulated }
            
            var updatedAccumulated = accumulated
            updatedAccumulated[section] = attributes
                .sorted { $0.descriptor.id < $1.descriptor.id }
            return updatedAccumulated
        }

        _sectionAttributeConfigMap = ret

        return ret
    }
    
    private typealias AttributeIdSectionMap = [Int: Section]
    
    private var _attributeIdSectionMap: AttributeIdSectionMap?
    private var attributeIdSectionMap: AttributeIdSectionMap {
        
        if let ret = _attributeIdSectionMap { return ret }
        
        let ret = sectionAttributeConfigMap.reduce([:]) {
            accumulated, nextPair -> AttributeIdSectionMap in
            var updatedAccumulated = accumulated
            nextPair.value.forEach {
                config in
                updatedAccumulated[config.descriptor.id] = nextPair.key
            }
            return updatedAccumulated
        }
        
        _attributeIdSectionMap = ret
        
        return ret
    }
    
    private func clearAttributeMaps() {
        _sectionAttributeConfigMap = nil
        _attributeIdSectionMap = nil
    }
    
    // MARK: IndexPath ↔ Section, Row conversion
    
    func config(for indexPath: IndexPath) -> DeviceProfile.AttributeConfig? {
        
        guard let section = indexPath.deviceInspectorSection else {
            let msg = "No deviceInspectorSection for \(String(describing: indexPath))"
            assert (false, msg)
            DDLogError(msg, tag: TAG)
            return nil
        }
        
        guard let configs = sectionAttributeConfigMap[section] else {
            let msg = "No attribute config for \(String(describing: section)) / \(String(describing: indexPath))"
            DDLogWarn(msg, tag: TAG)
            return nil
        }
        
        guard configs.count > indexPath.row else {
            let msg = "Attempt to retrieve attribute at index \(indexPath.row) from config array with only \(configs.count) members"
            assert (false, msg)
            DDLogError(msg, tag: TAG)
            return nil
        }
        
        return configs[indexPath.row]
    }

    /// Get the attribute description and state for an `IndexPath`.
    /// - parameter indexPath: The `IndexPath` for which to pull state
    /// - returns: The the relevant attribute, if any.
    /// -
    func attribute(for indexPath: IndexPath) -> DeviceModelable.Attribute? {
        
        guard let attributeId = config(for: indexPath)?.descriptor.id else {
            let msg = "No attributeId for \(String(describing: indexPath))"
            assert(false, msg)
            DDLogError(msg, tag: TAG)
            return nil
        }
        
        guard let ret = deviceModel?.attribute(for: attributeId) else {
            let msg = "No attribute for attributeId \(attributeId); will ignore."
            DDLogWarn(msg, tag: TAG)
            return nil
        }
        
        return ret
    }
    
    /// Get the `IndexPath` for a given `attributeId`.
    /// - parameter attributeId: The attributeId for which to get the indexPath.
    /// - returns: the associated `IndexPath`, if any.
    /// - note: It's an error to pass an `attributeId` with no associated platform attribute range,
    ///         and this will `assert`.

    func indexPath(for attributeId: Int) -> IndexPath? {
        
        guard let section = attributeId.aferoPlatformAttributeRange?.deviceInspectorSection else {
            let msg = "Attribute id \(attributeId) doesn't look like a valid Afero attribute."
            assert(false, msg)
            DDLogError(msg, tag: TAG)
            return nil
        }
        
        guard visibleSections.contains(section) else {
            let msg = "Attribute id \(attributeId)'s section (\(String(describing: section))) not not among visible sections."
            DDLogDebug(msg, tag: TAG)
            return nil
        }
        
        guard let row = sectionAttributeConfigMap[section]?.index(where: { $0.descriptor.id == attributeId }) else {
            let msg = "Attribute id \(attributeId) not found among known attrinutes."
            DDLogDebug(msg, tag: TAG)
            return nil
        }
        
        return IndexPath(row: row, section: section.rawValue)
    }
    
    // MARK: Section Visibility Management
    
//    func updateVisibleAttributeRanges() {
//        showAttributes(in: visibleAttributeRanges)
//    }
//
//    var attributeConfigs: [AferoPlatformAttributeRange: [DeviceProfile.AttributeConfig]]
//
//    func showAttributes(in ranges: Set<AferoPlatformAttributeRange>) {
//        ranges.forEach { showAttributes(in: $0) }
//    }
//
//    func showAttributes(in range: AferoPlatformAttributeRange) {
//
//        guard let attributes = deviceModel?.attributeConfigs(withIdsIn: range) else {
//            hideAttributes(in: range)
//            return
//        }
//
//        attributeConfigs[range] = Array(attributes)
//    }
//
//    func hideAttributes(in ranges: Set<AferoPlatformAttributeRange>) {
//        ranges.forEach { hideAttributes(in: $0) }
//    }
//
//    func hideAttributes(in range: AferoPlatformAttributeRange) {
//        attributeConfigs[range] = nil
//    }
    
    // MARK: - <UITableViewDataSource> -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return visibleSections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if section == 0 {
            return 1
        }
        
        let sections = Section.all.filter({ visibleSections.contains($0) })
        
        guard sections.count > section else {
            fatalError("\(section) is not a valid section.")
        }
        
        guard let ret = sectionAttributeConfigMap[sections[section]]?.count else {
            fatalError("No configs found for section \(section).")
        }
        
        return ret
        
    }
    
    func reuseIdentifier(for indexPath: IndexPath) -> String {
        let section = visibleSections[indexPath.section]
        switch section {
        case .deviceInfo: return Reuse.deviceInfo.reuseIdentifier
        default: return Reuse.genericAttribute.reuseIdentifier
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        guard self.tableView(tableView, numberOfRowsInSection: section) > 0 else {
            return nil
        }
        
        let section = visibleSections[section]
        return section.localizedName
    }
    
//    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//
//        guard self.tableView(tableView, numberOfRowsInSection: section) == 0 else {
//            return nil
//        }
//
//        return NSLocalizedString("Empty", comment: "DeviceInspectorTableViewController empty section footer")
//    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if self.tableView(tableView, numberOfRowsInSection: indexPath.section) == 0 {
            return tableView.dequeueReusableCell(withIdentifier: Reuse.empty.reuseIdentifier, for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier(for: indexPath), for: indexPath)
        configure(cell: cell, for: indexPath)
        return cell
    }
    
    func configure(cell: UITableViewCell, for indexPath: IndexPath) {
        
        if let deviceInfoCell = cell as? DeviceInspectorDeviceInfoCell {
            configure(infoCell: deviceInfoCell)
            return
        }
        
        if let attributeCell = cell as? DeviceInspectorGenericAttributeCell {
            configure(attributeCell: attributeCell, for: indexPath)
        }
    }
    
    func configure(infoCell cell: DeviceInspectorDeviceInfoCell) {
        cell.deviceId = deviceModel?.deviceId
        cell.deviceType = deviceModel?.profile?.deviceType
        cell.deviceTypeId = deviceModel?.profile?.deviceTypeId
        cell.profileId = deviceModel?.profileId
    }
    
    func configure(attributeCell cell: DeviceInspectorGenericAttributeCell, for indexPath: IndexPath) {

        guard let attribute = attribute(for: indexPath) else {

            guard let config = config(for: indexPath) else {
                print(sectionAttributeConfigMap.debugDescription)
                print(attributeIdSectionMap.debugDescription)
                fatalError("No attribute for row \(indexPath.row) in section: \(indexPath.section)")
            }
            
            cell.attribute = nil
            cell.attributeNameLabel.text = config.descriptor.semanticType
            cell.attributeIdLabel.text = "\(config.descriptor.id)"
            cell.attributeByteValueLabel.text = "-"
            cell.attributeStringValueLabel.text = "-"
            cell.attributeTypeLabel.text = config.descriptor.dataType.stringValue
            
            return
        }
        
        cell.attribute = attribute
    }

    // MARK: - <UITableViewDelegate> -

    
}

fileprivate extension AferoPlatformAttributeRange {
    
    var deviceInspectorSection: DeviceInspectorViewController.Section {
        switch self {
        case .mcuApplicationSpecific: return .mcuApplicationSpecificAttributes
        case .gpio: return .gpioAttributes
        case .aferoVersions: return .aferoVersionsAttributes
        case .mcuVersions: return .mcuVersionsAttributes
        case .aferoApplicationSpecific: return .aferoApplicationSpecificAttributes
        case .aferoHubSpecific: return .aferoHubSpecificAttributes
        case .aferoCloudProvided: return .aferoCloudProvidedAttributes
        case .aferoOfflineSchedules: return .aferoOfflineSchedulesAttributes
        case .aferoSystemSpecific: return .aferoSystemSpecificAttributes
        }
    }
    
}

fileprivate extension DeviceInspectorViewController.Section {
    
    var platformAttributeRange: AferoPlatformAttributeRange? {
        return AferoPlatformAttributeRange.all.filter { $0.deviceInspectorSection == self }.first
    }
    
}

fileprivate extension IndexPath {
    
    var deviceInspectorSection: DeviceInspectorViewController.Section? {
        return DeviceInspectorViewController.Section(rawValue: section)
    }
    
}

