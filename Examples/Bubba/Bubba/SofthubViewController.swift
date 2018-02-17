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
    case associated(deviceId: String, completionReason: SofthubCompletionReason?)
    
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

    @IBOutlet weak var currentStateMessageLabel: UILabel!
    @IBOutlet weak var currentStateDetailLabel: UILabel!
    
    // MARK: Task Views
    
    @IBOutlet weak var currentTaskContainerView: UIView!
    @IBOutlet var serviceSelectionView: ServiceSelectionView!
    @IBOutlet var associationNeededView: QRCodeView!
    @IBOutlet var hubControlView: HubControlView!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startObservingSofthubState()
        startObservingPrefs()
    }
    
    // MARK: - KVO
    
    /*
     
     We're using UserDefaults as our "model". Display state is entirely determined by observation of four things:
     
     * In UserDefaults, the accountId, cloud, and deviceId.
     * On the Softhub, the state.
 
     */
    
    private var defaultsAccountIdObs: NSKeyValueObservation?
    private var defaultsCloudObs: NSKeyValueObservation?
    private var defaultsDeviceIdObs: NSKeyValueObservation?
    
    func startObservingPrefs() {
        
        /// If the user changes the cloud, then we tear everything down.
        defaultsCloudObs = UserDefaults.standard.observe(\.softhubCloudId, options: [.initial]) {
            [weak self] obj, chg in
            self?.stopSofthub()
        }
        
//        defaultsDeviceIdObs = UserDefaults.standard.obseve(\.)
        
    }
    
    /// Handle any task state changes as per changes to UserDefaults.
    /// We don't handle absolutely everything here; for example, we enter
    /// `.associationNeeded` in response to the softhub asking for association.
    
    func syncTaskToDefaults() {
        
        // If we don't have a softhub cloud, that means we need to
        // present it to the user.
        guard let _ = UserDefaults.standard.softhubCloud else {
            currentTask = .serviceSelection
            return
        }
        
    }
    
    // MARK: - Hub Control

    /// Start the softhub, using the `accountId` and `cloud` stored in `UserDefaults`.
    /// If association is required, the softhub will ask us, at which point we'll
    /// display the `associationNeeded` task.
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
    
    func startSofthub() {
        
        guard let cloud = UserDefaults.standard.softhubCloud else {
            syncState()
            return
        }

        let accountId = UserDefaults.standard.softhubAccountId

        Softhub.shared.start(with: accountId, using: cloud, behavingAs: .enterprise, logLevel: .debug, associationHandler: {
            associationId in
            // Note: Used for logging only. See observers for softhub associationId and completeReason.
            NSLog("We're being asked to associate \(associationId)")
            }, completionHandler: {
                [weak self] cr in asyncMain {
                    // Note: Used for logging only. See observers for softhub associationId and completeReason.
                    NSLog("We've completed with reason: \(String(reflecting: cr))")
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
    
    func startObservingSofthubState() {
        
        /// We learn whether or not we need to be associated here.
        softhubAssociationIdObs = Softhub.shared.observe(\.associationId) {
            [weak self] obj, chg in self?.syncState()
        }
        
        /// We get starting, started, stopping, stopped from here.
        softhubDeviceIdObs = Softhub.shared.observe(\.deviceId) {
            [weak self] obj, chg in self?.syncState()
        }
        
        softhubStateObs = Softhub.shared.observe(\.state) {
            [weak self] obj, chg in self?.syncState()
        }
        
        softhubCompleteReasonObs = Softhub.shared.observe(\.completionReason) {
            [weak self] obj, chg in self?.syncState()
        }
        
        syncState()
    }
    
    func syncState() {
        
        switch (Softhub.shared.state, Softhub.shared.associationId, Softhub.shared.deviceId, Softhub.shared.completionReason) {
            
        // We need to present cloud selector, which also gives us the ability to connect.
        case let (_, .none, .some(deviceId), completionReason):
            self.currentTask = .associated(deviceId: deviceId, completionReason: completionReason)
            
        // We need to present the QR code bit
        case let (_, .some(associationId), _, _):
            self.currentTask = .associationNeeded(id: associationId)

        default:
            self.currentTask = .serviceSelection
            
        }

    }
    
    /// The current task state, set by `syncState().
    var currentTask: SofthubViewControllerTask = .serviceSelection {
        
        didSet {
            if oldValue == currentTask { return }
            transitionTo(taskView: taskView(for: currentTask), animated: true, completion: { })
        }
        
    }
    
    func taskView(for task: SofthubViewControllerTask) -> UIView {
        
        switch task {
        case .serviceSelection: return serviceSelectionView
        case .associationNeeded: return associationNeededView
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
                ["H:|[v]|", "V:|[v]|"].flatMap {
                    NSLayoutConstraint.constraints(
                        withVisualFormat: $0,
                        options: [],
                        metrics: [:],
                        views: ["v": view]
                    )
                }
            )
        }
        
        guard animated else {
            currentTaskView?.removeFromSuperview()
            currentTaskContainerView.addSubview(view)
            configureConstraints(view)
            return
        }
        
        guard let currentTaskView = currentTaskView else {
            currentTaskContainerView.addSubview(view)
            configureConstraints(view)
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
                .transitionFlipFromLeft
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
//        syncTaskView()
    }
    
    func handleSofthubCompleted(with completionReason: SofthubCompletionReason) {
//        syncTaskView()
    }


}

extension SofhthubViewController: ServiceSelectionViewDelegate {
    
    func numberOfServices(for selectionView: ServiceSelectionView) -> Int {
        return SofthubCloud.allValues.count
    }
    
    func titleForService(at index: Int, in selectionView: ServiceSelectionView) -> String {
        return SofthubCloud.allValues[index].description
    }
    
    
}

extension SofhthubViewController: HubControlViewDelegate {
    
    func hubEnabledValueChanged(to enabled: Bool, for hubControlView: HubControlView) {
        print("Enabled value changed to \(enabled)")
    }
    
}

