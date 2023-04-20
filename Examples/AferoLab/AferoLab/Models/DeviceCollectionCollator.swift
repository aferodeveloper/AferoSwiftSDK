//
//  DeviceCollectionCollator.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/18/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import ReactiveSwift
import CocoaLumberjack
import Afero

protocol DeviceCollator {
    
    associatedtype Model: DeviceModelable
    associatedtype Deltas = (deletions: NSIndexSet, insertions: NSIndexSet)
    
    func numberOfDevices() -> Int
    func deviceIdForIndex(_ index: Int) -> String
    func deviceForIndex(_ index: Int) -> Model
    func indexForDeviceId(_ deviceId: String) -> Int?
    func deltas(_ before: [String], after: [String]) -> IndexDeltas
    
    func isOrderedBefore(_ lhs: Model, rhs: Model) -> Bool
    
}

extension DeviceCollator {
    
    func isOrderedBefore(_ lhs: Model, rhs: Model) -> Bool {
        return lhs < rhs
    }
    
    func deltas(_ before: [String], after: [String]) -> IndexDeltas {
        return before.deltasProducing(after)
    }
    
}

protocol DeviceCollectionObserving: class {
    
    var deviceCollection: DeviceCollection? { get }
    var deviceCollectionDisposable: Disposable? { get set }
    func deviceCollectionBeganUpdates()
    func deviceCollectionAddedDevice(_ device: DeviceModel)
    func deviceCollectionRemovedDevice(_ device: DeviceModel)
    func deviceCollectionReset()
    func deviceCollectionEndedUpdates()
    
}

extension DeviceCollectionObserving {
    
    func startObservingDeviceCollection() {
        
        deviceCollectionDisposable = deviceCollection?.contentsSignal
            .observe(on: QueueScheduler.main)
            .observeValues {
                [weak self] change in
                switch change {
                    
                case .beginUpdates:
                    self?.deviceCollectionBeganUpdates()
                    
                case .create(let device):
                    self?.deviceCollectionAddedDevice(device)
                    
                case .delete(let device):
                    self?.deviceCollectionRemovedDevice(device)
                    
                case .resetAll:
                    self?.deviceCollectionReset()
                    
                case .endUpdates:
                    self?.deviceCollectionEndedUpdates()
                    
                }
        }
        
        
    }
    
    func stopObservingDeviceCollection() {
        deviceCollectionDisposable?.dispose()
        deviceCollectionDisposable = nil
    }
    
}

class DeviceCollectionDeviceCollator: DeviceCollectionObserving, DeviceCollator {
    
    typealias Model = DeviceModel
    
    init(deviceCollection: DeviceCollection) {
        self.deviceCollection = deviceCollection
        startObservingDeviceCollection()
    }
    
    var collatedDeviceIds: [String] = [] {
        didSet { signalUpdate(oldValue.deltasProducing(collatedDeviceIds)) }
    }
    
    func signalUpdate(_ deltas: IndexDeltas) {
        collatorEventSink.send(value: .collationUpdated(deltas: deltas))
    }
    
    // MARK: Signaling
    
    enum CollatorEvent {
        case collationUpdated(deltas: IndexDeltas)
    }
    
    /// Type for the sink to which we send `CollatorEvent`s.
    fileprivate typealias CollatorEventSink = Signal<CollatorEvent, Never>.Observer
    
    /// Type for the signal on which clients listen for `CollatorEvent`s.
    typealias CollatorEventSignal = Signal<CollatorEvent, Never>
    
    /// Type for the pipe that ties `CollatorEventSink` and `CollatorEventSignal` together.
    fileprivate typealias CollatorEventPipe = (output: CollatorEventSignal, input: CollatorEventSink)
    
    /// The pipe which casts `CollatorEvent`s.
    lazy fileprivate final var collatorEventPipe: CollatorEventPipe = {
        return CollatorEventSignal.pipe()
    }()
    
    /// The `Signal` on which Collator events can be received.
    var collatorEventSignal: CollatorEventSignal {
        return collatorEventPipe.0
    }
    
    /**
     The `Sink` to which Collator events are broadcast after being chaned.
     */
    
    fileprivate final var collatorEventSink: CollatorEventSink {
        return collatorEventPipe.1
    }
    
    // MARK: <DeviceCollator>
    
    func numberOfDevices() -> Int {
        return collatedDeviceIds.count
    }
    
    func deviceIdForIndex(_ index: Int) -> String {
        return collatedDeviceIds[index]
    }
    
    func deviceForIndex(_ index: Int) -> Model {
        guard let ret = deviceCollection?.peripheral(for: deviceIdForIndex(index)) else {
            fatalError("No device collection, or device DNE at index \(index)")
        }
        
        return ret
    }
    
    func indexForDeviceId(_ deviceId: String) -> Int? {
        #if compiler(>=5)
        return collatedDeviceIds.firstIndex(of: deviceId)
        #endif
        #if !compiler(>=5)
        return collatedDeviceIds.index(of: deviceId)
        #endif
    }
    
    // MARK: <AccountAware>
    
    var accountId: String? {
        return deviceCollection?.accountId
    }
    
    // MARK: <DeviceCollectionObserving>
    
    var deviceCollection: DeviceCollection? {
        didSet {
            startObservingDeviceCollection()
            updateCollatedIds()
        }
    }
    
    var deviceCollectionDisposable: Disposable?
    
    func updateCollatedIds() {
        collatedDeviceIds = deviceCollection?
            .devices
            .sorted(by: isOrderedBefore)
            .map { $0.deviceId } ?? []
        
    }
    
    func deviceCollectionBeganUpdates() {
        DDLogInfo("DeviceCollection updates began.")
    }
    
    func deviceCollectionAddedDevice(_ device: DeviceModel) {
        updateCollatedIds()
    }
    
    func deviceCollectionRemovedDevice(_ device: DeviceModel) {
        updateCollatedIds()
    }
    
    func deviceCollectionReset() {
        updateCollatedIds()
    }
    
    func deviceCollectionEndedUpdates() {
        DDLogInfo("DeviceCollectionUpdatesEnded.")
    }
    
}

