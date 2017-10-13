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

// MARK: - Device Info Cell -

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

// MARK: - Attribute Cells -

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

// MARK: - DeviceInspectorViewController -

class DeviceInspectorViewController: UITableViewController, DeviceModelableObserving {
    
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
    
    enum Section: Int, CustomStringConvertible, CustomDebugStringConvertible {
        
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
        tableView.allowsSelection = true
        tableView.remembersLastFocusedIndexPath = true
        tableView.estimatedRowHeight = 55
        tableView.rowHeight = UITableViewAutomaticDimension
        
        startObservingDeviceEvents()
        updateVisibleCells()
        updateDeviceStateIndicator()
    }
    
    deinit {
        stopObservingDeviceEvents()
    }

    // MARK: <DeviceModelableObserving>
    
    /// The DeviceModel that this inspector will observe.
    ///
    /// - note: This is `weak` because it's canonically held by the
    ///         `DeviceCollection`.
    
    weak var deviceModelable: DeviceModelable! {
        didSet { title = deviceModelable?.displayName }
    }
    

    /// The `disposable`, which is our handle to DeviceEventSignal
    /// observation.
    
    var deviceEventSignalDisposable: Disposable?
    
    func handleDeviceDeletedEvent() {
        close()
    }
    
    private var currentErrors: [DeviceErrorStatus: [DeviceError]] = [:] {
        didSet { updateErrorDisplay() }
    }
    
    func handleDeviceErrorEvent(error: DeviceError) {
        var errs: [DeviceError] = []
        if let maybeErrs = currentErrors[error.status] {
            errs = maybeErrs
        }
        errs.append(error)
        currentErrors[error.status] = errs
    }
    
    func handleDeviceErrorResolvedEvent(status: DeviceErrorStatus) {
        currentErrors[status] = nil
    }
    
    func handleDeviceMutedEvent(for duration: TimeInterval) {
        startMuteTimer(with: duration)
    }
    
    func handleDeviceProfileUpdate() {
        reloadAllSections()
    }
    
    func handleDeviceOtaStartEvent() {
        otaProgress = 0
    }
    
    func handleDeviceOtaProgressEvent(with proportion: Float) {
        otaProgress = proportion
    }
    
    func handleDeviceOtaFinishEvent() {
        otaProgress = nil
    }
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        updateVisibleCells()
        updateDeviceStateIndicator()
    }
    
    func handleDeviceWriteStateChangeEvent(newState: DeviceWriteState) {
        updateWriteStateIndicator()
    }

    // MARK: Display Updates
    
    func updateErrorDisplay() {
        // TODO: Implement updateErrorDisplay
        DDLogError("updateErrorDisplay not implemented.", tag: TAG)
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
        
        if deviceModelable.isAvailable {
            prompt = NSLocalizedString("Available", comment: "DeviceInspector device state available indicator")
        } else if deviceModelable.isLinked {
            prompt = NSLocalizedString("Linked", comment: "DeviceInspector device state linked indicator")
        } else if deviceModelable.isVisible {
            prompt = NSLocalizedString("Visible", comment: "DeviceInspector device state visible indicator")
        } else if deviceModelable.isConnected {
            prompt = NSLocalizedString("Connected", comment: "DeviceInspector device state connected indicator")
        } else if deviceModelable.isLinked {
            prompt = NSLocalizedString("Linked", comment: "DeviceInspector device state linked indicator")
        } else if deviceModelable.isDirty {
            prompt = NSLocalizedString("Dirty", comment: "DeviceInspector device state dirty indicator")
        } else if deviceModelable.isConnectable {
            prompt = NSLocalizedString("Connectable", comment: "DeviceInspector device connectable available indicator")
        } else if deviceModelable.isDirect {
            prompt = NSLocalizedString("Direct", comment: "DeviceInspector device state direct indicator")
        } else if deviceModelable.isRebooted {
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
        DDLogDebug("Device write state now: \(deviceModelable.writeState)", tag: TAG)
    }
    
    var otaProgress: Float? {
        didSet {
            // TODO: if non-nil, show the OTA progress indicator, with progress
            // indicated by value.
            // if nil, hid the OTA progress indicator.
        }
    }

    // MARK: Navigation
    
    func close() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func unwindToAccountController() {
        performSegue(withIdentifier: "unwindToAccountController", sender: self)
    }
    
    enum SegueIdentifier: String {
        case showTextViewAttributeInspector = "ShowTextViewAttributeInspector"
        case showSliderAttributeInspector = "ShowSliderAttributeInspector"
        case showSwitchAttributeInspector = "ShowSwitchAttributeInspector"
        case showPickerAttributeInspector = "ShowPickerAttributeInspector"
    }
    
    func performSegue(withIdentifier identifier: SegueIdentifier, sender: Any?) {
        performSegue(withIdentifier: identifier.rawValue, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard
            let identifierString = segue.identifier,
            let identifier = SegueIdentifier(rawValue: identifierString) else {
            return
        }
        
        switch identifier {
            
        case .showTextViewAttributeInspector: fallthrough
        case .showSliderAttributeInspector: fallthrough
        case .showSwitchAttributeInspector: fallthrough
        case .showPickerAttributeInspector:
            
            guard let selectedIndex = tableView.indexPathForSelectedRow else {
                DDLogError("No selection for device inspector segue.", tag: TAG)
                return
            }
            
            guard let attribute = attribute(for: selectedIndex) else {
                DDLogError("No attribute for row: \(selectedIndex.row) in section: \(selectedIndex.section)", tag: TAG)
                return
            }
            
            guard let inspector = segue.destination as? BaseAttributeInspectorViewController else {
                DDLogError("Unexpected type (\(String(describing: type(of: segue.destination))).", tag: TAG)
                return
            }
            
            inspector.deviceModelable = deviceModelable
            inspector.attributeId = attribute.config.descriptor.id
            
        }
    }

    
    // MARK: Model
    
    var visibleSections: [Section] = Section.all {
        didSet {
            let deltas = oldValue.deltasProducing(visibleSections)
            tableView.beginUpdates()
            tableView.deleteSections(deltas.deletions, with: .automatic)
            tableView.insertSections(deltas.insertions, with: .automatic)
            tableView.endUpdates()
        }
    }
    
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
    
    private typealias SectionAttributeConfigMap = [Section: [DeviceProfile.AttributeConfig]]
    
    private var _sectionAttributeConfigMap: SectionAttributeConfigMap?
    private var sectionAttributeConfigMap: SectionAttributeConfigMap {
        
        if let ret = _sectionAttributeConfigMap { return ret }
        
        guard let deviceModel = deviceModelable else { return [:] }
        
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
        
        guard let ret = deviceModelable?.attribute(for: attributeId) else {
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
    
    // MARK: <UITableViewDataSource>

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
        cell.deviceId = deviceModelable?.deviceId
        cell.deviceType = deviceModelable?.profile?.deviceType
        cell.deviceTypeId = deviceModelable?.profile?.deviceTypeId
        cell.profileId = deviceModelable?.profileId
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
    
    // MARK: <UITableViewDelegate>
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let attribute = attribute(for: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        var maybeSegueIdentifier: SegueIdentifier?
        
        switch attribute.config.descriptor.dataType {
        case .utf8S: fallthrough
        case .bytes:
            maybeSegueIdentifier = .showTextViewAttributeInspector
            
        case .boolean:
            maybeSegueIdentifier = .showSwitchAttributeInspector
            
        case .q1516: fallthrough
        case .q3132: fallthrough
        case .sInt8: fallthrough
        case .sInt16: fallthrough
        case .sInt32: fallthrough
        case .sInt64:
            maybeSegueIdentifier = .showSliderAttributeInspector
            
        // Floats are deprecated; use .q1516 / .q3132 instead.
        case .float32: fallthrough
        case .float64:
        DDLogWarn("Will show slider for deprecated type \(attribute.config.descriptor.dataType)", tag: TAG)
            maybeSegueIdentifier = .showSliderAttributeInspector
            
        // Added for completeness; the following are not supported.
        case .uInt8: fallthrough
        case .uInt16: fallthrough
        case .uInt32: fallthrough
        case .uInt64: fallthrough
        case .unknown:
            DDLogError("Detected unsupported type \(attribute.config.descriptor.dataType); not editing.", tag: TAG)

        }
        
        guard let segueIdentifier = maybeSegueIdentifier else {
            DDLogWarn("Unable to determine segue to use for \(String(describing: attribute)); bailing.", tag: TAG)
            return
        }
        
        performSegue(withIdentifier: segueIdentifier, sender: self)
    }
    
}

// MARK: - Convenience Extensions -

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

