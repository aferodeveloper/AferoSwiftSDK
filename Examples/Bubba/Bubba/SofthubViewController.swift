//
//  ViewController.swift
//  Bubba
//
//  Created by Justin Middleton on 2/13/18.
//  Copyright © 2018 Afero, Inc. All rights reserved.
//

import UIKit
import Afero

/**
 
 # Enterprise Softhub Control Example
 
 This file demonstrates controlling a softhub in an "enterprise" context, without
 relying upon an internal Afero Client API implemetation, by delegating association
 of a softhub to an account to the user of this app.
 
 Upon startup, the user will be asked for an Afero cloud to which to connect. Once
 that's been done, the softhub will attempt to acquire an `associationId` from afero,
 and upon success, will present the `associationId` both as text and as a QR code.
 
 At this point, the softhub can be associated by:
 1. Scanning the QR code with another Afero app,
 2. Entering the `associationId` into another Afero app manually,
 3. Making a `POST` to the Afero client API endpoint `/v1/accounts/{accountId}/devices`
    directly.
 
 Once the device has been successfully associated, an interface for observing and
 controlling softhub state whill be presented.
 
 */


// MARK: - UserDefaults Convenience Accessors -

fileprivate enum SofthubViewControllerUserDefaultsKey: String {
    
    case softhubAccountId
    case softhubCloud
    case softhubDeviceId
    case softhubEnabled
    
}

fileprivate extension UserDefaults {

    @objc func resetSofthubDefaults() {
        set(nil, forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue)
        self.softhubCloud = nil
    }
    
    /// The device id, if any, for the currently-associated softhub.
    /// Note that this is a cached value; the canonical value is always
    /// `Softhub.shared.deviceId`.

    @objc dynamic var softhubDeviceId: String? {
        get { return string(forKey: SofthubViewControllerUserDefaultsKey.softhubDeviceId.rawValue) }
        set { set(newValue, forKey: SofthubViewControllerUserDefaultsKey.softhubDeviceId.rawValue) }
    }
    
    /// The account id to use for this softhub. A hash of this. This becomes a component
    /// of the path for the local state storage maintained by the softhub itself.
    
    @objc dynamic var softhubAccountId: String {
        
        get {
            
            if let ret = string(forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue) {
                return ret
            }
            
            let ret = UUID().uuidString
            set(ret, forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue)
            return ret
        }
        
        set {
            set(newValue, forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue)
        }
        
    }
    
    /// The Afero cloud to connect to, `.dev` by default.
    
    @objc dynamic var softhubCloudId: String? {
        
        get {
            return string(forKey: SofthubViewControllerUserDefaultsKey.softhubCloud.rawValue)
            
        }
        
        set { set(newValue, forKey: SofthubViewControllerUserDefaultsKey.softhubCloud.rawValue)}
    }
    
    /// Convenience accessor to a reified `SofthubCloud` from the `softhubCloudId`, if available.

    var softhubCloud: SofthubCloud? {
        get { return SofthubCloud(stringIdentifier: softhubCloudId) }
        
        set { softhubCloudId = newValue?.stringIdentifier }
    }
    
    /// Whether or not we should attempt to start the softhub.
    
    @objc dynamic var softhubEnabled: Bool {
        
        get {
            return bool(forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue)
        }
        
        set {
            set(newValue, forKey: SofthubViewControllerUserDefaultsKey.softhubAccountId.rawValue)
        }
        
    }
}

/// Represents what state the interface is in.
/// * `.serviceSelection`: The user is prompted to select a service to
///   which to connect.
/// * `.associationNeeded(id)`: The softhub has acquired an association
///                             id; the user must scan the presented QR code
///                             or manually enter the association id into
///                             an Afero app.
/// * `.associated(deviceId)`: The softhub has been associated, and can be started
///                            and stopped at will by the user.

enum SofthubViewControllerTask: Equatable {

    case serviceSelection
    case associationNeeded(id: String)
    case associated(deviceId: String?, completionReason: SofthubCompletionReason?)
    
    static func ==(lhs: SofthubViewControllerTask, rhs: SofthubViewControllerTask) -> Bool {
        switch (lhs, rhs) {
        case (.serviceSelection, .serviceSelection): return true
        case let (.associationNeeded(lid), .associationNeeded(rid)): return lid == rid
        case let (.associated(lid, lcr), .associated(rid, rcr)): return lid == rid && lcr == rcr
        default: return false
        }
    }
}

// MARK: - SofthubViewController

/// The controller for all views. The SofthubViewController is responsible
/// for observing various aspects of the softhub, responding to requests for
/// information, etc.

@objcMembers class SofhthubViewController: UIViewController {

    // MARK: Task Views
    
    @IBOutlet weak var currentTaskContainerView: UIView!
    @IBOutlet var serviceSelectionView: ServiceSelectionView!
    @IBOutlet var associationNeededView: QRCodeView!
    @IBOutlet var hubControlView: HubControlView!

    // MARK: Versions Labels
    
    @IBOutlet weak var sdkVersionTitleLabel: UILabel!
    @IBOutlet weak var sdkVersionValueLabel: UILabel!
    @IBOutlet weak var softhubVersionTitleLabel: UILabel!
    @IBOutlet weak var softhubVersionValueLabel: UILabel!
    @IBOutlet weak var cloudValueLabel: UILabel!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startObservingSofthubState()
        softhubVersionValueLabel.text = Softhub.shared.version
        
        var cloud = UserDefaults.standard.softhubCloud
        
        if cloud == nil {
            cloud = .prod
            UserDefaults.standard.softhubCloud = cloud
        }
        
        serviceSelectionView.selectedIndex = cloud!.rawValue
    }
    
    // MARK: - KVO
    
    // MARK: - Hub Control

    /// Start the softhub.
    /// If association is required, the softhub will ask us, at which point we'll
    /// display the `associationNeeded` task.
    ///
    /// - parameter accountId: The account id to use.
    /// - parameter cloud: The cloud to which to connect.
    ///
    /// - note: The only explict state we set here is `.associationNeeded(id)`, because
    ///         that is not mapped to a specific softhub state but is an event that fires
    ///         when the softhub has been started by not yet associated (so, technically,
    ///         `Softhub.shared.state` will be `.starting`.
    ///         *All* other states are set though observation of other properties.
    ///
    /// - note: This is also the source of `completeReason`; once we're associated
    ///         (and the softhub's state is "started"), we'll show the `hubControlView`,
    ///         and this is the place where we acquire the complete reason if any.
    
    func startSofthub(with accountId: String, in cloud: SofthubCloud) {
        print("*** Starting softhub with accountId:\(accountId) cloud:\(String(describing: cloud))")
        UserDefaults.standard.softhubCloud = cloud
        Softhub.shared.start(with: accountId, using: cloud, behavingAs: .enterprise, logLevel: .debug, associationHandler: {
            associationId in
            // Note: Used for logging only. See observers for softhub associationId and completeReason.
            print("*** We're being asked to associate \(associationId)")
            }, completionHandler: {
                [weak self] cr in asyncMain {
                    // Note: Used for logging only. See observers for softhub associationId and completeReason.
                    print("*** We've completed with reason: \(String(reflecting: cr))")
                    self?.hubControlView?.completionReason = cr.description
                }
                
            }
        )
    }
    
    /// Stop the softhub.
    func stopSofthub() {
        Softhub.shared.stop()
    }
    
    private var softhubStateObs: NSKeyValueObservation?
    private var softhubDeviceIdObs: NSKeyValueObservation?
    private var softhubAssociationIdObs: NSKeyValueObservation?
    private var softhubCompleteReasonObs: NSKeyValueObservation?
    private var cloudSelectionObs: NSKeyValueObservation?
    
    func startObservingSofthubState() {
        
        /// We learn whether or not we need to be associated here.
        softhubAssociationIdObs = Softhub.shared.observe(\.associationId) {
            [weak self] obj, chg in asyncMain {
                print("*** Association id now: \(String(reflecting: obj.associationId))")
                self?.syncCurrentTask()
            }
        }
        
        /// We get starting, started, stopping, stopped from here.
        softhubDeviceIdObs = Softhub.shared.observe(\.deviceId) {
            [weak self] obj, chg in asyncMain {
                print("*** DeviceId now: \(String(reflecting: obj.deviceId))")
                self?.hubControlView.deviceId = obj.deviceId
                self?.syncCurrentTask()
            }
        }
        
        softhubStateObs = Softhub.shared.observe(\.state) {
            [weak self] obj, chg in asyncMain {
                print("*** SofthubState now: \(String(reflecting: obj.state))")
                self?.hubControlView.status = obj.state.description
                self?.syncCurrentTask()
            }
        }
        
        softhubCompleteReasonObs = Softhub.shared.observe(\.completionReason) {
            [weak self] obj, chg in asyncMain {
                print("*** CompletionReason now: \(String(reflecting: obj.completionReason))")
                let cr = obj.completionReason
                self?.hubControlView.completionReason = cr == .none ? nil : cr.description
                self?.syncCurrentTask()
            }
        }
        
        cloudSelectionObs = UserDefaults.standard.observe(\.softhubCloudId, options: [.initial]) {
            [weak self] obj, chg in asyncMain {
                print("*** Cloud now: \(String(reflecting: obj.softhubCloud))")
                self?.cloudValueLabel.text = UserDefaults.standard.softhubCloud?.stringIdentifier
//                self?.syncCurrentTask()
            }
        }
        
        setCurrentTask(to: .serviceSelection, animated: false)
    }
    
    func syncCurrentTask(animated: Bool = true, completion: @escaping ()->Void = {}) {
        
        let descrim = (UserDefaults.standard.softhubCloud, Softhub.shared.associationId, Softhub.shared.deviceId, Softhub.shared.completionReason)
        
        switch descrim {
            
        // We need to present cloud selector, which also gives us the ability to connect.
        case let (.some(_), .none, deviceId, completionReason):
            setCurrentTask(to: .associated(deviceId: deviceId, completionReason: completionReason), animated: animated, completion: completion)

        // We need to present the QR code bit
        case let (.some(_), .some(associationId), _, _):
            setCurrentTask(to: .associationNeeded(id: associationId), animated: animated, completion: completion)

        default:
            setCurrentTask(to: .serviceSelection, animated: animated, completion: completion)

        }

    }
    
    /// The current task state, set by `syncState().
    
    func setCurrentTask(to newTask: SofthubViewControllerTask, animated: Bool = false, completion: @escaping ()->Void = {}) {
        
        guard newTask != _currentTask  else {
            completion()
            return
        }
        
        guard let taskView = taskView(for: newTask) else {
            completion()
            return
        }
        
        _currentTask = newTask
        
        transitionTo(taskView: taskView, animated: animated, completion: completion)
    }
    
    private var _currentTask: SofthubViewControllerTask?
    
    func taskView(for task: SofthubViewControllerTask?) -> UIView? {
        
        guard let task = task else { return nil }
        switch task {
        case .serviceSelection: return serviceSelectionView
        
        case let .associationNeeded(associationId):
            associationNeededView.associationId = associationId
            return associationNeededView
            
        case .associated: return hubControlView
            
        }
        
    }
    
    var currentTaskView: UIView? {
        return currentTaskContainerView.subviews.first
    }
    
    func transitionTo(taskView view: UIView, animated: Bool = true, completion: @escaping ()->Void = { }) {
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let configureConstraints: (UIView)->Void = {
            view in
            
            NSLayoutConstraint.activate(
                [
                    "H:|-[v]-|",
                    "V:|-(>=0)-[v]-(>=0)-|",
                    ].flatMap {
                        NSLayoutConstraint.constraints(
                            withVisualFormat: $0,
                            options: [],
                            metrics: [:],
                            views: ["v": view]
                        )
                }
            )
            
            NSLayoutConstraint.activate([
                NSLayoutConstraint(
                    item: view,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self.currentTaskContainerView,
                    attribute: .centerY,
                    multiplier: 1.0,
                    constant: 0
                ),
            ])
            
        }
        
        guard animated else {
            currentTaskView?.removeFromSuperview()
            currentTaskContainerView.addSubview(view)
            configureConstraints(view)
            completion()
            return
        }
        
        guard let currentTaskView = currentTaskView else {
            currentTaskContainerView.addSubview(view)
            configureConstraints(view)
            completion()
            return
        }
        
        UIView.transition(
            with: currentTaskContainerView,
            duration: 0.125,
            options: [
                .allowAnimatedContent,
                .beginFromCurrentState,
                .layoutSubviews,
                .curveEaseInOut,
                .transitionCrossDissolve
            ],
            animations: {
                [weak self] in
                currentTaskView.removeFromSuperview()
                self?.currentTaskContainerView.addSubview(view)
                configureConstraints(view)
                
        }, completion: {
            completed in
            print("completed: \(completed)")
            completion()
        })

    }

    func handleSofthubAssociationNeeded(for associationId: String) {
        syncCurrentTask(animated: true)
    }
    
    func handleSofthubCompleted(with completionReason: SofthubCompletionReason) {
        syncCurrentTask(animated: true)
    }


}

extension SofhthubViewController: ServiceSelectionViewDelegate {
    
    func numberOfServices(for selectionView: ServiceSelectionView) -> Int {
        return SofthubCloud.allValues.count
    }
    
    func titleForService(at index: Int, in selectionView: ServiceSelectionView) -> String {
        return SofthubCloud.allValues[index].description
    }
    
    func selectedIndexChanged(to index: Int, in selectionView: ServiceSelectionView) {
        let cloud = SofthubCloud.allValues[index]
        UserDefaults.standard.softhubCloud = cloud
        print("Selection changed to \(cloud) (\(index)).")
    }
    
    func nextTapped(in selectionView: ServiceSelectionView) {
        print("Next tapped!")
        let cloud = SofthubCloud.allValues[selectionView.selectedIndex]
        let accountId = UserDefaults.standard.softhubAccountId
        startSofthub(with: accountId, in: cloud)
    }
    
}

extension SofhthubViewController: HubControlViewDelegate {

    func hubResetRequested(for hubControlView: HubControlView) {
        stopSofthub()
        UserDefaults.standard.resetSofthubDefaults()
        syncCurrentTask()
    }
    
    
    func hubEnabledValueChanged(to enabled: Bool, for hubControlView: HubControlView) {
        
        if enabled {

            guard let softhubCloud = UserDefaults.standard.softhubCloud else {
                syncCurrentTask()
                return
            }
            
            startSofthub(with: UserDefaults.standard.softhubAccountId, in: softhubCloud)
            return
        }
        
        stopSofthub()
        
    }
    
    
}

