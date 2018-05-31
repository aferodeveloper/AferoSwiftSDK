//
//  DeviceModelableObserving.swift
//  AferoLab
//
//  Created by Justin Middleton on 10/10/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import Afero
import ReactiveSwift
import CocoaLumberjack

protocol Tagged: class {
    var TAG: String { get }
}

extension Tagged {
    var TAG: String { return "\(type(of: self))@\(Unmanaged.passUnretained(self).toOpaque())" }
}

// MARK: - DeviceModelableObserving

/// Protocol which devices some handy convenience methods
/// for observing Afero DeviceModels and events.

protocol DeviceModelableObserving: Tagged {

    var deviceModelable: DeviceModelable! { get set }
    var deviceEventSignalDisposable: Disposable? { get set }
    func startObservingDeviceEvents()
    func stopObservingDeviceEvents()
    
    // MARK: Stream Events
    func handle(event: DeviceModelEvent)
    func handleDeviceEventSignalCompleted()
    func handleDeviceEventSignalFailed(with error: Error)
    func handleDeviceEventSignalInterrupted()
    
    // MARK: Device Model Event Values
    
    // These events originate from `handle(event:)`.
    
    func handleDeviceDeletedEvent()
    func handleDeviceErrorEvent(error: DeviceError)
    func handleDeviceErrorResolvedEvent(status: DeviceErrorStatus)
    func handleDeviceMutedEvent(for duration: TimeInterval)
    func handleDeviceOtaStartEvent()
    func handleDeviceOtaProgressEvent(with proportion: Float)
    func handleDeviceOtaFinishEvent()
    func handleDeviceStateUpdateEvent(newState: DeviceState)
    func handleDeviceProfileUpdateEvent()
    func handleDeviceWriteStateChangeEvent(newState: DeviceWriteState)
    func handleTagEvent(event: DeviceModelable.DeviceTagEvent)
    
}

// MARK: DeviceModelableEventSignal Observation Control Default Implementations

/*
 Methods in the following extension provide a default implementation which
 dispatches onto methods retroactively modeled onto `DeviceModelable` classes.
 */

extension DeviceModelableObserving {
    
    func startObservingDeviceEvents() {
        
        let TAG = self.TAG
        
        stopObservingDeviceEvents()
        
        guard let deviceModel = deviceModelable else {
            DDLogWarn("No deviceModel to observe; bailing", tag: TAG)
            return
        }
        
        deviceEventSignalDisposable = deviceModel.eventSignal
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] signalEvent in switch signalEvent {
                    
                case let .value(event):
                    self?.handle(event: event)
                    
                case .completed:
                    self?.handleDeviceEventSignalCompleted()
                    
                case let .failed(err):
                    self?.handleDeviceEventSignalFailed(with: err)
                    
                case .interrupted:
                    self?.handleDeviceEventSignalInterrupted()
                }
        }
        
    }
    
    func stopObservingDeviceEvents() {
        deviceEventSignalDisposable?.dispose()
        deviceEventSignalDisposable = nil
    }
}

// MARK: DeviceModelEvent Signal Event Default Implementations

extension DeviceModelableObserving {
    
    func handle(event: DeviceModelEvent) {
        
        DDLogInfo("Device \(deviceModelable.deviceId) emitted event: \(event)", tag: TAG)
        
        switch event {

        case .deleted:
            handleDeviceDeletedEvent()

        case .error(let error):
            handleDeviceErrorEvent(error: error)

        case .errorResolved(let status):
            handleDeviceErrorResolvedEvent(status: status)

        case .muted(let timeout):
            handleDeviceMutedEvent(for: timeout)

        case .otaStart:
            handleDeviceOtaStartEvent()

        case .otaProgress(let progress):
            handleDeviceOtaProgressEvent(with: progress)

        case .otaFinish:
            handleDeviceOtaFinishEvent()

        case .profileUpdate:
            handleDeviceProfileUpdateEvent()

        case .stateUpdate(let newState):
            handleDeviceStateUpdateEvent(newState: newState)

        case .writeStateChange(let newState):
            handleDeviceWriteStateChangeEvent(newState: newState)
            
        case .tagEvent(let event):
            handleTagEvent(event: event)
        }
    }
    
    func handleDeviceEventSignalCompleted() {
        DDLogDebug("Device \(deviceModelable.deviceId) signal completed (default impl).", tag: TAG)
        stopObservingDeviceEvents()
    }
    
    func handleDeviceEventSignalFailed(with error: Error) {
        // NOTE: Provided for completeness; .failed(_) messages are currently not sent.
        DDLogError("Device model error: \(error.localizedDescription) (default impl)", tag: TAG)
        stopObservingDeviceEvents()
    }
    
    func handleDeviceEventSignalInterrupted() {
        // NOTE: Shown for completeness; .interrupted messages are currently not sent.
        DDLogWarn("Device event stream interrupted (default impl)", tag: TAG)
    }
    
}

// MARK: DeviceModelEvent Value Handler Default Implementations

/*
 Methods in this extension are default handlers for specific events, and simply
 log at DEBUG or VERBOSE levels, for demonstration purposes.
 */

extension DeviceModelableObserving {
    
    func handleDeviceDeletedEvent() {
        DDLogDebug("Device \(deviceModelable.deviceId) deleted; stopping observation (default impl).", tag: TAG)
        stopObservingDeviceEvents()
    }
    
    func handleDeviceErrorEvent(error: DeviceError) {
        DDLogDebug("Device \(deviceModelable.deviceId) encountered error: \(String(reflecting: error)) (default impl).", tag: TAG)
    }
    
    func handleDeviceErrorResolvedEvent(status: DeviceErrorStatus) {
        DDLogDebug("Device \(deviceModelable.deviceId) resolved error with status: \(String(reflecting: status)) (default impl).", tag: TAG)
    }
    
    func handleDeviceMutedEvent(for duration: TimeInterval) {
        DDLogDebug("Device \(deviceModelable.deviceId) muted for \(duration) seconds (default impl).", tag: TAG)
    }
    
    func handleDeviceOtaStartEvent() {
        DDLogDebug("Device \(deviceModelable.deviceId) OTA started (default impl).", tag: TAG)
    }
    
    func handleDeviceOtaProgressEvent(with proportion: Float) {
        DDLogDebug("Device \(deviceModelable.deviceId) OTA progress now \(proportion) (default impl).", tag: TAG)
    }
    
    func handleDeviceOtaFinishEvent() {
        DDLogDebug("Device \(deviceModelable.deviceId) OTA finished (default impl).", tag: TAG)
    }
    
    func handleDeviceStateUpdateEvent(newState: DeviceState) {
        DDLogDebug("Device \(deviceModelable.deviceId) state state udpated (default impl)", tag: TAG)
        DDLogVerbose("Device \(deviceModelable.deviceId) state now \(String(reflecting: newState))", tag: TAG)
    }
    
    func handleDeviceProfileUpdateEvent() {
        DDLogDebug("Device \(deviceModelable.deviceId) profile updated. (default impl).", tag: TAG)
    }
    
    func handleDeviceWriteStateChangeEvent(newState: DeviceWriteState) {
        DDLogDebug("Device \(deviceModelable.deviceId) write state now: \(newState) (default impl).", tag: TAG)
    }
    
    func handleTagEvent(event: DeviceModelable.DeviceTagEvent) {
        DDLogDebug("Device \(deviceModelable.deviceId) got tag event: \(event) (default impl).", tag: TAG)
    }

}

// MARK: - AttributeEventObserving -

/// Protocol which to make observations of individual attribute changes
/// easier.

protocol AttributeEventObserving: Tagged {

    var attributeId: Int? { get set }
    var attribute: DeviceModelable.Attribute? { get }
    
    var attributeEventSignaling: AttributeEventSignaling! { get set }
    var attributeEventDisposable: Disposable? { get set }
    
    func initializeAttributeObservation()
    
    func startObservingAttributeEvents()
    func stopObservingAttributeEvents()

    func handle(event: AttributeEvent)
    func handleAttributeEventSignalCompleted()
    func handleAttributeEventSignalFailed(with error: Error)
    func handleAttributeEventSignalInterrupted()
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute)
    
    // Convenience Accessors (defaults are provided)
    
    var attributeIdStringValue: String { get }
    var attributeNameStringValue: String { get }
    var attributeTypeStringValue: String { get }
    var attributeIsWritable: Bool { get }
    var attributeValueStringValue: String { get }
    
    var attributeLabelDisplayValue: String? { get }
    
    var attributeRangeOptions: AferoAttributePresentationRangeOptions? { get }
    var attributeRangeSubscriptor: RangeOptionsSubscriptor? { get }
    
    typealias ValueOption = AferoAttributePresentationValueOption

    var attributeValueOptions: [ValueOption]? { get }
    var attributeValueOptionsMap: ValueOptionsMap? { get }
    func attributeValue(forStringValue stringValue: String?) -> AttributeValue?
    func attributeValue(forDoubleValue doubleValue: Double?) -> AttributeValue?
    func attributeValue(forFloatValue floatValue: Float?) -> AttributeValue?
    func attributeValue(forIntegerValue integerValue: Int?) -> AttributeValue?

    func attributeValue(forProportion proportion: Float) -> AttributeValue?
    func proportion(for value: AttributeValue?) -> Float
    
}


extension AttributeEventObserving {
    
    weak var attributeEventSignaling: AttributeEventSignaling! {
        get { return (self as? DeviceModelableObserving)?.deviceModelable }
        set { (self as? DeviceModelableObserving)?.deviceModelable = (newValue as? DeviceModelable) }
    }
    
}

// MARK: AttributeEventSignal Observation Control Default Implementations

extension AttributeEventObserving {
    
    func startObservingAttributeEvents() {
        
        let TAG = self.TAG
        
        stopObservingAttributeEvents()
        
        guard
            let attributeId = attributeId,
            let attributeEventSignaling = attributeEventSignaling else {
            DDLogWarn("No attributeEventSignaling to observe; bailing", tag: TAG)
            return
        }
        
        attributeEventDisposable = attributeEventSignaling.eventSignalForAttributeId(attributeId)?
            .observe(on: QueueScheduler.main)
            .observe {
                [weak self] signalEvent in switch signalEvent {
                    
                case let .value(event):
                    self?.handle(event: event)
                    
                case .completed:
                    self?.handleAttributeEventSignalCompleted()
                    
                case let .failed(err):
                    self?.handleAttributeEventSignalFailed(with: err)
                    
                case .interrupted:
                    self?.handleAttributeEventSignalInterrupted()
                }
        }
        
        initializeAttributeObservation()
        
    }
    
    func stopObservingAttributeEvents() {
        attributeEventDisposable?.dispose()
        attributeEventDisposable = nil
    }

}

// MARK: AttributeEventSignal Event Handler Default Implementations

extension AttributeEventObserving {
    
    func initializeAttributeObservation() {
        guard let attributeId = attributeId else {
            DDLogWarn("Not initializing observation yet; missing device or attributeId", tag: TAG)
            return
        }
        DDLogDebug("Initializing observation for \(attributeId)", tag: TAG)
    }
    
    
    func handle(event: AttributeEvent) {
        switch event {
        case let .update(accountId, deviceId, attribute):
            handleAttributeUpdate(accountId: accountId, deviceId: deviceId, attribute: attribute)
        }
    }
    
    func handleAttributeEventSignalCompleted() {
        DDLogDebug("Attribute signal ended for attributeId \(attributeIdStringValue); stopping observation (default impl).", tag: TAG)
        stopObservingAttributeEvents()
    }
    
    func handleAttributeEventSignalFailed(with error: Error) {
        DDLogDebug("Attribute signal failed with error \(String(describing: error)) for attributeId \(attributeIdStringValue); stopping observation (default impl).", tag: TAG)
        stopObservingAttributeEvents()
    }
    
    func handleAttributeEventSignalInterrupted() {
        DDLogDebug("Attribute signal interrupted (default impl).", tag: TAG)
    }
    
}

extension AttributeEventObserving {
    
    func handleAttributeUpdate(accountId: String, deviceId: String, attribute: DeviceModelable.Attribute) {
        DDLogDebug("Device \(deviceId) on account \(accountId) got attribute \(String(reflecting: attribute)) (default impl)", tag: TAG)
    }
    
}

// MARK: Convenience Accessor Default Implementations

extension AttributeEventObserving {
    
    /// A tuple containing the attribute's data type and display
    /// information, as well as its current value
    
    var attribute: DeviceModelable.Attribute? {
        guard let attributeId = attributeId else { return nil }
        return attributeEventSignaling.attribute(for: attributeId)
    }

    var attributeIdStringValue: String {
        guard let attributeId = attributeId else { return "-" }
        return "\(attributeId)"
    }
    
    var attributeNameStringValue: String {
        return attribute?.config.dataDescriptor.semanticType ?? "-"
    }
    
    var attributeTypeStringValue: String {
        return attribute?.config.dataDescriptor.dataType.stringValue ?? "-"
    }
    
    var attributeIsWritable: Bool {
        return attribute?.config.dataDescriptor.isWritable ?? false
    }

    var attributeValueStringValue: String {
        return attribute?.value?.stringValue ?? "-"
    }
    
    var attributeLastUpdatedStringValue: String {
        // TODO: Implement last updated
        return "-"
    }
    
    var attributeLabelDisplayValue: String? {
        return attribute?.displayParams?["label"] as? String
    }
}

// MARK: ValueOptions Methods Default Implementations

extension AttributeEventObserving {
    
    typealias ValueOption = AferoAttributePresentationValueOption
    var attributeValueOptions: [ValueOption]? {
        return attribute?.config.presentationDescriptor?.valueOptions
    }
    
    var attributeValueOptionsMap: ValueOptionsMap? {
        guard let ret = attributeValueOptions?.valueOptionsMap else { return nil }
        guard ret.count > 0 else { return nil }
        return ret
    }
    
    func attributeValue(forStringValue stringValue: String?) -> AttributeValue? {
        
        guard let stringValue = stringValue else { return nil }
        
        guard let attribute = attribute else {
            return nil
        }
        
        guard let value = attribute.config.dataDescriptor.attributeValue(for: stringValue) else {
            return nil
        }
        
        if let rangeOptions = attributeRangeSubscriptor {
            guard rangeOptions.steps.contains(value) else {
                return nil
            }
        }
        
        if let valueOptionsMap = attributeValueOptionsMap {
            guard valueOptionsMap.keys.contains(stringValue) else {
                return nil
            }
        }
        
        return value
    }

    func attributeValue(forDoubleValue doubleValue: Double?) -> AttributeValue? {
        guard let doubleValue = doubleValue else { return nil }
        return attributeValue(forStringValue: "\(doubleValue)")
    }

    func attributeValue(forFloatValue floatValue: Float?) -> AttributeValue? {
        guard let floatValue = floatValue else { return nil }
        return attributeValue(forDoubleValue: Double(floatValue))
    }
    
    func attributeValue(forIntegerValue integerValue: Int?) -> AttributeValue? {
        guard let integerValue = integerValue else { return nil }
        return attributeValue(forStringValue: "\(integerValue)")
    }

}

// MARK: RangesOptions Methods Default Implementations

extension AttributeEventObserving {
    
    var attributeRangeOptions: AferoAttributePresentationRangeOptions? {
        return attribute?.config.presentationDescriptor?.rangeOptions
    }
    
    var attributeRangeSubscriptor: RangeOptionsSubscriptor? {
        guard let dataType = attribute?.config.dataDescriptor.dataType else {
            return nil
        }
        return attributeRangeOptions?.subscriptor(dataType)
    }
    
    func attributeValue(forProportion proportion: Float) -> AttributeValue? {
        
        guard let rangeSubscriptor = attributeRangeSubscriptor else {
            return nil
        }
        
        return rangeSubscriptor[Double(proportion)]
        
    }
    
    func proportion(for value: AttributeValue?) -> Float {
        
        guard let rangeSubscriptor = attributeRangeSubscriptor else {
            return Float(0.0)
        }
        
        guard let proportion = rangeSubscriptor.proportionOf(value) else {
            return Float(0.0)
        }
        
        return Float(proportion)
        
    }


}
