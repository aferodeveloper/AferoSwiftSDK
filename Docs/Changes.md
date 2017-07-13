---
title: Changes
author: Justin Middleton <jrmiddle@afero.io>
---

# Changes

## Milestone 1 / SDK v1.2.0

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
