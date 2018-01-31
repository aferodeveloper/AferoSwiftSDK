//
//  DeviceProfile.swift
//  iTokui
//
//  Created by Tony Myles on 2/14/15.
//  Copyright (c) 2015 Kiban Labs, Inc. All rights reserved.
//

import Foundation

import CocoaLumberjack

public typealias LabelPresentable = String
public typealias LabelSizePresentable = String
public typealias URIPresentable = String

public protocol LayerImagePresentable: CustomDebugStringConvertible {
    var URI: URIPresentable { get }
    var cardURI: URIPresentable? { get }
    var imageSize: String? { get }

}

public func ==<T: LayerImagePresentable>(lhs: T?, rhs: T?) -> Bool {
    
    if let lhs = lhs, let rhs = rhs {
        return lhs.URI == rhs.URI && lhs.cardURI == rhs.cardURI && lhs.imageSize == rhs.imageSize
    }

    if lhs == nil && rhs == nil {
        return true
    }
    
    return false
}

public extension LayerImagePresentable {
    
    var URL: Foundation.URL? {
        return Foundation.URL(string: URI)
    }
    
    var cardURL: Foundation.URL? {
        guard let cardURI = cardURI else { return nil }
        return Foundation.URL(string: cardURI)
    }
}

public protocol LayerPresentable: CustomDebugStringConvertible {
    
    /// The number of URIs available
    var count: Int { get }
    
    /// Return the URI at the given index, otherwise an optional default.
    subscript(URI index: Int?) -> URIPresentable? { get }
    subscript(layer index: Int?) -> LayerImagePresentable? { get }
}

public extension LayerPresentable {
    
    var layerImagePresentables: [LayerImagePresentable] {
        return (0..<count).map {
            (index: Int) -> LayerImagePresentable? in self[layer: index]
            }.filter { $0 != nil }.map { $0! }
    }
    
    var imageURLs: [URL]  {
        return layerImagePresentables.map { $0.URL }.filter { $0 != nil }.map { $0! }
    }
    
    var scaledImageURLs: [URL] {

        var scaleURLComponent = "/3x/"
        let scaleURLPlaceholder = "/3x/"
        
        switch(UIScreen.main.nativeScale) {
        case 1..<2:
            scaleURLComponent = "/1x/"
        case 2..<3:
            scaleURLComponent = "/2x/"
        default:
            scaleURLComponent = "/3x/"
        }
        
        return imageURLs.map {
            (url: URL) -> URL? in
            let urlString = url.absoluteString.replacingOccurrences(of: scaleURLPlaceholder, with: scaleURLComponent)
            return URL(string: urlString) ?? nil
            }.filter { $0 != nil }.map { $0! }
    }
    
}

public typealias GaugeTypePresentable = String

public protocol GaugePresentable: CustomDebugStringConvertible {
    
    /// The label text for this gauge
    var label: LabelPresentable? { get }
    
    /// The label size indicator
    var labelSize: LabelSizePresentable? { get }
    
    /// The type of the gauge
    var type: GaugeTypePresentable? { get }
    
    /// The graphical representation of the gauge
    var icon: LayerPresentable? { get }
    
    /**
    Produces a function which takes an optional argument which can dereference subscripts to
    attributes, as well as an initial `[String: Object]` configuration, and produces a possibly
    transformed `[String: Object]` configuration based upon the input param.
    
    - parameter initial: A `[String: Any]` which represents defaults for the transformation.
    */
    func displayRulesProcessor<C: Hashable & SafeSubscriptable>
        (_ initial: [String: Any]?) -> ((C?)->[String: Any]) where C.Value == AttributeValue, C.Key == Int
}

public extension GaugePresentable {
    
    var imageURLs: [URL] {
        return icon?.imageURLs ?? []
    }
    
    var scaledImageURLs: [URL] {
        return icon?.scaledImageURLs ?? []
    }
}

public typealias ControlIdPresentable = Int

public protocol GroupPresentable: CustomDebugStringConvertible {
    
    /// The `GaugePresentable` that should be used to represent this
    /// group in the UI
    var display: GaugePresentable { get }

    /// The number of `ControlPresentables` in the group
    var controlCount: Int { get }
    
    /// Get the id for a control at the given index, if any.
    subscript(control index: Int?) -> ControlIdPresentable? { get }
    
    /// Get the control for a given index, if any
    subscript(controlId index: ControlIdPresentable?) -> ControlPresentable? { get }
    
    /// The number of sub-`GroupPresentables` in this group
    var groupCount: Int { get }
    
    /// Get the `GroupPresentable` at the given index, if any.
    subscript(group index: Int?) -> GroupPresentable? { get }
    
    /// The `LabelPresentable` for this group
    var label: LabelPresentable? { get }
}

public protocol AttributeOptionPresentable {
    var flags: DeviceProfile.Presentation.Flags { get }
    var label: LabelPresentable? { get }
    var rangeOptionsPresentable: RangeOptionsPresentable? { get }
    var valueOptionsPresentable: [ValueOptionPresentable] { get }
    var valueOptionsMap: ValueOptionsMap { get }
}

public extension AttributeOptionPresentable {
    var isLocallySchedulable: Bool { return flags.contains(.LocalSchedulable) }
    var isPrimaryOperation: Bool { return flags.contains(.PrimaryOperation) }
}


public typealias ValueOptionApplyPresentable = [String: Any]
public typealias ValueOptionMatchPresentable = String
public typealias ValueOptionsMap = [ValueOptionMatchPresentable: ValueOptionApplyPresentable]

/// Represents a set of distinct, discrete values for an attribute state
public protocol ValueOptionPresentable {

    /// What characteristics to apply to the attribute state if this
    /// option is selected.
    
    var apply: ValueOptionApplyPresentable { get }

    /// The value the option should match
    var match: ValueOptionMatchPresentable { get }
}

public typealias RangeOptionsUnitLabelPresentable = String

/// Represents a range of available options for a ControlPresentable
/// The `min`, `max`, and `step` properties are AttributeValues which
/// are guaranteed to be mutually comparable.
// TODO: actually guarantee this :)

public protocol RangeOptionsPresentable: CustomDebugStringConvertible {

    /// The minimum value to present.
    var min: String { get }
    
    /// The maximum value to present
    var max: String { get }
    
    /// The step by which ticks, etc should be separated
    var step: String { get }

    /// Struct that can handle subscripting over the range options using the given type.
    func subscriptor(_ dataType: AferoAttributeDataType) -> RangeOptionsSubscriptor
    
    /// The unit lablel, if any, to present
    var unitLabel: RangeOptionsUnitLabelPresentable? { get }
}

public typealias ControlTypePresentable = String
public typealias AttributeIdPresentable = Int

/// Represents an individual control

public protocol ControlPresentable: CustomDebugStringConvertible {
    
    /// The id of the control
    var id: Int { get }
    
    /// The type of the control
    var type: ControlTypePresentable { get }
    
    /// The `Set` of keys available for attributes. Values are suitable
    /// for subscripting the control to get attribute IDs back.
    var attributeKeys: Set<String> { get }
    
    var attributeIds: Set<Int> { get }

    /// A map of symbolic names to attribute IDs
    var attributeMap: [String: Int]? { get }
    
    /// Get an attribute ID for the given `key`. If the key is a member
    /// of `attributeKeys`, will return non-nil. Otherwise, nil.
    
    subscript(key: String?) -> AttributeIdPresentable? { get }
    
    var displayRules: DisplayRules { get }
    
    /**
    Produces a function which takes an optional argument which can dereference subscripts to
    attributes, as well as an initial `[String: Object]` configuration, and produces a possibly
    transformed `[String: Object]` configuration based upon the input param.
    
    - parameter initial: A `[String: Any]` which represents defaults for the transformation.
    */
    
    func displayRulesProcessor<C: Hashable & SafeSubscriptable>
        (_ initial: [String: Any]?) -> ((C?)->[String: Any]) where C.Value == AttributeValue, C.Key == Int
}

public extension DeviceProfile {
    
    typealias AttributeConfig = (descriptor: DeviceProfile.AttributeDescriptor, presentation: DeviceProfile.Presentation.AttributeOption?)
    
    @available(*, deprecated, message: "Use attributeConfig(for:on:) instead.")
    func attributeConfig(_ id: Int, deviceId: String? = nil) -> AttributeConfig? {
        return attributeConfig(for: id, on: deviceId)
    }
    
    func attributeConfig(for attributeId: Int, on deviceId: String? = nil) -> AttributeConfig? {

        // Note that we don't use attributeConfigs(on:isIncluded:) here, because we
        // can index directly into attributes using attributeId.
        
        guard let descriptor = descriptor(for: attributeId) else {
            return nil
        }
        
        return (descriptor: descriptor, presentation: presentation(deviceId)?[attributeId])
    }
    
    func attributeConfig(for semanticType: String, on deviceId: String? = nil) -> AttributeConfig? {
        return attributeConfigs(on: deviceId) { $0.descriptor.semanticType == semanticType }.first
    }
    
    /// Returns attributeConfigs filtered by `isIncluded`.
    /// - parameter isIncluded: The predicate to use for filtering configs. If unspecified, defaults to `{ _ in true }`, therefore
    ///                         including all configs in the result.
    /// - returns: A `LazyCollection<[AttributeConfig]>` which matches all results.
    
    func attributeConfigs(on deviceId: String? = nil, isIncluded: @escaping (AttributeConfig)->Bool = { _ in true }) -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], AttributeConfig>> {
        
        let ret = descriptors()
            .map {
            descriptor in
                return (descriptor: descriptor, presentation: self.presentation(deviceId)?[descriptor.id])
        }.filter(isIncluded)
        return ret
    }

    func attributeConfigs(on deviceId: String? = nil, withIdsIn range: ClosedRange<Int>) -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], AttributeConfig>> {
        return attributeConfigs(on: deviceId) { range.contains($0.descriptor.id) }
    }
    
    func attributeConfigs(on deviceId: String? = nil, withIdsIn platformAttributeRange: AferoPlatformAttributeRange) -> LazyFilterCollection<LazyMapCollection<[DeviceProfile.AttributeDescriptor], AttributeConfig>> {
        return attributeConfigs(on: deviceId, withIdsIn: platformAttributeRange.range)
    }
    
}

/**
Describes a Kiban device and its attributes.
*/

public class DeviceProfile: CustomDebugStringConvertible, Equatable {

    public var debugDescription: String {
        return "<DeviceProfile> id: \(String(reflecting: id)) deviceType: \(String(reflecting: deviceType)) primaryOperation: \(String(reflecting: primaryOperationAttribute)) summaryAttribute: \(String(reflecting: gaugeSummaryAttribute)) services: \(services) attributes: \(attributes) presentation: \(String(reflecting: presentation))"
    }
    
    public var CoderKeyDeviceType: String   { return "deviceType" }
    public var CoderKeyProfileId: String    { return "profileId" }
    public var CoderKeyServices: String     { return "services" }
    public var CoderKeyPresentation: String { return "presentation" }
    public var CoderKeyPresentationOverrideMap: String { return "presentationOverrideMap" }
    public var CoderKeyDeviceTypeId: String { return "deviceTypeId" }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            CoderKeyServices: services.JSONDict,
            CoderKeyPresentationOverrideMap: presentationOverrideMap.JSONDict,
            ]
        
        if let id = id {
            ret[CoderKeyProfileId] = id
        }
        
        if let deviceType = deviceType {
            ret[CoderKeyDeviceType] = deviceType
        }
        
        if let presentation = presentation {
            ret[CoderKeyPresentation] = presentation.JSONDict
        }
        
        if let deviceTypeId = deviceTypeId {
            ret[CoderKeyDeviceTypeId] = deviceTypeId
        }
        
        return ret
        
    }
    
    public required init(id: String? = nil, deviceType: String? = nil, attributes: [Int: AttributeDescriptor] = [:]) {
        self.id = id
        self.deviceType = deviceType
        self.attributes = attributes
    }
    
    public convenience init(id: String? = nil, deviceType: String? = nil, attributes: [AttributeDescriptor] = []) {

        self.init(id: id, deviceType: deviceType, attributes: attributes.reduce([:]) {
            curr, next in
            var ret = curr
            ret[next.id] = next
            return ret
            })
        
    }
    
    public required init?(json: AferoJSONCodedType?) {
        
        // Note that self.id is coming from the "profileId" key,
        // NOT "id".
        
        if let json = json as? AferoJSONObject {
            
            id = json[CoderKeyProfileId] as? String
            deviceType = json[CoderKeyDeviceType] as? String
            deviceTypeId = json[CoderKeyDeviceTypeId] as? String
            
            presentation = |<(json[CoderKeyPresentation])
            
            self.presentationOverrideMap = (json[CoderKeyPresentationOverrideMap] as? [String: Any])?.reduce(presentationOverrideMap) {
                (curr: [String: DeviceProfile.Presentation], next: (String, AferoJSONCodedType)) -> [String: DeviceProfile.Presentation]  in
                var ret = curr
                guard let override: DeviceProfile.Presentation = |<next.1 else { return ret }
                ret[next.0] = override
                return ret
                } ?? self.presentationOverrideMap
            
            if let services: [Service] = |<(json[CoderKeyServices] as? [AnyObject]) {
                self.services = services
            }
            
            for svc in services {
                for att in svc.attributes {
                    self.attributes[att.id] = att
                }
            }
            
            // Lastly, "augment" the presentation if necessary.
            
            if let jsonFile =
                deviceType?.lowercased().replacingOccurrences(of: " ", with: "") {
                
                do {
                    if
                        let fixture = try ResourceUtils.readJson(named: jsonFile),
                        let presentation: DeviceProfile.Presentation = |<fixture {
                        DDLogInfo("Attaching local presentation info for deviceType \(String(reflecting: deviceType)): \(presentation)")
                        self.presentation = presentation
                    }
                } catch {
                    DDLogVerbose("No local presentation JSON resource \(jsonFile).json: \(error)")
                }
        }
        
        } else {
            return nil
        }
    }

    fileprivate(set) public var id: String?
    fileprivate(set) public var deviceType: String?
    fileprivate(set) public var deviceTypeId: String?
    
    fileprivate(set) public var gaugeSummaryAttribute: AttributeDescriptor?
    fileprivate(set) public var services: [Service] = []

    // MARK: Attribute Descriptors and Filters
    fileprivate(set) public var attributes: [Int: AttributeDescriptor] = [:]
    
    fileprivate var _semanticTypeDescriptorMap: [String: [AttributeDescriptor]]! = [:]
    
    var semanticTypeDescriptorMap: [String: [AttributeDescriptor]] {
        
        if let ret = _semanticTypeDescriptorMap { return ret }
        
        _semanticTypeDescriptorMap = attributes.reduce([:]) {
            curr, next in
            var ret: [String: [AttributeDescriptor]] = curr ?? [:]
            
            guard let semanticType = next.1.semanticType else { return curr }
            
            var arr: [AttributeDescriptor]
            
            if let existing = ret[semanticType] {
                arr = existing
            } else {
                arr = []
            }
            
            arr.append(next.1)
            ret[semanticType] = arr
            return ret
        }
        
        return _semanticTypeDescriptorMap
        
    }
    
    fileprivate var attributeOperationMap: [AferoAttributeOperations: Set<AttributeDescriptor>] = [:]
    
    /// All attributes matching the given operation type
    public func attributesForOperation(_ operation: AferoAttributeOperations) -> Set<AttributeDescriptor> {
        
        guard let ret = attributeOperationMap[operation] else {
            let attrs = Set(attributes.values.filter {
                $0.operations.intersection(operation).rawValue != 0
            })
            attributeOperationMap[operation] = attrs
            return attrs
        }
        
        return ret
    }
    
    /// All readable attributes for this profile
    public var readableAttributes: Set<AttributeDescriptor> {
        return attributesForOperation(.Read)
    }
    
    lazy public var readableAttributeIds: Set<Int> = {
        return Set(self.readableAttributes.map { $0.id })
    }()
    
    public var hasReadableAttributes: Bool {
        return readableAttributes.count > 0
    }
    
    /// Whether this profile has at least one readable attribute
    public var hasPresentableReadableAttributes: Bool {
        
        return groupsForOperation(.Read).count > 0
    }

    /// All writable attributes for this profile
    public var writableAttributes: Set<AttributeDescriptor> {
        return attributesForOperation(.Write)
    }
    
    lazy public var writableAttributeIds: Set<Int> = {
        return Set(self.writableAttributes.map { $0.id })
    }()
    
    public var hasWritableAttributes: Bool {
        return writableAttributes.count > 0
    }
    
    /// Whether this profile has at least one writable attribute
    public var hasPresentableWritableAttributes: Bool {
        return groupsForOperation(.Write).count > 0
    }
    
    @available(*, deprecated, message: "Use descriptor(for:Int) instead.")
    public subscript (attributeId: Int) -> AttributeDescriptor? {
        get { return descriptor(for: attributeId) }
    }
    
    /// Return a lazy collection of all attribute descriptors matching the given predicate.
    /// - parameter isIncluded: The predicate used to indicate whether or not a descriptor
    ///                         should be included.
    /// - returns: A `LazyCollection<[AttributeDescriptor]>` which contains all
    ///            of the attributes in this profile filtered by `isIncluded`.
    
    public func descriptors(isIncluded: (AttributeDescriptor)->Bool  = { _ in return true})
        -> LazyCollection<[AttributeDescriptor]> {
            return attributes.values.filter(isIncluded).lazy
    }
    
    /// Get the `AttributeDescriptor` for the given `attributeId`, if any.
    /// - parameter attributeId: The attributeId for which to get the descriptor.
    ///
    /// > **NOTE**
    /// >
    /// > Attribute ID **0** is special; this refers to the `primaryOperationAttribute`,
    /// > if one exists. So, if the `id` of the `primaryOperationAttribute` is `5`, then
    /// > `descriptor(for: 0) == descriptor(for: 5)`
    
    public func descriptor(for attributeId: Int) -> AttributeDescriptor? {
        if attributeId == 0 {
            return self.primaryOperationAttribute
        }
        return self.attributes[attributeId]
    }
    
    public var primaryOperationAttribute: AttributeDescriptor? {
        if let id = self.presentation?.primaryOperationId {
            return self.attributes[id]
        }
        return nil
    }
    
    @available(*, deprecated, message: "Use descriptors(for:String) instead")
    public subscript (semanticType: String) -> [AttributeDescriptor] {
        get { return Array(descriptors(for: semanticType)) }
    }
    
    /// Return the first `AttributeDescriptor` matching the given `semanticType`.
    /// - parameter semanticType: The `semanticType` for which to search.
    ///
    /// > **NOTE**
    /// >
    /// > While schema-wise these can be non-unique, as a practical matter they have to be,
    /// > since this is enforced by APE, and is transformed into a unique `#define`
    /// > in `device_description.h`, used by firmware developers.
    
    public func descriptor(for semanticType: String) -> AttributeDescriptor? {
        return descriptors(for: semanticType).first
    }
    
    /// Get the `AttributeDescriptor`s matching the given `semanticType`.
    /// - parameter semanticType: The `semanticType` for which to search.
    ///
    /// > **NOTE**
    /// >
    /// > While schema-wise these can be non-unique, as a practical matter they have to be,
    /// > since this is enforced by APE, and is transformed into a unique `#define`
    /// > in `device_description.h`, used by firmware developers.
    
    public func descriptors(for semanticType: String) -> LazyCollection<[AttributeDescriptor]> {
        return descriptors(isIncluded: { $0.semanticType == semanticType })
    }
    
    // MARK: Presentation convenience accessors
    
    func clearCaches() {
        attributeIdValueOptionProcessors.removeAll()
        controlsForAttributeIdCache.removeAll()
        groupsForControlIdCache.removeAll()
        groupIndicesForOperationCache.removeAll()
        groupsForOperationCache.removeAll()
        groupIndicesForControlIdCache.removeAll()
    }
    
    public typealias ValueOptionProcessor = (AttributeValue?) -> [String: Any]
    
    var attributeIdValueOptionProcessors: [Int: ValueOptionProcessor] = [:]
    
    func valueOptionProcessor(for attributeId: Int?) -> ValueOptionProcessor? {
        
        guard let attributeId = attributeId else { return nil }
        
        if let ret = attributeIdValueOptionProcessors[attributeId] {
            return ret
        }
        
        guard let ret = attributeConfig(for: attributeId)?.presentation?.valueOptions.displayRulesProcessor() else {
            return nil
        }
        
        attributeIdValueOptionProcessors[attributeId] = ret
        return ret
    }

    fileprivate var groupIndicesForControlIdCache: [Int: [Int]] = [:]
    
    public func groupIndicesForControl(_ control: Presentation.Control) -> [Int] {
        
        if let ret = groupIndicesForControlIdCache[control.id] { return ret }
        
        let ret: [Int]? = presentation?.groups?.enumerated().filter {
            $1.controlIds?.contains(control.id) ?? false
            }.map { (index: Int, element: DeviceProfile.Presentation.Group) -> Int in return index }
        
        groupIndicesForControlIdCache[control.id] = ret
        
        return ret ?? []
    }

    fileprivate var groupsForControlIdCache: [Int: [Presentation.Group]] = [:]
    
    /// Return a list of controls referencing the given ProfileControl
    public func groupsForControl(_ control: Presentation.Control) -> [Presentation.Group] {
        
        if let ret = groupsForControlIdCache[control.id] {
            return ret
        }
        
        let ret = presentation?.groups?.filter {
            $0.controlIds?.contains(control.id) ?? false
            } ?? []
        
        groupsForControlIdCache[control.id] = ret
        
        return ret
    }
    
    public func attributeHasControls(_ attributeId: Int) -> Bool {
        return controlsForAttribute(attributeId).count > 0
    }
    
    /// Return a list of controls referencing the given AttributeDescriptor.
    public func controlsForAttribute(_ attribute: AttributeDescriptor) -> [Presentation.Control] {
        return controlsForAttribute(attribute.id)
    }

    fileprivate var controlsForAttributeIdCache: [Int: [Presentation.Control]] = [:]
    
    public func controlsForAttribute(_ attributeId: Int) -> [Presentation.Control] {
        
        if let ret = controlsForAttributeIdCache[attributeId] { return ret }
        
        let ret: [Presentation.Control] = (presentation?.controls ?? []).filter {
            $0.attributeIds.contains(attributeId)
        }
        
        controlsForAttributeIdCache[attributeId] = ret
        
        return ret
    }

    fileprivate var groupIndicesForOperationCache: [AferoAttributeOperations: [Int]] = [:]

    public func groupIndicesForOperation(_ operations: AferoAttributeOperations) -> [Int] {
        
        if let ret = groupIndicesForOperationCache[operations] { return ret }
        
        let indices = attributesForOperation(operations).flatMap {
            (attribute: AttributeDescriptor) -> [Presentation.Control] in
            DDLogVerbose("Found attibute \(attribute) for operation \(operations)")
            return self.controlsForAttribute(attribute)
            }.flatMap {
                (control: Presentation.Control) -> [Int] in
                DDLogVerbose("Found control: \(control) for operation \(operations)")
                let ret = self.groupIndicesForControl(control)
                DDLogVerbose("Found groups \(ret) for control \(control)")
                return ret
        }
        
        let ret = Set(indices).sorted()
        groupIndicesForOperationCache[operations] = ret
        return ret
        
    }

    fileprivate var groupsForOperationCache: [AferoAttributeOperations: [Presentation.Group]] = [:]
    
    /// Return a list of groups which have controls which reference at least one attribute which
    /// matches the given operation.
    
    public func groupsForOperation(_ operations: AferoAttributeOperations) -> [Presentation.Group] {
        
        if let ret = groupsForOperationCache[operations] { return ret }

        let ret: [Presentation.Group] = attributesForOperation(operations).flatMap {
            (attribute: AttributeDescriptor) -> [Presentation.Control] in
            DDLogVerbose("Found attibute \(attribute) for operation \(operations)")
            return self.controlsForAttribute(attribute)
            }.flatMap {
                (control: Presentation.Control) -> [Presentation.Group] in
                DDLogVerbose("Found control: \(control) for operation \(operations)")
                let ret = self.groupsForControl(control)
                DDLogVerbose("Found groups \(ret) for control \(control)")
                return ret
        }
        
        groupsForOperationCache[operations] = ret
        
        return ret
    }
    
    public var presentationOverrideMap: [String: Presentation] = [:]
    
    fileprivate var presentation: Presentation? = nil
    
    public func presentation(_ deviceId: String? = nil) -> Presentation? {
        guard let deviceId = deviceId else { return presentation }
        guard let presentationOverride = presentationOverrideMap[deviceId] else { return presentation }
        DDLogDebug("Will use presentationOverrideMap for device \(deviceId): \(presentationOverrideMap)")
        return presentationOverride
    }
    
    // MARK: - DeviceProfile.Presentation
    
    /**
    Presentation definition for a Kiban device.
    */
    
    public struct Presentation: CustomDebugStringConvertible, Equatable {
        
        public var debugDescription: String {
            return "<Presentation> gauge: \(gauge) groups: \(String(reflecting: groups)) controls: \(String(reflecting: controls))"
        }
        
        public var label: LabelPresentable? = nil
        
        public var displayRules: DisplayRules = []

        // MARK: AttributeOption access
        
        public var attributeOptions: [Int: AttributeOption] = [:]
        public subscript (attributeId: Int) -> AttributeOption? {
            get {
                if attributeId == 0 {
                    return self.primaryOperationOption
                }
                return self.attributeOptions[attributeId]
            }
        }
        
        public var gauge: Gauge
        public var groups: [Group]? = []
        
        /// The AttributeOption to be used as the primary operation.
        
        public var primaryOperationId: Int? {
            return Array(self.attributeOptions).filter { $0.1.isPrimaryOperation }.first?.0
        }
        
        public var primaryOperationOption: AttributeOption? {
            return Array(self.attributeOptions.values).filter { $0.isPrimaryOperation }.first
        }

        public var controls: [Control]? = []
        public var controlRegistry: [ControlIdPresentable: ControlPresentable] = [:]
        
        public subscript(controlId id: ControlIdPresentable?) -> ControlPresentable? {
            if let id = id { return controlRegistry[id] }
            return nil
        }
        
        init(label: LabelPresentable? = nil, attributeOptions: [Int: AttributeOption] = [:], gauge: Gauge, groups: [Group]? = [], controls: [Control]? = [], displayRules: DisplayRules? = nil) {
            self.label = label
            self.attributeOptions = attributeOptions
            self.gauge = gauge
            self.controls = controls
            self.controlRegistry = Dictionary(controls?.map() { return ($0.id, $0) })

            if let displayRules = displayRules {
                self.displayRules = displayRules
            }
            
            let groups = groups?.map() { (g: Group) -> Group in var ret = g; ret.presentation = self; return ret }
            self.groups = groups
        }
        
        public func displayRulesProcessor<
            C: Hashable & SafeSubscriptable>(_ initial: [String: Any]? = nil) -> ((C?)->[String: Any])
            where C.Value == AttributeValue, C.Key == Int
        {
            
            return DisplayRulesProcessor.MakeProcessor(
                initial ?? [:],
                rules: displayRules,
                operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
                integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue  }
            )
        }

        public struct Flags: OptionSet {
            
            // Yes, this is what a bitfield looks like in Swift :(
            
            public typealias RawValue = UInt
            
            fileprivate var value: RawValue = 0
            
            // MARK: NilLiteralConvertible
            
            public init(nilLiteral: Void) {
                self.value = 0
            }
            
            // MARK: RawLiteralConvertible
            
            public init(rawValue: RawValue) {
                self.value = rawValue
            }
            
            static func fromRaw(_ raw: UInt) -> Flags {
                return self.init(rawValue: raw)
            }
            
            public var rawValue: RawValue { return self.value }
            
            
            // MARK: BooleanType
            
            public var boolValue: Bool {
                return value != 0
            }
            
            // MARK: BitwiseOperationsType
            
            public static var allZeros: Flags {
                return self.init(rawValue: 0)
            }
            
            // MARK: Actual values
            
            public static func fromMask(_ raw: UInt) -> Flags {
                return self.init(rawValue: raw)
            }
            
            public init(bitIndex: RawValue) {
                self.init(rawValue: 0x01 << bitIndex)
            }
            
            /// The associated attribute is considered a "primary operation" of the device,
            /// meaning that its state can be reflected, and interacted with, in the gauge.
            public static var PrimaryOperation: Flags { return self.init(bitIndex: 0) }
            
            /// The associated attribute can be included in local/offline schedules.
            public static var LocalSchedulable: Flags { return self.init(bitIndex: 1) }
            
        }
        
        public struct AttributeOption: AttributeOptionPresentable, CustomDebugStringConvertible {
            
            public var debugDescription: String {
                return "<AttributeOptions> flags: \(flags) label: \(String(reflecting: label)) rangeOptions: \(String(reflecting: rangeOptions)) valueOptions: \(valueOptions)"
            }
            
            public var flags: Flags = []
            public var label: LabelPresentable? = nil
            
            public var rangeOptions: RangeOptions? = nil
            public var rangeOptionsPresentable: RangeOptionsPresentable? { return rangeOptions }
            
            public var valueOptionsMap: ValueOptionsMap
            public var valueOptions: [ValueOption] = []
            public var valueOptionsPresentable: [ValueOptionPresentable] { return self.valueOptions.map { $0 as ValueOptionPresentable } }
            
            init(label: String? = nil, rangeOptions: RangeOptions? = nil, valueOptions: [ValueOption] = [], flags: Flags = []) {
                self.label = label
                self.rangeOptions = rangeOptions
                self.valueOptions = valueOptions
                self.valueOptionsMap = valueOptions.valueOptionsMap
                self.flags = flags
            }
            
            public struct ValueOption: ValueOptionPresentable, Equatable, CustomDebugStringConvertible {
                
                public var debugDescription: String {
                    return "<ValueOption> match: \(match) apply: \(apply)"
                }
                
                public var match: ValueOptionMatchPresentable
                public var apply: ValueOptionApplyPresentable
                
                public init(match: ValueOptionMatchPresentable, apply: ValueOptionApplyPresentable) {
                    self.match = match
                    self.apply = apply
                }
                
            }
            
            public struct RangeOptions: RangeOptionsPresentable, Equatable {
                
                public var debugDescription: String {
                    return "<RangeOptions> min: \(min) max: \(max) displayStep: \(step) unitLabel: \(String(reflecting: unitLabel))"
                }
                
                public var min: String
                public var max: String
                public var step: String
                public var unitLabel: RangeOptionsUnitLabelPresentable?
                
                public init(min: String, max: String, step: String, unitLabel: String?) {
                    self.min = min
                    self.max = max
                    self.step = step
                    self.unitLabel = unitLabel
                }
                
            }


        }
        
        public struct Control: ControlPresentable, Equatable {
            
            public var debugDescription: String {
                return "<Control> id: \(id) controlType: \(type) attributeMap: \(String(reflecting: attributeMap)) displayRules: \(displayRules)"
            }
            
            public var id: Int
            
            public var type: ControlTypePresentable
            
            // Attributes
            
            public var attributeMap: [String: Int]? = [:]
            
            /// A `Set` of attribute keys this `Control` references.
            public var attributeKeys: Set<String>
            
            /// A `Set` of attribute ids this `Control` references.
            public var attributeIds: Set<Int>
            
            public subscript(key: String?) -> AttributeIdPresentable? {
                if let key = key {
                    return attributeMap?[key]
                }
                return nil
            }
            
            // RangeOptions

            public var displayRules: DisplayRules = []

            init(id: Int, type: ControlTypePresentable, attributeMap: [String: Int]? = [:], displayRules: DisplayRules? = nil) {
                self.id = id
                self.type = type
                self.attributeMap = attributeMap
                self.attributeIds = Set(attributeMap?.values.compactMap { $0 } ?? [])
                self.attributeKeys = Set(attributeMap?.keys.compactMap { $0 } ?? [])
                self.displayRules = displayRules ?? []
            }
            
            public func displayRulesProcessor<
                C: Hashable & SafeSubscriptable>(_ initial: [String: Any]? = nil) -> ((C?)->[String: Any])
                where C.Value == AttributeValue, C.Key == Int
                 {
                    
                    return DisplayRulesProcessor.MakeProcessor(
                        initial ?? [:],
                        rules: self.displayRules ,
                        operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
                        integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue  }
                    )
            }
            
        }
        
        public struct Group: GroupPresentable, Equatable {
            
            public var debugDescription: String {
                return "<Group> gauge: \(gauge), label: \(String(reflecting: label)) controls: \(String(reflecting: controlIds))"
            }
            
            public var gauge: Gauge

            public var display: GaugePresentable {
                return self.gauge
            }

            public var label: LabelPresentable? = nil

            // Controls
            
            public var controlIds: [Int]? = nil
            
            public var controlCount: Int {
                return controlIds?.count ?? 0
            }
            
            public subscript(control index: Int?) -> ControlIdPresentable? {
                return controlIds?[safe: index]
            }
            
            public subscript(controlId id: ControlIdPresentable?) -> ControlPresentable? {
                return self.presentation?[controlId: id]
            }
            
            public var presentation: Presentation?
            
            // Groups
            
            public var groups: [Group]? = nil
            
            public var groupCount: Int {
                return groups?.count ?? 0
            }
            
            public subscript(group index: Int?) -> GroupPresentable? {
                return groups?[safe: index]
            }
            
            init(gauge: Gauge, label: String? = nil, controlIds: [Int]? = nil, groups: [Group]? = nil) {
                self.gauge = gauge
                self.label = label
                self.controlIds = controlIds
                self.groups = groups
            }
        }
        
        public struct Gauge: GaugePresentable, Equatable {
            
            public var debugDescription: String {
                return "<Gauge> foreground: \(String(reflecting: foreground)) background: \(String(reflecting: background))"
            }
            
            public var foreground: Layer?
            public var background: Layer?
            public var displayRules: DisplayRules? = []
            
            public var label: LabelPresentable?
            public var labelSize: LabelSizePresentable?
            public var type: GaugeTypePresentable?
            
            public var icon: LayerPresentable? {
                return foreground
            }
            
            init(type: GaugeTypePresentable? = nil, label: LabelPresentable? = nil, labelSize: LabelSizePresentable? = nil, foreground: Layer? = nil, background: Layer? = nil, displayRules: DisplayRules? = []) {
                self.type = type
                self.label = label
                self.labelSize = labelSize
                self.foreground = foreground
                self.background = background
                self.displayRules = displayRules
            }
            
            public func displayRulesProcessor<
                C: Hashable & SafeSubscriptable>(_ initial: [String: Any]? = nil) -> ((C?)->[String: Any])
                where C.Value == AttributeValue, C.Key == Int
                 {

                return DisplayRulesProcessor.MakeProcessor(
                    initial ?? [:],
                    rules: self.displayRules ?? [],
                    operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
                    integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue  }
                )
            }
            
        }
        
        /// Represents a foreground/background layer
        public struct Layer: LayerPresentable, Equatable {
            
            public var debugDescription: String {
                return "<Layer> images: \(images)"
            }
            
            /// The images that make up the layer. Multiple images imply animation.
            public var images: [LayerImage]
            
            public var count: Int {
                return images.count
            }
            
            public subscript(URI index: Int?) -> URIPresentable? {
                return self[layer: index]?.URI
            }
            
            public subscript(layer index: Int?) -> LayerImagePresentable? {
                return images[safe: index]
            }
            
            init(images: [LayerImage]) {
                self.images = images
            }
            
        }
        
        /// Represents a single image object in a foreground/background layer.
        public struct LayerImage: LayerImagePresentable, Equatable {
            
            public var debugDescription: String {
                return "<LayerImage> uri: \(URI)"
            }
            
            public var URI: URIPresentable
            public var cardURI: URIPresentable?
            public var imageSize: String?
            
            init(uri: URIPresentable, cardURI: URIPresentable? = nil, imageSize: String? = nil) {
                self.URI = uri
                self.cardURI = cardURI
                self.imageSize = imageSize
            }
        }

    }

    // MARK: - DeviceProfile.AttributeDescriptor
    
    public typealias AttributeDescriptor = AferoAttributeDescriptor

    // MARK: - DeviceProfile.Service
    
    public struct Service: CustomDebugStringConvertible, Equatable {
        
        public var debugDescription: String {
            return "<Service> id: \(id) attributes: \(attributes)"
        }
        
        fileprivate(set) public var id: Int = 0
        fileprivate(set) public var attributes: [AttributeDescriptor] = []
    }

}

extension Int8 {

    public static var maxValue: AttributeValue? {
        return AttributeValue(self.max)
    }
    
    public static var minValue: AttributeValue? {
        return AttributeValue(self.min)
    }
    
}

extension Int16 {
    
    public static var maxValue: AttributeValue? {
        return AttributeValue(self.max)
    }
    
    public static var minValue: AttributeValue? {
        return AttributeValue(self.min)
    }
    
}

extension Int32 {
    
    public static var maxValue: AttributeValue? {
        return AttributeValue(self.max)
    }
    
    public static var minValue: AttributeValue? {
        return AttributeValue(self.min)
    }
    
}

extension Int {
    
    public static var maxValue: AttributeValue? {
        return AttributeValue(self.max)
    }
    
    public static var minValue: AttributeValue? {
        return AttributeValue(self.min)
    }
    
}

extension Int64 {
    
    public static var maxValue: AttributeValue? {
        return AttributeValue(self.max)
    }
    
    public static var minValue: AttributeValue? {
        return AttributeValue(self.min)
    }
    
}

public extension AferoAttributeDataType {
    
    var maxValue: AttributeValue? {
        switch self {
            
        case .sInt8: return Int8.maxValue
        case .sInt16: return Int16.maxValue
        case .sInt32: return Int32.maxValue
        case .sInt64: return Int64.maxValue
        
        case .q1516: return .q1516(32_767.9999847412109375) // max is 2**m - 2**(-n)
        case .q3132: return .q1516(2_147_483_647.999999999767169) // max is 2**m - 2**(-n)
            
        default: return nil
        }
    }
    
    
    var minValue: AttributeValue? {
        switch self {
            
        case .sInt8: return Int8.minValue
        case .sInt16: return Int16.minValue
        case .sInt32: return Int32.minValue
        case .sInt64: return Int64.minValue
            
        case .q1516: return .q1516(-32_768.0) // min is -(2**m)
        case .q3132: return .q3132(-2_147_483_648.0) // min is -(2**m)

        default: return nil
        }
    }
    
}
public func ==(lhs: DeviceProfile.Presentation.Flags, rhs: DeviceProfile.Presentation.Flags) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

extension DeviceProfile.Presentation.Control: Hashable {
    
    public func hash(into h: inout Hasher) {
        h.combine(id)
        h.combine(type)
        h.combine(attributeMap)
    }

}

public func ==(lhs: DeviceProfile.Presentation.Control, rhs: DeviceProfile.Presentation.Control) -> Bool {

    let ret = lhs.id == rhs.id && lhs.type == rhs.type

    var lam: [String: Int] = [:]
    if let lham = lhs.attributeMap {
        lam = lham
    }
    
    var ram: [String: Int] = [:]
    if let rham = rhs.attributeMap {
        ram = rham
    }
    
    return ret && lam == ram
}

public func ==(lhs: DeviceProfile.Presentation.AttributeOption.ValueOption, rhs: DeviceProfile.Presentation.AttributeOption.ValueOption) -> Bool {
    return lhs.match == rhs.match
}

public func ==(lhs: DeviceProfile.Presentation.AttributeOption.RangeOptions, rhs: DeviceProfile.Presentation.AttributeOption.RangeOptions) -> Bool {
    return lhs.min == rhs.min && lhs.max == rhs.max && lhs.step == rhs.step && lhs.unitLabel == rhs.unitLabel
}

// MARK: Group Extensions and Operators

extension DeviceProfile.Presentation.Group: Hashable {

    public func hash(into h: inout Hasher) {
        h.combine(gauge)
        h.combine(label)
        h.combine(controlIds)
        h.combine(groups)
    }
    
}

public func ==(lhs: DeviceProfile.Presentation.Group, rhs: DeviceProfile.Presentation.Group) -> Bool {
    
    return lhs.gauge == rhs.gauge && lhs.label == rhs.label && lhs.controlIds == rhs.controlIds && lhs.presentation == rhs.presentation && lhs.groups == rhs.groups
}

// MARK: Gauge Extension and Operators

extension DeviceProfile.Presentation.Gauge: Hashable {
    
    public func hash(into h: inout Hasher) {
        h.combine(foreground)
        h.combine(background)
        h.combine(label)
        h.combine(type)
    }
    
}

public func ==(lhs: DeviceProfile.Presentation.Gauge, rhs: DeviceProfile.Presentation.Gauge) -> Bool {
    return lhs.foreground == rhs.foreground && lhs.background == rhs.background && lhs.label == rhs.label && lhs.type == rhs.type
}

// MARK: Layer extension and Operators

extension DeviceProfile.Presentation.Layer: Hashable {
    
    public func hash(into h: inout Hasher) {
        h.combine(images)
    }
}

public func ==(lhs: DeviceProfile.Presentation.Layer, rhs: DeviceProfile.Presentation.Layer) -> Bool {
    return lhs.images == rhs.images
}

// MARK: LayerImage extension and operators

extension DeviceProfile.Presentation.LayerImage: Hashable {

    public func hash(into h: inout Hasher) {
        h.combine(URI)
    }

}

public func ==(lhs: DeviceProfile.Presentation.LayerImage, rhs: DeviceProfile.Presentation.LayerImage) -> Bool {
    return lhs.URI == rhs.URI
}

// MARK: AttributeDescriptor extension and operators

extension DeviceProfile.AttributeDescriptor: Hashable {

    public func hash(into h: inout Hasher) {
        h.combine(id)
        h.combine(dataType)
        h.combine(semanticType)
    }
    
}

public func ==(lhs: DeviceProfile.AttributeDescriptor, rhs: DeviceProfile.AttributeDescriptor) -> Bool {
    return lhs.id == rhs.id && lhs.dataType == rhs.dataType && lhs.semanticType == rhs.semanticType
}

// MARK: Service extension and operators

extension DeviceProfile.Service: Hashable {
    
    public func hash(into h: inout Hasher) {
        h.combine(id)
        h.combine(attributes)
    }

}

public func ==(lhs: DeviceProfile.Service, rhs: DeviceProfile.Service) -> Bool {
    return lhs.id == rhs.id && lhs.attributes == rhs.attributes
}

// MARK: Profile extension and operators

extension DeviceProfile.Presentation: Hashable {
    
    public func hash(into h: inout Hasher) {
        h.combine(gauge)
        h.combine(groups)
        h.combine(controls)
    }
}

public func ==(lhs: DeviceProfile.Presentation, rhs: DeviceProfile.Presentation) -> Bool {
    return lhs.gauge == rhs.gauge && lhs.groups == rhs.groups && lhs.controls == rhs.controls
}

extension DeviceProfile: Hashable {

    public func hash(into h: inout Hasher) {
        h.combine(services)
        h.combine(primaryOperationAttribute)
        h.combine(presentation)
    }
    
}

public func ==(lhs: DeviceProfile, rhs: DeviceProfile) -> Bool {
    return lhs.id == rhs.id &&
        lhs.primaryOperationAttribute == rhs.primaryOperationAttribute &&
        lhs.services == rhs.services &&
        lhs.attributes == rhs.attributes &&
        lhs.presentation == rhs.presentation
}

// MARK: - AferoJSONCoding Extensions


extension DeviceProfile.Presentation.Flags: AferoJSONCoding {
    
    static var CoderValuePrimaryOperation: String { return "primaryOperation" }
    static var CoderValueLocalSchedulable: String { return "localSchedulable" }
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String] = []
        
        if self.contains(.PrimaryOperation) {
            ret.append(type(of: self).CoderValuePrimaryOperation)
        }
        
        if self.contains(.LocalSchedulable) {
            ret.append(type(of: self).CoderValueLocalSchedulable)
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        var rawValue: RawValue = 0
        
        if let json = json as? [String] {
            for flag in json {
                switch(flag) {
                case type(of: self).CoderValuePrimaryOperation:
                    rawValue |= DeviceProfile.Presentation.Flags.PrimaryOperation.rawValue
                case type(of: self).CoderValueLocalSchedulable:
                    rawValue |= DeviceProfile.Presentation.Flags.LocalSchedulable.rawValue
                default:
                    break
                }
            }
        }
        
        self.init(rawValue: rawValue)
    }
}

extension DeviceProfile: AferoJSONCoding { }

extension DeviceProfile.Presentation: AferoJSONCoding {

    // Zhal. These are static lets b/c we can't get to computed ivars
    // prior to initializing all of our required fields.
    
    static let CoderKeyGauge = "gauge"
    static let CoderKeyGroups = "groups"
    static let CoderKeyControls = "controls"
    static let CoderKeyAttributeOptions = "attributeOptions"
    static let CoderKeyLabel = "label"
    static let CoderKeyDisplayRules = "displayRules"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: AferoJSONObject = [
            type(of: self).CoderKeyGauge: gauge.JSONDict!,
            type(of: self).CoderKeyAttributeOptions: Dictionary(attributeOptions) {
                return ("\($0.0)", $0.1.JSONDict!)
            },
            type(of: self).CoderKeyDisplayRules:  displayRules,
        ]
        
        if let label = label {
            ret[type(of: self).CoderKeyLabel] = label
        }
        
        if let groups = groups {
            ret[type(of: self).CoderKeyGroups] = groups.map() { return $0.JSONDict! }
        }
        
        if let controls = controls {
            ret[type(of: self).CoderKeyControls] = controls.map() { return $0.JSONDict! }
        }

        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if let json = json as? AferoJSONObject {
            if let
                gauge: DeviceProfile.Presentation.Gauge = |<(json[type(of: self).CoderKeyGauge]),
                let attributeOptionsDict: [String: AferoJSONCodedType] = json[type(of: self).CoderKeyAttributeOptions] as? [String: AferoJSONCodedType] {
                    
                    let label = json[type(of: self).CoderKeyLabel] as? LabelPresentable
                    let attributeOptions: [Int: DeviceProfile.Presentation.AttributeOption] = Dictionary(attributeOptionsDict) {
                        if let
                            rk = Int($0.0),
                            let rv: DeviceProfile.Presentation.AttributeOption = |<$0.1 {
                                return (rk, rv)
                        }
                        return nil
                    }
                    
                    self.init(
                        label: label,
                        attributeOptions: attributeOptions,
                        gauge: gauge,
                        groups: |<(json[type(of: self).CoderKeyGroups] as? [[String: Any]]),
                        controls: |<(json[type(of: self).CoderKeyControls] as? [[String: Any]]),
                        displayRules: json[type(of: self).CoderKeyDisplayRules] as? DisplayRules
                    )
                
            } else {
                DDLogError("ERROR: Unable to decode DeviceProfile.Presentation: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Presentation.AttributeOption: AferoJSONCoding {
    
    static let CoderKeyLabel = "label"
    static let CoderKeyFlags = "flags"
    static let CoderKeyValueOptions = "valueOptions"
    static let CoderKeyRangeOptions = "rangeOptions"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: AferoJSONObject = [
            type(of: self).CoderKeyFlags: flags.JSONDict!,
            type(of: self).CoderKeyValueOptions: valueOptions.map { $0.JSONDict! },
        ]
        
        if let rangeOptions = rangeOptions {
            ret[type(of: self).CoderKeyRangeOptions] = rangeOptions.JSONDict!
        }
        
        if let label = label {
            ret[type(of: self).CoderKeyLabel] = label
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        guard let json = json as? AferoJSONObject else { return nil }
        
        self.flags = |<(json[type(of: self).CoderKeyFlags]) ?? []
        self.label = json[type(of: self).CoderKeyLabel] as? String
        self.valueOptions = |<(json[type(of: self).CoderKeyValueOptions] as? [AnyObject]) ?? []
        self.valueOptionsMap = valueOptions.valueOptionsMap
        self.rangeOptions = |<(json[type(of: self).CoderKeyRangeOptions] as? [String: Any])
        
    }
}

extension DeviceProfile.Presentation.AttributeOption.ValueOption: AferoJSONCoding {
    
    static let CoderKeyMatch = "match"
    static let CoderKeyApply = "apply"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyMatch: match,
            type(of: self).CoderKeyApply: apply,
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? AferoJSONObject {
            if let
                match = json[type(of: self).CoderKeyMatch] as? ValueOptionMatchPresentable,
                let apply = json[type(of: self).CoderKeyApply] as? ValueOptionApplyPresentable {
                    self.init(match: match, apply: apply)
            } else {
                DDLogInfo("ERROR: Unable to decode DeviceProfile.Presentation.Control.ValueOption: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
    
}

extension DeviceProfile.Presentation.AttributeOption.RangeOptions: AferoJSONCoding {

    static let CoderKeyMinLegacy = "min"
    static let CoderKeyMin = "minValue"
    
    static let CoderKeyMaxLegacy = "max"
    static let CoderKeyMax = "maxValue"
    
    static let CoderKeyStepLegacy = "step"
    static let CoderKeyStep = "stepValue"
    static let CoderKeyUnitLabel = "unitLabel"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyMin: min,
            type(of: self).CoderKeyMax: max,
            type(of: self).CoderKeyStep: step,
            type(of: self).CoderKeyUnitLabel: unitLabel ?? "",
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        
        if let json = json as? AferoJSONObject {
            
            if
                
                let min = json[type(of: self).CoderKeyMin] as? String,
                let max = json[type(of: self).CoderKeyMax] as? String,
                let step = json[type(of: self).CoderKeyStep] as? String {
                    self.init(min: min, max: max, step: step, unitLabel: (json["unitLabel"] as? String))
                
            } else if

                // Legacy support
                
                let min = json[type(of: self).CoderKeyMinLegacy] as? NSNumber,
                let max = json[type(of: self).CoderKeyMaxLegacy] as? NSNumber,
                let step = json[type(of: self).CoderKeyStepLegacy] as? NSNumber {
                    self.init(min: min.stringValue, max: max.stringValue, step: step.stringValue, unitLabel: (json["unitLabel"] as? String))
                
            } else {
                DDLogInfo("ERROR: Unable to decode DeviceProfile.Presentation.Control.RangeOptions: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Presentation.Control: AferoJSONCoding {
    
    static let CoderKeyId = "id"
    static let CoderKeyControlType = "controlType"
    static let CoderKeyAttributeMap = "attributeMap"
    static let CoderKeyRangeOptions = "rangeOptions"
    static let CoderKeyDisplayRules = "displayRules"
    
    public var JSONDict: AferoJSONCodedType? {

        var ret: AferoJSONObject = [
            Swift.type(of: self).CoderKeyId: id,
            Swift.type(of: self).CoderKeyControlType: type,
            Swift.type(of: self).CoderKeyDisplayRules:  displayRules
        ]
        
        if let attributeMap = attributeMap {
            ret[Swift.type(of: self).CoderKeyAttributeMap] = attributeMap
        }
        
        return ret
    }
    
    public init?(json maybeJson: AferoJSONCodedType?) {
        
        guard let json = maybeJson as? AferoJSONObject else {
            DDLogError("ERROR: Unable to decode DeviceProfile.Presentation.Control: \(String(reflecting: maybeJson))")
            return nil
        }
        
        guard
            let id = json[Swift.type(of: self).CoderKeyId] as? Int,
            let type = json[Swift.type(of: self).CoderKeyControlType] as? String else {
                DDLogError("ERROR: Unable to decode DeviceProfile.Presentation.Control (missing id or type): \(json)")
                return nil
        }
        
        let maybeAttributeMap = json[Swift.type(of: self).CoderKeyAttributeMap] as? [String: Int]
        let maybeDisplayRules = json[Swift.type(of: self).CoderKeyDisplayRules] as? DisplayRules
        
        self.init(
            id: id,
            type: type,
            attributeMap: maybeAttributeMap,
            displayRules: maybeDisplayRules
        )

    }
    
}

extension DeviceProfile.Presentation.Group: AferoJSONCoding {

    static let CoderKeyGauge = "gauge"
    static let CoderKeyLabel = "label"
    static let CoderKeyControls = "controls"
    static let CoderKeyGroups = "groups"
    
    public var JSONDict: AferoJSONCodedType? {

        var ret: AferoJSONObject = [
            type(of: self).CoderKeyGauge: gauge.JSONDict!
        ]
        
        if let label = label {
            ret[type(of: self).CoderKeyLabel] = label
        }
        
        if let controlIds = controlIds {
            ret[type(of: self).CoderKeyControls] = controlIds
        }
        
        if let groups = groups {
            ret[type(of: self).CoderKeyGroups] = groups.map() { $0.JSONDict! }
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {

        if let json = json as? AferoJSONObject {
            if
                let gaugeJSON = json[type(of: self).CoderKeyGauge] as? [String: Any],
                let gauge: DeviceProfile.Presentation.Gauge = |<gaugeJSON {
                    self.init(
                        gauge: gauge,
                        label: json[type(of: self).CoderKeyLabel] as? String,
                        controlIds: json[type(of: self).CoderKeyControls] as? [Int],
                        groups: |<(json[type(of: self).CoderKeyGroups] as? [[String: Any]])
                    )
                    
            } else {
                DDLogInfo("ERROR: Unable to decode DeviceProfile.Presentation.Group: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Presentation.Gauge: AferoJSONCoding {
    
    static let CoderKeyForeground = "foreground"
    static let CoderKeyBackground = "background"
    static let CoderKeyDisplayRules = "displayRules"
    static let CoderKeyLabelSize = "labelSize"
    static let CoderKeyLabel = "label"

    public var JSONDict: AferoJSONCodedType? {
        var ret: AferoJSONObject = [:]

        if let foreground = foreground {
            ret[Swift.type(of: self).CoderKeyForeground] = foreground.JSONDict
        }

        if let background = background {
            ret[Swift.type(of: self).CoderKeyBackground] = background.JSONDict
        }

        if let label = label {
            ret[Swift.type(of: self).CoderKeyLabel] = label
        }

        if let labelSize = labelSize {
            ret[Swift.type(of: self).CoderKeyLabelSize] = labelSize
        }
        
        if let displayRules = displayRules {
            ret[Swift.type(of: self).CoderKeyDisplayRules] = displayRules
        }
        
        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? AferoJSONObject {
            self.init(
                foreground: |<(json[Swift.type(of: self).CoderKeyForeground] as? [String: Any]),
                background: |<(json[Swift.type(of: self).CoderKeyBackground] as? [String: Any]),
                displayRules: json[Swift.type(of: self).CoderKeyDisplayRules] as? DisplayRules
            )
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Presentation.Layer: AferoJSONCoding {
    
    static let CoderKeyImages = "images"
    
    public var JSONDict: AferoJSONCodedType? {
        return [
            type(of: self).CoderKeyImages: images.map() { return $0.JSONDict! }
        ]
    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? AferoJSONObject {
            if let
                
                images: [DeviceProfile.Presentation.LayerImage] = |<(json[type(of: self).CoderKeyImages] as? [[String: Any]]) {
                    self.init(images: images)
            } else {
                DDLogInfo("ERROR: Unable to decode DeviceProfile.Presentation.Layer: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Presentation.LayerImage: AferoJSONCoding {

    static let CoderKeyURI = "uri"
    static let CoderKeyCardURI = "cardURI"
    
    public var JSONDict: AferoJSONCodedType? {
        
        var ret: [String: Any] = [
            type(of: self).CoderKeyURI: URI
        ]
        
        if let cardURI = cardURI {
            ret[type(of: self).CoderKeyCardURI] = cardURI
        }
        
        return ret

    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? AferoJSONObject {
            if let
                uri = json[type(of: self).CoderKeyURI] as? String {
                    self.init(uri: uri, cardURI: json[type(of: self).CoderKeyCardURI] as? String)
            } else {
                DDLogInfo("ERROR: Unable to decode DeviceProfile.Presentation.LayerImage: \(json)")
                return nil
            }
        } else {
            return nil
        }
    }
}

extension DeviceProfile.Service: AferoJSONCoding {

    public var CoderKeyId: String          { return "id" }
    public var CoderKeyAttributes: String  { return "attributes" }
    
    public var JSONDict: AferoJSONCodedType? {

        let ret: AferoJSONObject = [
            CoderKeyId: id,
            CoderKeyAttributes: attributes.map() { $0.JSONDict! },
        ]

        return ret
    }
    
    public init?(json: AferoJSONCodedType?) {
        if let json = json as? AferoJSONObject {
            id = json[CoderKeyId] as? Int ?? 0
            self.attributes = |<(json[CoderKeyAttributes] as? [AnyObject]) ?? []
        } else {
            return nil
        }
    }
    
}

extension DeviceProfile.Presentation.LayerImage {
    
    public func URIForScale(_ scale: CGFloat) -> URIPresentable {
        var scaleURLComponent = "/3x/"
        let scaleURLPlaceholder = "/3x/"
        
        switch(UIScreen.main.nativeScale) {
        case 1..<2:
            scaleURLComponent = "/1x/"
        case 2..<3:
            scaleURLComponent = "/2x/"
        default:
            scaleURLComponent = "/3x/"
        }
        return self.URI.replacingOccurrences(of: scaleURLPlaceholder, with: scaleURLComponent)
    }
    
    public var scaledURI: URIPresentable {
        return URIForScale(UIScreen.main.nativeScale)
    }
}

extension RangeOptionsPresentable {

    var maxValue: AttributeValue? { return AttributeValue(max) }
    var minValue: AttributeValue? { return AttributeValue(min) }
    var stepValue: AttributeValue? { return AttributeValue(step) }

    /// Number of possible steps in this instance
    
    public var count: NSDecimalNumber {
        
        guard let
            dmax = maxValue?.number,
            let dmin = minValue?.number,
            let dstep = stepValue?.number else {
                return 0
        }
        
        let ret = abs((dmax - dmin) / dstep) + 1
        return ret
    }
    
    /// Clamp the given value, so that it falls falls within the range `min...max`. "Out-of-bounds"
    /// values will be equal to the min or max, whichever is applicable.
    /// This function returns `nil` iff `{minValue,maxValue}.{doubleValue,int64value}` return nil.
    
    func clamp(_ value: NSDecimalNumber) -> NSDecimalNumber? {
        
        guard let min = minValue?.number, let  max = maxValue?.number else { return nil }
        
        let ret = value.clamp(min, max: max)
        DDLogVerbose("[clamp] value: \(value) min: \(min) max: \(max) ret: \(ret)", tag: "RangeOptionsPresentable")
        
        return ret
    }
    
    /// An array of `NSDecimalNumber`s representing the valid discrete steps
    /// for this instance.
    
    public var steps: [NSDecimalNumber] {
        return (0..<count.uint64Value).compactMap { self[idx: $0] }
    }
    
    
    /// The closest discrete index of the given proportion.
    
    func indexOf(prop: NSDecimalNumber?) -> NSDecimalNumber? {

        guard
            let prop = prop,
            let dmin = minValue?.number,
            let dmax = maxValue?.number,
            let dstep = stepValue?.number else { return nil }
        
        let magnitude = dmax - dmin
        if magnitude == 0 { return 0.0 }
        
        let cprop = prop.clamp(NSDecimalNumber(value: 0), max: NSDecimalNumber(value: 1))
        let numSteps = (magnitude / dstep)
        let n = (numSteps * prop).rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance)

        DDLogVerbose("indexOf(prop: \(prop), cprop: \(cprop), count: \(count)): \(n)", tag: "RangeOptionsPresentable")
        
        return n
    }
    
    /// Return the index, suitable for dereferencing, of the given AttributeValue. The returned index will dereference
    /// an NSDecimalNumber that is closest to the value that's passed in, so `self[indexOf(value)]` may not equal `value`.
    
    func indexOf(_ value: NSNumber) -> NSDecimalNumber? {
        return indexOf(prop: proportionOf(value: value))
    }
    
    /// Find the proportion, from 0.0...1.0, of the receiver that the value represents.
    
    func proportionOf(value: NSNumber?) -> NSDecimalNumber? {

        guard let
            value = value,
            let dmin = minValue?.number,
            let dmax = maxValue?.number else { return nil }
        
        let magnitude = dmax - dmin
        if magnitude == 0 { return 0.0 }
        
        
        let consumed = NSDecimalNumber(value: value.doubleValue) - dmin
        let ret = consumed / magnitude
        DDLogVerbose("proportionOf(\(value)): \(ret)", tag: "RangeOptionsPresentable")
        return ret
    }
    
    /**
     Subscript RangeOptions by an index of its discrete values, from 0..<count.
     */
    
    
    subscript(idx idx: UInt64) -> NSDecimalNumber? {
        return self[idx: NSDecimalNumber(value: idx as UInt64)]
    }
    
    subscript(idx idx: NSDecimalNumber) -> NSDecimalNumber? {
        
        guard let
            dmin = minValue?.number,
            let dstep = stepValue?.number else { return nil }
        
        return clamp(dmin + (dstep * idx))
    }
    
    /**
     Subscript the RangeOptionsPresentable by a proportion of its range, from 0.0...1.0.
     */
    
    subscript(proportion proportion: Double) -> NSDecimalNumber? {
        return self[proportion: NSDecimalNumber(value: proportion)]
    }
    
    subscript(proportion proportion: NSDecimalNumber) -> NSDecimalNumber? {
        
        if count == NSDecimalNumber.zero { return nil }
        
        guard let
            dmin = minValue?.number,
            let dmax = maxValue?.number,
            let dstep = stepValue?.number,
            let idx = indexOf(prop: proportion) else {
                return nil
        }
        
        let ret = clamp(dmin + (dstep * idx.rounding(accordingToBehavior: NSDecimalNumber.IntegerBehaviors.sharedInstance)))
        DDLogVerbose("valueForProportion(\(proportion) dmin: \(dmin) dmax: \(dmax) dstep: \(dstep) idx: \(idx)): \(String(describing: ret))", tag: "RangeOptionsPresentable")
        return ret
        
    }

}

public extension Array where Element: ValueOptionPresentable {
    
    var displayRules: DisplayRules {
        
        return self.compactMap {
            opt in
            
            let filteredApply = opt.apply.filter {
                key, value in
                guard let value = value as? String else { return false }
                
                // NOTE: JM 03MAR2017 We don't currently have an explicit standby state;
                // if state's not running but a device is online, it's assumed
                // to be in standby. There are some old profiles that include the
                // state: standby pair, but due to the way their rules are arranged,
                // standby overwrites running. This is here to explicitly handle this case.
                
                return !((key == "state") && (value == "standby"))
                }.reduce([:]) {
                    (curr: ValueOptionApplyPresentable, next: (String, Any)) -> ValueOptionApplyPresentable in
                    var ret = curr
                    ret[next.0] = next.1
                    return ret
            }
            
            return ["match": opt.match, "apply": filteredApply]
        }
    }
    
    var valueOptionsMap: ValueOptionsMap {
        
        return displayRules.reduce([:]) {
            curr, next in
            guard
                let match = next["match"] as? ValueOptionMatchPresentable,
                let apply = next["apply"] as? ValueOptionApplyPresentable else {
                    return curr
            }
            var ret = curr
            ret[match] = apply
            return ret
        }
        
    }
    
    func displayRulesProcessor<
        C: Hashable & SafeSubscriptable>(_ attributeId: Int, initial: [String: Any]? = nil) -> ((C?)->[String: Any])
        where C.Value == AttributeValue, C.Key == Int
         {
        
        let rules = self.displayRules.map {
            return $0 ++ ["attributeId": attributeId]
        }
        
        return DisplayRulesProcessor.MakeProcessor(
            initial ?? [:],
            rules: rules,
            operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
            integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue  }
        )
    }
    
    func displayRulesProcessor(_ initial: [String: Any]? = [:]) -> ((AttributeValue?) -> [String: Any]) {
        
        return DisplayRulesProcessor.MakeProcessor(
            initial ?? [:],
            rules: displayRules,
            operandXform: { (oper: String) -> AttributeValue in return AttributeValue(oper) },
            integerOptionalXform: { (value: AttributeValue) -> Int? in return value.intValue  }
        )
    }
    
}

public protocol LongIntegerAttributeValueSubscriptable {
    var count: UInt64 { get }
    subscript(idx: UInt64) -> AttributeValue? { get }
}

public protocol ProportionAttributeValueSubscriptable {
    func proportionOf(_ v: AttributeValue?) -> Double?
    subscript(proportion: Double) -> AttributeValue? { get }
}

public protocol OptionsSubscriptable:
    LongIntegerAttributeValueSubscriptable,
    ProportionAttributeValueSubscriptable,
    CustomDebugStringConvertible { }

public struct RangeOptionsSubscriptor: OptionsSubscriptable {
    
    fileprivate let TAG = "RangeOptionsSubscriptor"
    
    public var debugDescription: String {
        return "<RangeOptionsSteps> [" + steps.map { $0.debugDescription }.joined(separator: ",") + "]"
    }
    
    public var steps: [AttributeValue] {
        return (0..<count).compactMap { self[$0] }
    }
    
    public typealias Presentable = DeviceProfile.Presentation.AttributeOption.RangeOptions
    
    fileprivate(set) public var rangeOptions: Presentable
    fileprivate(set) public var dataType: AferoAttributeDataType
    
    init(rangeOptions: Presentable, dataType: AferoAttributeDataType) {
        self.rangeOptions = rangeOptions
        self.dataType = dataType
    }
    
    public var count: UInt64 {
        return rangeOptions.count.uint64Value
    }
    
    public var midPoint: AttributeValue? {
        return self[count / 2]
    }
    
    public subscript(idx: UInt64) -> AttributeValue? {
        guard let value = rangeOptions[idx: idx] else { return nil }
        return AttributeValue(type: dataType, value: value)
    }
    
    public subscript(proportion: Double) -> AttributeValue? {
        guard let value = rangeOptions[proportion: proportion] else {
            DDLogError("ERROR: Got nil when subscripting AttributeValue for proportion \(proportion).", tag: TAG)
            return nil
        }
        
        DDLogVerbose("Got \(value) for range options subscript", tag: TAG)
        let ret = AttributeValue(type: dataType, value: value)
        DDLogVerbose("Returning \(String(describing: ret))", tag: TAG)
        return ret
    }
    
    public func proportionOf(_ v: AttributeValue?) -> Double? {
        return rangeOptions.proportionOf(value: v?.number)?.doubleValue
    }

    public func indexOf(_ value: Double?) -> UInt64? {

        guard let value = value else {
            return nil
        }
        
        guard let dv = rangeOptions.indexOf(NSNumber(value: value))?.doubleValue else {
            return nil
        }
        
        return UInt64(round(dv))
        
    }
    
    public func indexOf(_ value: Float?) -> UInt64? {
        guard let value = value else { return nil }
        return indexOf(Double(value))
    }
    
    /// Quantize `v` to the closest valid value, and return its index.
    public func indexOf(_ value: AttributeValue?) -> UInt64? {
        guard let fv = value?.doubleValue else { return nil }
        return indexOf(fv)
    }
    
}

public extension DeviceProfile.Presentation.AttributeOption.RangeOptions {
    
    func subscriptor(_ dataType: AferoAttributeDataType) -> RangeOptionsSubscriptor {
        return RangeOptionsSubscriptor(rangeOptions: self, dataType: dataType)
    }
    
    var range: ClosedRange<AttributeValue> {
        return minValue!...maxValue!
    }

}

extension AttributeValue {
    
    /// Returns an AttributeValue representation for a ValueOption's match value,
    /// based upon the given AttributeDescriptor
    
    public init?(option: ValueOptionPresentable, descriptor: DeviceProfile.AttributeDescriptor) {
        let value = option.match
        if let castValue = descriptor.attributeValue(for: value) {
            self = castValue
            return
        }
        DDLogError("Unable to convert valueOption.match \(value) to value with descriptor \(descriptor)", tag: "AttributeValue-ValueOptionExtension")
        return nil
    }
}

public struct ValueOptionsSubscriptor: OptionsSubscriptable {

    public var TAG: String { return "ValueOptionsSubscriptor" }
    
    public var debugDescription: String {
        return "<ValueOptionsSubscriptor> type: \(descriptor) \(valueOptions.debugDescription)"
    }
    
    public typealias Presentable = DeviceProfile.Presentation.AttributeOption.ValueOption
    
    let descriptor: DeviceProfile.AttributeDescriptor
    let valueOptions: [Presentable]
    let values: [AttributeValue]
    
    public init?(valueOptions: [Presentable]?, descriptor: DeviceProfile.AttributeDescriptor) {
        guard let valueOptions = valueOptions else { return nil }

        let localValues = valueOptions.enumerated().map {
            (idx: Int, valueOption: Presentable) -> AttributeValue in
            guard let value = AttributeValue(option: valueOption, descriptor: descriptor) else {
                DDLogWarn("Will sub in '0'", tag: "ValueOptionsSubscriptor")
                return AttributeValue("0")
            }
            return value
        }
        self.valueOptions = valueOptions
        self.descriptor = descriptor
        self.values = localValues
    }
    
    public var count: UInt64 {return UInt64(valueOptions.count) }
    
    public subscript(idx: UInt64) -> AttributeValue? {
        
        let tag = "ValueOptionSubscriptor_subscript[UInt64]"
        
        guard idx < count else {
            DDLogError("subscript[idx] index \(idx) outside of valid range 0...<\(count).", tag: tag)
            return nil
        }
        
        let ret = values[Int(idx)]
        DDLogVerbose("self[\(idx)]: \(ret)", tag: tag)
        return ret
    }
    
    public subscript(proportion: Double) -> AttributeValue? {
        
        let tag = "ValueOptionSubscriptor_subscript[proportion]"
        
        guard proportion >= 0 && proportion <= 1.0 else {
            DDLogError("subsript[prop] proportion \(proportion) outside of valid range 0...1.", tag: tag)
            return nil
        }
        let count = self.count
        let cidx = proportion * Double(count - 1)
        let idx = UInt64(floor(cidx))
        let ret = self[idx]
        DDLogVerbose("self[\(proportion)] (idx: \(idx)): \(String(describing: ret))", tag: tag)
        return ret
    }
    
    public func indexOf(_ v: AttributeValue?) -> UInt64? {
        
        let tag = "ValueOptionSubscriptor_indexOf"
        
        guard let v = v else {
            DDLogWarn("indexOf no value provided.", tag: tag)
            return nil
        }
        
        let maybeIdx: Int?
        
        #if !compiler(>=5)
        maybeIdx = values.index(of: v)
        #endif
        
        #if compiler(>=5)
        maybeIdx = values.firstIndex(of: v)
        #endif
        
        guard let idx = maybeIdx else {
            DDLogWarn("indexOf no index for value \(v) in \(values.debugDescription)", tag: tag)
            return nil
        }
        
        let ret = UInt64(idx)
        DDLogVerbose("indexOf value: \(v) : \(ret)", tag: "ValueOptionSubscriptor_indexOf")
        return ret
    }
    
    public func indexOf(_ v: Double?) -> UInt64? {
        
        guard let v = v else { return nil }
        
        assert(v >= 0, "indexOf(Double): value must be >= 0")
        assert(v <= 1.0, "indexOf(Double): value must be <= 1.0")
        
        return UInt64(floor(Double(count - 1) * v))
    }

    public func indexOf(_ v: Float?) -> UInt64? {
        
        guard let v = v else { return nil }
        return indexOf(Double(v))
    }

    public func proportionOf(_ v: AttributeValue?) -> Double? {

        let tag = "ValueOptionSubscriptor_proportionOf"
        
        guard let v = v else {
            DDLogWarn("proportionOf: no value given.", tag: tag)
            return nil
        }
        
        let castValue = descriptor.attributeValue(for: v.stringValue)

        guard let idx = indexOf(castValue) else {
            DDLogWarn("proportionOf \(v) value did not match a known index.", tag: tag)
            return nil
        }
        
        let ret = Double(idx) / Double(count - 1)
        DDLogVerbose("proportionOf value: \(v) (idx: \(idx)): \(ret)", tag: tag)
        return ret
    }
}
