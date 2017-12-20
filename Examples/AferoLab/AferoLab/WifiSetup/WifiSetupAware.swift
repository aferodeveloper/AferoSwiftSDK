//
//  WifiSetupAware.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/15/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import UIKit
import Afero
import ReactiveSwift
import Result
import CocoaLumberjack


/// A convenience protocol for handling `WifiSetupManager` interaction.

public protocol WifiSetupAware: class {
    
    var TAG: String { get }
    
    var deviceId: String? { get }
    var deviceModel: DeviceModel? { get  set }
    var wifiSetupManager: WifiSetupManaging? { get }
    var wifiEventDisposable: Disposable? { get set }
    
    func subscribeToWifiSetupManager()
    
    func onWifiSetupEvent(_ event: WifiSetupEvent)
    
    func handleSSIDListChanged(_ newList: WifiSetupManaging.WifiNetworkList)
    
    func handlePasswordCommitted()
    func handleAssociateFailed()
    func handleHandshakeFailed()
    func handleEchoFailed()
    func handleSSIDNotFound()
    func handleUnknownFailure()

    // Events related to the currently-configured wifi network
    
    func handleNetworkTypeChanged(_ newType: WifiSetupManaging.NetworkType)
    func handleWifiSteadyStateChanged(_ newState: WifiSetupManaging.WifiState)
    func handleWifiCurrentSSIDChanged(_ newSSID: String)
    func handleWifiRSSIBarsChanged(_ newRSSIBars: Int)
    func handleWifiRSSIChanged(_ newRSSI: Int)
    
    func handleWifiSetupStateChanged(_ newState: WifiSetupManaging.WifiState)
    func handleWifiConnected()

    // Events related to the setup process
    
    func handleManagerStateChanged(_ newState: WifiSetupManagerState)
    func handleCommandStateChanged(_ newState: WifiSetupManaging.CommandState)
    
    func handleWifiCommandError(_ error: Error)
    

}

public extension WifiSetupAware {
    
    func subscribeToWifiSetupManager() {
        
        let TAG = self.TAG
        
        wifiEventDisposable = wifiSetupManager?.wifiSetupEventSignal
            .observe(on: QueueScheduler.main)
            .observeValues {
                [weak self] wifiEvent in
                DDLogDebug("In observer for wifi event \(wifiEvent)", tag: TAG)
                self?.onWifiSetupEvent(wifiEvent)
        }
        
        DDLogDebug("subscribed to wifi event signal with disposable \(String(describing: wifiEventDisposable))", tag: TAG)
    }
    
}

// MARK: - Default wifi event handlers

public extension WifiSetupAware {
    
    func onWifiSetupEvent(_ event: WifiSetupEvent) {
        
        switch event {
            
        case .managerStateChange(let newState):
            handleManagerStateChanged(newState)
            
        case .commandStateChange(let newState):
            handleCommandStateChanged(newState)
            
        case let .ssidListChanged(newList):
            handleSSIDListChanged(newList)
            
        case let .networkTypeChanged(newType):
            handleNetworkTypeChanged(newType)
            
        case .wifiPasswordCommitted:
            handlePasswordCommitted()
            
        case .wifiSetupStateChanged(.associationFailed):
            handleAssociateFailed()
            
        case .wifiSetupStateChanged(.handshakeFailed):
            handleHandshakeFailed()
            
        case .wifiSetupStateChanged(.echoFailed):
            handleEchoFailed()
            
        case .wifiSetupStateChanged(.ssidNotFound):
            handleSSIDNotFound()
            
        case .wifiSetupStateChanged(.unknownFailure):
            handleUnknownFailure()
            
        case .wifiSetupStateChanged(.connected):
            handleWifiConnected()
            
        case let .wifiCurrentSSIDChanged(newSSID):
            handleWifiCurrentSSIDChanged(newSSID)
            
        case let .wifiSetupStateChanged(newState):
            handleWifiSetupStateChanged(newState)
            
        case let .wifiSteadyStateChanged(newState):
            handleWifiSteadyStateChanged(newState)
            
        case let .wifiRSSIChanged(newRSSI):
            handleWifiRSSIChanged(newRSSI)
            
        case let .wifiRSSIBarsChanged(newBars):
            handleWifiRSSIBarsChanged(newBars)
            
        }
        
    }


}

class WifiSetupAwareViewController: UIViewController, Tagged, WifiSetupAware {

    var deviceId: String? { return deviceModel?.deviceId }
    
    var deviceModel: DeviceModel?
    
    var wifiSetupManager: WifiSetupManaging? {
        
        willSet {
            wifiEventDisposable = nil
            wifiSetupManager?.stop()
        }
        
        didSet {
            subscribeToWifiSetupManager()
            wifiSetupManager?.start()
        }
    }
    
    var wifiEventDisposable: Disposable? {
        willSet {
            wifiEventDisposable?.dispose()
            DDLogDebug("unsubscribed from wifi event signal.", tag: TAG)
        }
    }
    
    deinit {
        wifiSetupManager = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wifiSetupManager = deviceModel?.getWifiSetupManager()
    }
    
    func handleSSIDListChanged(_ newList: WifiSetupManaging.WifiNetworkList) {
        DDLogInfo("Device \(deviceModel!.deviceId) sees SSIDs: \(String(describing: newList)) (default impl)", tag: TAG)
    }
    
    func handlePasswordCommitted() {
        DDLogInfo("Device \(deviceModel!.deviceId) committed password (default impl)", tag: TAG)
    }
    
    func handleAssociateFailed() {
        DDLogError("Device \(deviceModel!.deviceId) associate failed (default impl)", tag: TAG)
    }
    
    func handleHandshakeFailed() {
        DDLogError("Device \(deviceModel!.deviceId) handshake failed (default impl)", tag: TAG)
    }
    
    func handleEchoFailed() {
        DDLogError("Device \(deviceModel!.deviceId) echo failed (unable to ping Afero cloud) (default impl)", tag: TAG)
    }
    
    func handleSSIDNotFound() {
        DDLogError("Device \(deviceModel!.deviceId) SSID not found (default impl)", tag: TAG)
    }
    
    func handleUnknownFailure() {
        DDLogError("Device \(deviceModel!.deviceId) encountered an unknown wifi setup error. (default impl)", tag: TAG)
    }
    
    // Events related to the currently-configured wifi network
    
    func handleNetworkTypeChanged(_ newType: WifiSetupManaging.NetworkType) {
        DDLogInfo("Device \(deviceModel!.deviceId) network type changed to \(newType) (default impl)")
    }
    
    func handleWifiSteadyStateChanged(_ newState: WifiSetupManaging.WifiState) {
        DDLogInfo("Device \(deviceModel!.deviceId) new wifi steady state: \(newState) (default impl)", tag: TAG)
    }
    
    func handleWifiCurrentSSIDChanged(_ newSSID: String) {
        DDLogInfo("Device \(deviceModel!.deviceId) new SSID: \(newSSID) (default impl)", tag: TAG)
    }
    
    func handleWifiRSSIBarsChanged(_ newRSSIBars: Int) {
        DDLogInfo("Device \(deviceModel!.deviceId) new RSSI Bars: \(newRSSIBars) (default impl)", tag: TAG)
    }
    
    func handleWifiRSSIChanged(_ newRSSI: Int) {
        DDLogInfo("Device \(deviceModel!.deviceId) new RSSI: \(newRSSI) (default impl)", tag: TAG)
    }
    
    func handleWifiSetupStateChanged(_ newState: WifiSetupManaging.WifiState) {
        DDLogInfo("Device \(deviceModel!.deviceId) new wifi setup state: \(String(describing: newState)) (default impl)", tag: TAG)
    }
    
    func handleWifiConnected() {
        DDLogInfo("Device \(deviceModel!.deviceId) connected to wifi. (default impl)", tag: TAG)
    }
    
    // Events related to the setup process
    
    func handleManagerStateChanged(_ newState: WifiSetupManagerState) {
        DDLogInfo("Got new wifi setup manager state: \(newState) (default impl)", tag: TAG)
    }
    
    func handleCommandStateChanged(_ newState: WifiSetupManaging.CommandState) {
        
        DDLogInfo("Got new command state: \(newState) (default impl)", tag: TAG)
        
        if let error = WifiSetupError(hubbyCommandState: newState) {
            handleWifiCommandError(error)
        }
    }
    
    func handleWifiCommandError(_ error: Error) {
        DDLogInfo("Device \(deviceModel!.deviceId) encountered command error: \(String(reflecting: error)). (default impl)", tag: TAG)
    }

}

class WifiSetupAwareTableViewController: UITableViewController, Tagged, WifiSetupAware {
    
    var deviceId: String? { return deviceModel?.deviceId }
    
    var deviceModel: DeviceModel?
    
    var wifiSetupManager: WifiSetupManaging? {
        
        willSet {
            wifiEventDisposable = nil
            wifiSetupManager?.stop()
        }
        
        didSet {
            subscribeToWifiSetupManager()
            wifiSetupManager?.start()
        }
    }
    
    var wifiEventDisposable: Disposable? {
        willSet {
            wifiEventDisposable?.dispose()
            DDLogDebug("unsubscribed from wifi event signal.", tag: TAG)
        }
    }
    
    deinit {
        wifiSetupManager = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wifiSetupManager = deviceModel?.getWifiSetupManager()
    }
    
    func handleSSIDListChanged(_ newList: WifiSetupManaging.WifiNetworkList) {
        DDLogInfo("Device \(deviceModel!.deviceId) sees SSIDs: \(String(describing: newList)) (default impl)", tag: TAG)
    }
    
    func handlePasswordCommitted() {
        DDLogInfo("Device \(deviceModel!.deviceId) committed password (default impl)", tag: TAG)
    }
    
    func handleAssociateFailed() {
        DDLogError("Device \(deviceModel!.deviceId) associate failed (default impl)", tag: TAG)
    }
    
    func handleHandshakeFailed() {
        DDLogError("Device \(deviceModel!.deviceId) handshake failed (default impl)", tag: TAG)
    }
    
    func handleEchoFailed() {
        DDLogError("Device \(deviceModel!.deviceId) echo failed (unable to ping Afero cloud) (default impl)", tag: TAG)
    }
    
    func handleSSIDNotFound() {
        DDLogError("Device \(deviceModel!.deviceId) SSID not found (default impl)", tag: TAG)
    }
    
    func handleUnknownFailure() {
        DDLogError("Device \(deviceModel!.deviceId) encountered an unknown wifi setup error. (default impl)", tag: TAG)
    }
    
    // Events related to the currently-configured wifi network
    
    func handleNetworkTypeChanged(_ newType: WifiSetupManaging.NetworkType) {
        DDLogInfo("Device \(deviceModel!.deviceId) network type changed to \(newType) (default impl)")
    }
    
    func handleWifiSteadyStateChanged(_ newState: WifiSetupManaging.WifiState) {
        DDLogInfo("Device \(deviceModel!.deviceId) new wifi steady state: \(newState) (default impl)", tag: TAG)
    }
    
    func handleWifiCurrentSSIDChanged(_ newSSID: String) {
        DDLogInfo("Device \(deviceModel!.deviceId) new SSID: \(newSSID) (default impl)", tag: TAG)
    }
    
    func handleWifiRSSIBarsChanged(_ newRSSIBars: Int) {
        DDLogInfo("Device \(deviceModel!.deviceId) new RSSI Bars: \(newRSSIBars) (default impl)", tag: TAG)
    }
    
    func handleWifiRSSIChanged(_ newRSSI: Int) {
        DDLogInfo("Device \(deviceModel!.deviceId) new RSSI: \(newRSSI) (default impl)", tag: TAG)
    }
    
    func handleWifiSetupStateChanged(_ newState: WifiSetupManaging.WifiState) {
        DDLogInfo("Device \(deviceModel!.deviceId) new wifi setup state: \(String(describing: newState)) (default impl)", tag: TAG)
    }
    
    func handleWifiConnected() {
        DDLogInfo("Device \(deviceModel!.deviceId) connected to wifi. (default impl)", tag: TAG)
    }
    
    // Events related to the setup process
    
    func handleManagerStateChanged(_ newState: WifiSetupManagerState) {
        DDLogInfo("Got new wifi setup manager state: \(newState) (default impl)", tag: TAG)
    }
    
    func handleCommandStateChanged(_ newState: WifiSetupManaging.CommandState) {
        
        DDLogInfo("Got new command state: \(newState) (default impl)", tag: TAG)
        
        if let error = WifiSetupError(hubbyCommandState: newState) {
            handleWifiCommandError(error)
        }
    }
    
    func handleWifiCommandError(_ error: Error) {
        DDLogInfo("Device \(deviceModel!.deviceId) encountered command error: \(String(reflecting: error)). (default impl)", tag: TAG)
    }
    
}

