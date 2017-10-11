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

protocol DeviceModelableObserving: class {

    var TAG: String { get }
    weak var deviceModelable: DeviceModelable! { get }
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
    
}

/*
 Methods in the following extension provide a default implementation which
 dispatches onto methods retroactively modeled onto `DeviceModelable` classes.
 */

extension DeviceModelableObserving {
    
    var TAG: String { return "\(type(of: self))" }
    
    func startObservingDeviceEvents() {
        
        let TAG = self.TAG
        
        stopObservingDeviceEvents()
        
        guard let deviceModel = deviceModelable else {
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
        }
    }
    
    func handleDeviceEventSignalCompleted() {
        DDLogDebug("Device \(deviceModelable.deviceId) signal completed (default impl).", tag: TAG)
    }
    
    func handleDeviceEventSignalFailed(with error: Error) {
        // NOTE: Shown for completeness; .failed(_) messages are never sent.
        DDLogError("Device model error: \(error.localizedDescription) (default impl)", tag: TAG)
    }
    
    func handleDeviceEventSignalInterrupted() {
        // NOTE: Shown for completeness; .interrupted messages are never sent.
        DDLogWarn("Device event stream interrupted (default impl)", tag: TAG)
    }
    
}

/*
 Methods in this extension are default handlers for specific events, and simply
 log at DEBUG or VERBOSE levels, for demonstration purposes.
 */

extension DeviceModelableObserving {
    
    func handleDeviceDeletedEvent() {
        DDLogDebug("Device \(deviceModelable.deviceId) deleted (default impl).", tag: TAG)
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

}

