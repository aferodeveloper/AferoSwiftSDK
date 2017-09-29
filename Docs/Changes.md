---
title: Changes
author: Justin Middleton <jrmiddle@afero.io>
---

# Changes

## Milestone 3 / SDK v0.8

### XCode 9 / Swift 4 support

As of **SDK 0.8.2**, AferoSwiftSDK pod can be linked to Swift 3.2 and Swift 4.0 projects.
The `Afero` module itself is still Swift 3.2, however, so in Xcode 9 projects,
it's required that a `post_install` hook be configured `Podfile` to indicate
direct Xcode to use the correct Swift version.

To see this in action, the `AferoLab` and `AferoSwiftSDK` targets in the example project
have been ported to Swift 4.0, and a `post_install` hook has been added to the Podfile:

```ruby
# Credit to GitHub member "cocojoe", in a comment on this thread:
# https://github.com/auth0/Lock.swift/issues/470

post_install do |installer|

  # List of Pods to use as Swift 3.2
  myTargets = ['AferoSwiftSDK', 'ReactiveSwift']

  installer.pods_project.targets.each do |target|
    if myTargets.include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '3.2'
      end
    end
  end
end
```

### API Changes

#### Overview

* **Offline schedule entry times are now expressed in peripheral-local time, and migration from UTC schedules is supported** ([see below](#offline-schedules))

* Timezones can now be set directly on `DeviceModelable` instances ([see below](#setting-peripheral-timezone))

* Non-presentable devices are no longer elided ([see below](#non-presentable-devices-no-longer-elided))

* Conclave access token acquisition has been simplified ([see below](#conclave-access-simplification))


* `DeviceBatchActionRequestable` has been renamed to `DeviceActionable`.

* `AferoSofthub` start methods now support a `hardwareIdentifier` string; this is used when associating the softhub with the service, and is reflected in the `.softhubHardwareInfo` property on `DeviceModelable`s representing softhubs. This facility can be used to determine whether a given softhub is the softhub running on the local mobile device.

* The `DeviceCollection` now processes individual devices returned either by querying the Client API or as a result of receiving a `peripheralList` Conclave message, in separate tasks, rather as one blocking task.

* Redundant `.create` messages emitted by the `DeviceCollection` have been eliminated.

* A problem with device association which resulted in the association failing, but the device not being returned in `DeviceCollection.addDevice() -> Promise<DeviceModel>` promise resolution has been fixed.

* The `AferoSwiftLogging` prerequesite has been removed.

* Overall logging verbosity has been squelched.

#### Non-presentable devices no longer elided

In SDK v0.7 and prior, the DeviceCollection elided devices with nil `presentation` properties in their profiles. This was a behavioral difference compared to the Android SDK, which has always retained non-presentable devices and let the developer decide whether or not to display them.

In SDK v0.8, the Swift `DeviceCollection` now behaves consistently with Android, and presentability of devices can be checked with `DeviceModelable.isPresentable: Bool`. See `AccountInfoTableViewController` in the AferoLab example project for an example.

#### Conclave Access Simplification

SDK v0.7 and earlier versions used a `ConclaveAccess` endpoint that required
the developer to create a unique client UUID, register it with the Client API using the `mobileDevices` endpoint, and then call the `conclaveAuth` endpoint to fetch Conclave access tokens:

```swift
public func authConclave(
    accountId: String,
    userId: String,
    mobileDeviceId: String
) -> Promise<ConclaveAccess>
```

SDK v0.8 removes this requirement, and now only an `accountId` is required:

```swift
public func authConclave(accountId: String) -> Promise<ConclaveAccess>
```

Furthermore, it is unnecessary to register a unique client ID with the
Afero cloud for the purposes of Conclave auth. Registration of a unique
id _is_ required for push notification support.

See changes to `Examples/AferoLab/AferoLab/AccountInfoTableViewController.swift`
for details.


#### Offline Schedules

In SDK v0.7, the times specified in offline schedules (schedules which are
stored in attributes on-device and don't require the Afero cloud to execute)
were specified in the UTC timezone, and computed accessors were provided for
working with time specifications in the mobile device's local timezone.

In SDK 0.8, this changes. By default, times are assumed to be in the Afero
peripheral's local timezone, whatever that is, and use of UTC timezones is
deprecated. Consequently, `utcHour, ...`, and `localHour, ...` accessors on
`OfflineSchedule.ScheduleEvent.TimeSpecification` have been removed, and `day`,
`hour`, `minute` should be used instead.

##### UTC → Local Time Migration

To ease the adoption of local time `TimeSpecification`s for offline schedules, the `DeviceCollection` now
automatically migrates schedules from UTC to a peripheral's timezone, as long as
s the peripheral has a timezone. Timezones can be set on peripherals at
association time, or later. Once the timeZone is set on a peripheral, the
migration process will start.

##### Setting peripheral TimeZone

At association time:
```swift
/// Add a device to the device collection.
///
/// - parameter associationId: The associationId for the device. Note that this is different from the deviceId.
/// - parameter location: The location, if any, to associate with the device.
/// - parameter isOwnershipChangeVerified: If the device is eligible for ownership change (see note), and
///                                        `isOwnershipChangeVerified` is `true`, then the device being scanned
///                                        will be disassociated from its existing account prior to being
///                                        associated with the new one.
/// - parameter timeZone: The timezone to use for the device. Defaults to `TimeZone.current`.
/// - parameter timeZoneIsUserOverride: If true, indicates the user has explicitly set the timezone
///                             on this device (rather than it being inferred by location).
///                             If false, timeZone is the default timeZone of the phone.
/// - parameter onDone: The completion handler for the call.
///
/// ## Ownership Transfer
/// Some devices are provisioned to have their ownership transfer automatically. If upon an associate attempt
/// with `isOwnershipTransferVerified == false` is made upon a device that's assocaiated with another account,
/// and an error is returned with an attached URLResponse with header `transfer-verification-enabled: true`,
/// then the call can be retried with `isOwnershipTranferVerified == true`, and the service will disassociate
/// said device from its existing account prior to associating it with the new account.

func addDevice(with associationId: String, location: CLLocation? = nil, isOwnershipChangeVerified: Bool = false, timeZone: TimeZone = TimeZone.current, timeZoneIsUserOverride: Bool = false, onDone: @escaping AddDeviceOnDone)

/// Add a device to the device collection.
///
/// - parameter associationId: The associationId for the device. Note that this is different from the deviceId.
/// - parameter location: The location, if any, to associate with the device.
/// - parameter isOwnershipChangeVerified: If the device is eligible for ownership change (see note), and
///                                        `isOwnershipChangeVerified` is `true`, then the device being scanned
///                                        will be disassociated from its existing account prior to being
///                                        associated with the new one.
/// - parameter timeZone: The timezone to use for the device. Defaults to `TimeZone.current`.
/// - parameter timeZoneIsUserOverride: If true, indicates the user has explicitly set the timezone
///                             on this device (rather than it being inferred by location).
///                             If false, timeZone is the default timeZone of the phone.
///
/// ## Ownership Transfer
/// Some devices are provisioned to have their ownership transfer automatically. If upon an associate attempt
/// with `isOwnershipTransferVerified == false` is made upon a device that's assocaiated with another account,
/// and an error is returned with an attached URLResponse with header `transfer-verification-enabled: true`,
/// then the call can be retried with `isOwnershipTranferVerified == true`, and the service will disassociate
/// said device from its existing account prior to associating it with the new account.

public func addDevice(with associationId: String, location: CLLocation? = nil, isOwnershipChangeVerified: Bool = false, timeZone: TimeZone = TimeZone.current, timeZoneIsUserOverride: Bool = false) -> Promise<DeviceModel>
```

On an existing `DeviceModel`:

```swift
public extension DeviceModelable {

/// Set this device's timezone. Upon success, the timeZone will be immediately set on this device
/// (a conclave invalidation will also be handled), and a device state update will be signaled.
func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool) -> Promise<SetTimeZoneResult>
```

## Milestone 2 / SDK v0.7

### Misc

* AferoSwiftSDK now builds and tests, and AferoLab runs, on XCode9β5.
* AferoLab now supports manual association id entry when running in the sim.
* DeviceCollection now automatically starts and stops automatically based
  upon app state.
* DeviceCollection now fetches all app and profile state directly from the ClientAPI
  on startup, improving startup time.
* An off-by-one has been corrected in OTA progress calculation.
* 0.7.2 / IOS-1440: Added an `appId` field to body sent to `/v1/accounts/.../mobileDevices`.

### API Changes

#### Device association/Disassociation have moved

Device association and disassociation have been moved to the DeviceCollection, improving
association time and handling additional configuration tasks automatically.

**Device association** has been moved to:

```swift
DeviceCollection.addDevice(
    with associationId: String,
    location: CLLocation? = nil,
    isOwnershipChangeVerified: Bool = false,
    timeZone: TimeZone = TimeZone.current,
    timeZoneIsUserOverride: Bool = false
) -> Promise<DeviceModel>
```
When using this call, the following happens automatically:
* The device, with profile, is added to the deviceCollection immediately upon
  clientApi return.
* The device's timeZone is set either to a custom-specified value, or the current
  timeZone of the mobile device being used.

**Device Disassociation** has been moved to:

```swift
DeviceCollection.removeDevice(with deviceId: String) -> Promise<String>
```

The returned promise resolves to the `id` of the device removed.

### XCode 9

The short story: make sure you do a `pod update` anytime you switch between XCode 8
and XCode 9.

Longer: While the code is still technically Swift 3.2, and XCode 9 supports
Swift 3.2, there is still some third-party issues which require pointing to
specific branches for beta compatibility.

`Examples/Podfile` has been updated
to select the correct pods based upon the currently-selected XCode version, so
after running `xcode-select -s`, or changing the toolchain location in XCode preferences,
it's important to run `pod update`.

 ## Milestone 1 / SDK v0.6.0

Afero SDK M1 contains a number of changes since the original drop of code to Kenmore, notably:

* All SDK code is now hosted via CocoaPods (currently in the [aferodeveloper] restricted-access repo)
* Conclave 2.0 is included, streamlining device state synchronization with the Afero cloud,
and reducing the number of message types SDK users are required to handle.
* Simplified Softhub integration, using the `AferoSofthub` module.
* The public interface footprint has been reduced, and alignment with
Android Afero SDK API symbol names has been improved.

### CocoaPods Integration

The Afero Swift SDK is now available via the [aferodeveloper] Github account.
This is a restricted-access repository; contact Afero for access.

| Repo | Description | URL |
| - | - | - |
| [`Podspecs`][repo-podspecs-main] | Afero CocoaPods repo | https://github.com/aferodeveloper/Podspecs |
| [`AferoSwiftSDK`][repo-sdk] | Main SDK Repo | http://github.com/aferodeveloper/AferoSwiftSDK |
| [`AferoSofthub`][repo-softhub] | Afero SoftHub (implicitly imported by `AferoSwiftSDK`) | http://github.com/aferodeveloper/AferoSwiftSDK |

[aferodeveloper]:  https://github.com/aferodeveloper
[repo-podspecs-main]: https://github.com/aferodeveloper/Podspecs
[repo-sdk]: http://github.com/aferodeveloper/AferoSwiftSDK
[repo-softhub]: http://github.com/aferodeveloper/AferoSwiftSDK

#### Example Podfile

```ruby

# While in restricted release, the preferred means of access
# is ssh.
source 'git@github.com:aferodeveloper/Podspecs.git'

# If using https, you'll have to authenticate to GitHub
# on every install.
#source 'https://github.com/aferodeveloper/Podspecs.git'

# Include the CocoaPods global spec repo.
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '9.3'

use_frameworks!

# As of AferoSwiftSDKv1.1.0, 'afero-thirdparty' cannot be included as an
# implicit prerequesite by AferoSwiftSDK, but is a requirement for linking.
# Therefore it must be included in your Podfile.
pod 'afero-thirdparty', '0.0.5'

# Hubby is included implicitly, but warnings can be inhibited like so:
pod 'Hubby', :inhibit_warnings => true

# Finally, include AferoSwiftSDK.
pod 'AferoSwiftSDK', '~> 1.1'

```

### Conclave 2.0

The `DeviceCollection` has been updated to support the Conclave 2.0 protocol. Along
with this change, the set of messages emitted by `DeviceCollection` has been simplified.

### AferoSofthub

The former `AferoHubbyService` and `Hubby` modules have been combined into `AferoSofthub`.
The `AferoSofthub` API has been simplified. In the process, a number of symbols have
been renamed.

For an example of use, see [`AferoSofthubMinder.swift`][afero-softhub-minder] in the `AferoLab` example.

[afero-softhub-minder]: https://github.com/KibanLabsInc/AferoSwiftSDK/blob/master/Examples/AferoLab/AferoLab/SofthubMinder.swift

### API changes

#### Renamed Symbols

* `DeviceCollection.deviceForDeviceid(_:)` has been renamed to `DeviceCollection.peripheral(for:)`
