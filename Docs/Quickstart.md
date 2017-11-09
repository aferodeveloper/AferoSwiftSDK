# Afero SDK Quickstart

## Imports

```swift
import UIKit

import Afero
import ReactiveSwift
```

## Protocols

The following are among the protocols are defined by `Afero`, and are required
for this example.

```swift
// MARK: - <ConclaveAuthable>, defined in AferoSwiftSDK

public typealias AuthConclaveOnDone = (ConclaveAccess?, Error?) -> Void

public protocol ConclaveAuthable: class {
    var conclaveClientVersion: String { get }
    var conclaveClientType: String { get }
    var conclaveMobileDeviceId: String { get }
    func authConclave(_ accountId: String, onDone: @escaping AuthConclaveOnDone)
}

// MARK: - <DeviceCollectionDelegate>, defined in AferoSwiftSDK

public protocol DeviceCollectionDelegate: class {
    func isTraceEnabled(for accountId: String) -> Bool
    func deviceCollectionShouldStart(_ deviceCollection: DeviceCollection) -> Bool
}

// MARK: - <DeviceBatchActionRequestable>, defined in AferoSwiftSDK

public typealias PostBatchActionRequestOnDone = (DeviceBatchAction.Results?, Error?) -> Void

public protocol DeviceBatchActionRequestable: class {
    func post(actions: [DeviceBatchAction.Request], forDeviceId deviceId: String, withAccountId accountId: String, onDone: @escaping PostBatchActionRequestOnDone)
}
```

## HTTP Client

By default, `Afero` expresses no opinion about the HTTP client implementation you use;
instead, you're responsible for supplying protocol implementations. In this example,
we'll assume that you have an HTTP client class called `MyAPIClient`, and add the required
protocol support to it via an extension:

```swift
// MARK: - Your HTTP client

class MyAPIClient { ... }

extension MyAPIClient: DeviceBatchActionRequestable {

    func post
        (actions: [DeviceBatchAction.Request],
        forDeviceId deviceId: String,
        withAccountId accountId: String,
        onDone: @escaping PostBatchActionRequestOnDone)

    {
        POST(...) { maybeResults, maybeError in onDone(maybeResults, maybeError) }
    }
}
```

## ViewController

With the HTTP client in place, we're ready to implement our `ViewController`.

```swift
// MARK: - Your ViewController Code

class DeviceCollectionViewController: UIViewController, DeviceCollectionDelegate, ConclaveAuthable, DeviceBatchActionRequestable {

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

```
Central to all interaction with Afero is the `DeviceCollection`; it manages a realtime
connection with the Afero service, providing account membership, device status, and device
attribute state information, as well as notification of various "invalidation" events
(more on this later).

```swift
        deviceCollection = DeviceCollection(
            delegate: self,
            profileSource: <# Your DeviceAccountProfilesSource impl #>
            authable: self,
            accountId: accountId,
            batchActionRequestable: <# Your DeviceBatchActionRequestable impl #>
        )
    }

    deinit {
        deviceCollection = nil
    }

    // MARK: - DeviceCollection Observation

    /// Holder for our Reactive `Disposable` for our `DeviceCollection`'s
    /// `contentsSignal`

    var deviceCollectionContentsDisposable: Disposable? {
        willSet { deviceCollectionContentsDisposable?.dispose() }
    }

    /// Holder for our Reactive `Disposable` for our `DeviceCollection`'s
    /// `stateSignal`

    var deviceCollectionStateDisposable: Disposable? {
        willSet { deviceCollectionStateDisposable?.dispose() }
    }

    /// The DeviceCollection we'll observe. Setting this
    /// automatically disposes any previous `deviceCollectionDisposable`, and,
    /// if the deviceCollection is non-nil, subscribes its `contentsSignal`
    /// for content events.

    var deviceCollection: DeviceCollection? {

        willSet { deviceCollectionContentsDisposable = nil }

        didSet {

            deviceCollectionContentsDisposable = deviceCollection?.contentsSignal
                .observe(on: QueueScheduler.main)
                .observeValues {
                    [weak self] event in switch event {

                    // A device was added to the DeviceCollection
                    // Show in device list, etc.
                    case .create(let device): self?.deviceCollectionCreated(device: device)

                    // A device was removed from the DeviceCollection;
                    // Remove device from UI
                    case .delete(let device): self?.deviceCollectionRemoved(device: device)

                    // The DeviceCollection removed all devices; clear UI
                    case .resetAll: self?.deviceCollectionReset()

                    }
            }

            deviceCollectionStateDisposable = deviceCollection?.stateSignal
                .observe(on: QueueScheduler.main)
                .observeValues {
                    [weak self] state in switch state {

                    // The DeviceCollection entered a `.loading` state
                    // Show spinner/activity indicator
                    case .loading: self?.deviceCollectionStartedLoading()

                    // The DeviceCollection finished loading
                    // All systems go
                    case .loaded: self?.deviceCollectionDidLoad()

                    // The DeviceCollection unloaded; maybe show zero state?
                    case .unloaded: self?.deviceCollectionDidUnload()

                    // The DeviceCollection encountered an error; handle
                    // accordingly
                    case .error(let maybeError): self?.deviceCollectionEmittedError(maybeError)
                    }
            }
        }
    }

    func deviceCollectionCreated(device: DeviceModel) { }

    func deviceCollectionRemoved(device: DeviceModel) { }

    func deviceCollectionReset() { }

    func deviceCollectionStartedLoading() { }

    func deviceCollectionDidLoad() { }

    func deviceCollectionDidUnload() { }

}
```
