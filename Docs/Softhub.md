---
author: Justin Middleton <jrmiddle@afero.io>
title: "Afero Softhub"
date: Feb 9, 2018 4:21 PM
release: 1.0.8
status: 1.0
---

**AFERO CONFIDENTIAL AND PROPRIETARY INFORMATION**

© Copyright 2018 Afero, Inc, All Rights Reserved.

Any use and distribution of this software is subject to the terms
of the License and Services Agreement between Afero, Inc. and licensee.

SDK products contain certain trade secrets, patents, confidential and
proprietary information of Afero.  Use, reproduction, disclosure
and distribution by any means are prohibited, except pursuant to
a written license from Afero. Use of copyright notice is
precautionary and does not imply publication or disclosure.

**Restricted Rights Legend:**

Use, duplication, or disclosure by the Government is subject to
restrictions as set forth in subparagraph (c)(1)(ii) of The
Rights in Technical Data and Computer Software clause in DFARS
252.227-7013 or subparagraphs (c)(1) and (2) of the Commercial
Computer Software--Restricted Rights at 48 CFR 52.227-19, as
applicable.

# Afero Softhub

# In This Document

<!-- @import "[TOC]" {cmd:"toc", depthFrom:2, depthTo:6, orderedList:true} -->
<!-- code_chunk_output -->

* [Afero Softhub](#afero-softhub)
* [In This Document](#in-this-document)
	* [Overview](#overview)
	* [Quickstart](#quickstart)
		* [Configure your Podfile](#configure-your-podfile)
		* [Configure your app](#configure-your-app)
			* [Start the Softhub](#start-the-softhub)
			* [Stop the Softhub](#stop-the-softhub)
	* [Detailed Description](#detailed-description)
		* [`Afero.Softhub`](#aferosofthub)
			* [Properties](#properties)
			* [Methods](#methods)
		* [Softhub Association](#softhub-association)
			* [`AferoLab.SofthubMinder` example code](#aferolabsofthubminder-example-code)
	* [Appendix: Softhub Public Interface](#appendix-softhub-public-interface)
		* [Softhub](#softhub)
		* [`SofthubCloud`](#softhubcloud)
		* [`SofthubLogLevel`](#softhubloglevel)
		* [`SofthubState`](#softhubstate)
		* [`SofthubCompletionReason`](#softhubcompletionreason)
	* [See Also](#see-also)
	* [Colophon](#colophon)

<!-- /code_chunk_output -->


## Overview

The Afero Softhub is an auxiliary component of the Afero SDK which
provides a means for Afero peripheral devices to communicate with the Afero
cloud using a mobile device's network connection (WiFi or cellular). It operates
independent of other Afero SDK components, and the SDK user need only start
and stop the Softhub as appropriate. The softhub, meanwhile, handles:

1. Bluetooth-based Afero device discovery and connectivity.
2. Automatic Over-the-Air (OTA) updates to Afero device firmware.
3. Secure configuration of WiFi connectivity for WiFi-compatible Afero devices.

## Quickstart

### Configure your Podfile

```ruby
source 'git@github.com:aferodeveloper/Podspecs.git'
source 'https://github.com/CocoaPods/Specs.git'

pod `AferoSwiftSDK`
```

### Configure your app

Your app should be configured with the `bluetooth-central` background mode:

1. In **XCode**, select your app target.
2. Click the **Capabilities** tab.
3. Enable **Background Modes**
4. Check **Uses Bluetooth LE accessories**

Alternatively, add `bluetooth-central` to the `UIBackgroundModes` value of your
app's `Info.plist`

> **NOTE**
> Implementors are also expected to manage softhub state *vis à vis* application
background state, while being mindful of active OTAs in progress. See
[below](#UIApplication-Lifecycle-and-the-Softhub) for an explanation and a
reference to example code.

#### Start the Softhub

```swift
import Afero

let accountId: String = "some_account_id"
let cloud: SofthubCloud = .prod
let softhubIdentifier = NSUUID().uuidString

Softhub.shared.start(
    with: accountId,
    logLevel: logLevel,
    associationHandler: {
        (associationId: String) -> Void in
        // See "Softhub Association", below.    
        print("The softhub asks to associate with association id \(associationId) on \(cloud)")
    },
    completionHandler: {
        (completionReason: SofthubCompletionReason) -> Void in
        DDLogInfo("Softhub stopped with reason \(String(reflecting: completionReason))")
    })

```

> **NOTE**
>
> The `associationHandler` closure above is a stub; the developer must provide a working implementation.
See [Softhub Association](#softhub-association) below for details.

#### Stop the Softhub

```swift
import Afero
Softhub.shared.stop()
```

## Detailed Description

### `Afero.Softhub`

The public implementation for the Afero Softhub can be found in the [Softhub]
class, in the `Afero` module vended by [AferoSwiftSDK]. This class, compatible
with Objective-C and Swift, provides a high-level interface for starting and
stopping the softhub, as well as  information about the softhub's current state.


```puml

folder aferodeveloper/AferoSwiftSDK {

    package Afero {

        class SoftHub {
            {field} state: SofthubState
            {field} deviceId: String?
            {field} activeOTACount: Int

            {method} start(accountId:cloud:identifier:associationHandler:completionHandler)
            {method} stop()
        }

    }

}

```

#### Properties

| Name | Type | Description |
| - | - | - |
| `state` | `SofthubState` | The current state of the softhub. |
| `deviceId` | `Optional<String>` | Once connected to the Afero cloud, the associated `DeviceModel`'s `deviceId`. This can be used to identify the local SoftHub in a `DeviceCollection`.
| `activeOTACount` | `Int` | The number of currently-active over-the-air updates being serviced by this SoftHub instance. |

#### Methods

| Name | Description |
| - | - |
| start() | Start the softhub. See [Appendix](#softhub) for a description of parameters. See [Softhub Association](#softhub-association) for an explanation of the association process.
| stop() | Stop the softhub.

### Softhub Association

The Afero Softhub attaches to an Afero account by acting as a logical Afero device, and
therefore must be associated with an account before it is able to communicate
with physical Afero peripheral devices. Once associated, it saves its
configuration so that subsequent starts against the same account do not require
an association step.

To accomplish association, the Softhub delegates device association to the caller
of `start(with:loglevel:associationHandler:completionHandler)`,
via the `associationHandler: @escaping (String)->Void` parameter. It is expected
that this invocation will result in a POST to the Afero client API:

```
    POST https://api.afero.io/v1/accounts/$accountId$/devices
```

The body of this request should be JSON-formatted, as such:

```json
{ associationId: "ASSOCIATION_ID" }
```

If an `AferoAPIClient` implementor is being used, such as
`AFNetworkingAferoAPIClient`, then
`associateDevice(with:to:locatedAt:ownershipTransferVerified:expansions)` can be
used for this purpose. See `AferoAPIClient+Device.swift` for more info.

Once the softhub has associated with an account, it will complete its startup
process after locally persisting configuration.

> **NOTE**
>
> Softhub configuration is stored in the client's filesystem, and the path to
the configuration is determined in part by hashing the `accountId` value. Upon
subsequent starts using the same `accountId`, the softhub will connect directly
to the Afero service requiring association. For this reason, its highly
desirable that the `accountId` parameter be the same for each account, and that
it differ from one account to another. Afero recommends using an actual Afero
account id, which is a UUID.

#### `AferoLab.SofthubMinder` example code

`Afero.Softhub` provides a high-level interface to manipulating and observing
the softhub, but it delegates determination of when to start and stop the softhub
to the SDK user. On iOS, for example, it is **important to stop the softhub when
the app enters the background, except if the softhub is currently serving an
over-the-air update to a connected Afero device**. In this case, it's desirable to
allow the softhub to run in the background until all OTAs have been completed.

The [SofthubMinder] class, in the [AferoLab] sample code, provides an example of
managing softhub state based upon application state, OTA state, and whether or not
the softhub should be started at all. While not a part of the official SDK _per se_,
SDK users are free to use this code and modify it to their tastes.

## Appendix: Softhub Public Interface

### Softhub

```swift
/// A Swift wrapper around the Afero softhub software. This is the lowest-level
/// interface available to non-Afero developers.
@objcMembers public class Softhub : NSObject {

    /// The softhub is a shared singleton; this gives access to it.
    public static let shared: main.Softhub

    /// The current state of the softhub. KVO-compliant.
    private(set) public dynamic var state: SofthubState

    /// The current deviceId, if any, of the softhub. KVO-compliant.
    ///
    /// This value can be used to identify the local softhub among devices
    /// in a `DeviceCollection`.
    /// - note: This value will be `nil` if the softhub is in any state
    ///         other than `.started`
    private(set) public dynamic var deviceId: String?

    /// The number of Over-The-Air peripheral device updates (firmware or profile)
    /// that are currently happening via this softhub.
    ///
    /// The Softhub can act as a conduit for OTA updates to peripheral
    /// devices. While the softhub not intended to run in the background
    /// normally, it is often desirable to allow it to run int he background
    /// when OTAs are active, and to stop it once they've completed.
    ///
    /// This value can be observed so that whichever class is managing the
    /// softhub lifecycle can determine if and when it's appropriate to
    /// keep the hub running or shut it down depending upon application state.
    ///
    /// - seealso: `SofthubMinder.swift` in the AferoLab example app.
    private(set) public dynamic var activeOTACount: Int

    /// Ask the softhub to start.
    ///
    /// - parameter accountId: A string that is unique to the account to which the
    ///             softhub will be associated. An actual Afero account id is sufficient,
    ///             but any string unique to a given account will do. See **Associating**.
    ///
    /// - parameter cloud: The cloud to which to connect. Defaults to `.prod`, and should not
    ///             be changed for production applications.
    ///
    /// - parameter softhubType: Identifies the behavior a softhub should declar when it associates
    ///             with the service. Unless otherwise instructed by Afero, this should be
    ///             `.consumer`, the default. **This cannot be changed after a hub has been
    ///             associated**.
    ///
    /// - parameter identifier: A string which, if present, is added to the HUBBY_HARDWARE_INFO
    ///             attribute of the softhub's device representation. It can be used to distinguish
    ///             the local softhub from others.
    ///
    /// - parameter associationhandler: A callback which takes an `associationId` in the form of
    ///             a string, and performs a call against the appropriate Afero REST API
    ///             to associate.
    ///
    /// - parameter completionHandler: A callback called when the softhub stops. The reason
    ///             for stopping is provided as the sole parameter.
    ///
    /// # Overview
    ///
    /// The Afero Softhub runs on its own queue and provides a means for Afero peripheral devices
    /// to communicate with the Afero cloud using a mobile device's network connection
    /// (WiFi or cellular). It operates independent of other Afero SDK components,
    /// and the implementor need only start and stop the Softhub as appropriate.
    ///
    /// # Lifecycle
    ///
    /// The Afero Softhub attaches to an Afero account by acting as another device, and therefor
    /// must be associated with an account before it is able to communicate with
    /// physical Afero peripheral devices. Once associated, it saves its configuration
    /// so that subsequent starts against the same account do not require an association step.
    ///
    /// To accomplish association, the Softhub delegates device association to the caller
    /// of `start(with:using:identifiedBy:loglevel:associationHandler:completionHandler)`,
    /// via the `associationHandler: @escaping (String)->Void` parameter. It is expected
    /// that this invocation will result in a POST to the Afero client API:
    ///
    ///
    /// ```
    ///     POST https://api.afero.io/v1/accounts/$accountId$/devices
    /// ```
    ///
    /// The body of this request should be JSON-formatted, as such:
    /// ```
    /// { associationId: "ASSOCIATION_ID" }
    /// ```
    ///
    /// If an `AferoAPIClient` implementor is being used, such as `AFNetworkingAferoAPIClient`,
    /// then `associateDevice(with:to:locatedAt:ownershipTransferVerified:expansions)` can be used
    /// for this purpose. See `AferoAPIClient+Device.swift` for more info.
    ///
    /// Once a softhub has associated with an account,
    /// it saves its configuration info locally to a path determined in part by
    /// hashing the `accountId` value. Upon subsequent starts using the same `accountId`,
    /// the softhub will connect directly to the Afero service requiring association.
    /// For this reason, its highly desirable that the `accountId` parameter be the same
    /// for each account, and that it differ from one account to another. Afero recommends
    /// using an actual Afero account id, which is a UUID.
    public func start(with accountId: String, using cloud: SofthubCloud = default, behavingAs softhubType: SofthubType = default, identifiedBy identifier: String? = default, logLevel: SofthubLogLevel, associationHandler: @escaping (String) -> Void, completionHandler: @escaping (SofthubCompletionReason) -> Void)

    /// Stop the Softhub. The Softub will terminate immediately,
    /// and the `completionHandler` passed to `start(_:_:_:_:_:_:)` will be
    /// invoked with `SofthubCompletionReason.stopCalled`.
    ///
    /// Immediately upon calling this, `state` will change to `.stopping`, and
    /// once the `completionHandler` is called, `.stopped`.
    ///
    /// - seealso: `var state: SofthubState`
    public func stop()
}



```

### `SofthubCloud`

> **NOTE**
>
> `SofthubCloud` is provided for informational purposes only. The `cloud` parameter to `Softhub.start()` defaults to `.prod`
> and should not be changed by external developers.

```swift
/// The Afero cloud to which a softhub should attempt to connect.
/// For production applications, this should always be `.prod`.
///
/// # Cases
///
/// * `.prod`: The Afero production cloud. Third parties should always use this.
/// * `.dev`: The Afero development cloud. Production apps and third parties should never use this.
@objc public enum SofthubCloud : Int, CustomStringConvertible, CustomDebugStringConvertible {

    /// The Afero production cloud. Third parties should always use this.
    case prod

    /// The Afero development cloud. Production apps and third parties should never use this.
    case dev
}
```

### `SofthubLogLevel`

```swift
/// The level at which the Softhub should log.
@objc public enum SofthubLogLevel : Int, CustomStringConvertible, CustomDebugStringConvertible {
    case none
    case error
    case warning
    case info
    case debug
    case verbose
    case trace
}
```

### `SofthubState`

```swift
@objc public enum SofthubState : Int, CustomStringConvertible, CustomDebugStringConvertible {
    case stopping
    case stopped
    case starting
    case started
}

```

### `SofthubCompletionReason`

```swift
@objc public enum SofthubCompletionReason : Int, CustomStringConvertible, CustomDebugStringConvertible {
    case stopCalled
    case missingSetupPath
    case unhandledService
    case fileIOError
    case setupFailed
}
```

## See Also

| Title/Link | Description |
| - | - |
| [AferoDeveloper on GitHub][aferodeveloper] | The main Afero developer GitHub site |
| [AferoIOSSofthub] | Binary distribution for the Afero softhub. |
| [AferoSwiftSDK] | Source repo for the Afero SDK for Swift / iOS |
| [SofthubMinder] | Example code for managing softhub state *vis á vis*  UIApplication lifecycle. |

[aferodeveloper]: https://github.com/aferodeveloper
[AferoIOSSofthub]: https://github.com/aferodeveloper/AferoIOSSofthub
[AferoSwiftSDK]: https://github.com/aferodeveloper/AferoSwiftSDK
[AferoLab]: https://github.com/aferodeveloper/AferoSwiftSDK/tree/master/Examples/AferoLab
[Softhub]: https://github.com/aferodeveloper/AferoSwiftSDK/blob/f87b691c571c1945feba43e800065e77ce075678/AferoSwiftSDK/Core/AferoSofthub%2BUtils.swift#L220
[SofthubMinder]:https://github.com/aferodeveloper/AferoSwiftSDK/blob/master/Examples/AferoLab/AferoLab/SofthubMinder.swift

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/),
[Mermaid](https://mermaidjs.github.io) for sequence diagrams, and
[PlantUML](http://plantuml.com) for UML.

Creation was done in [Atom](), with rendered output created using [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).
