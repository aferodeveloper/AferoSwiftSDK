---
author: Justin Middleton <jrmiddle@afero.io>
title: "Afero Softhub"
date: Feb 9, 2018 4:21 PM
status: 0.1
---

**AFERO CONFIDENTIAL AND PROPRIETARY INFORMATION**

© Copyright 2017 Afero, Inc, All Rights Reserved.

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

1. [Overview](#overview)
2. [Components](#components)
    1. [Public Implementation](#public-implementation)
        1. [`Afero.Softhub`](#aferosofthub)
        2. [`AferoLab.SofthubMinder` example code](#aferolabsofthubminder-example-code)
    2. [Internal Implementation](#internal-implementation)
3. [Using](#using)
    1. [Obtaining a Softhub reference](#obtaining-a-softhub-reference)
    2. [Starting the Softhub](#starting-the-softhub)
        1. [Parameters](#parameters)
    3. [Stopping the Softhub](#stopping-the-softhub)
4. [Softhub Association](#softhub-association)
5. [Colophon](#colophon)

<!-- /code_chunk_output -->


## Overview

The Afero Softhub is an auxilliary component of the Afero SDK which
provides a means for Afero peripheral devices to communicate with the Afero
cloud using a mobile device's network connection (WiFi or cellular). It operates
independent of other Afero SDK components, and the SDK user need only start
and stop the Softhub as appropriate.

## Components

### Public Implementation

```puml

package Cocoa {
    class NSObject
}

package AferoSofthub {
    class AferoSofthub
}

NSObject <|-- AferoSofthub


package Afero {

    class SoftHub {
        {field} state: SofthubState
        {field} deviceId: String?
        {field} activeOTACount: Int

        {method} start(accountId:cloud:identifier:associationHandler:completionHandler)
        {method} stop()
    }

}

NSObject <|-- SoftHub

package AferoLab {

    class SoftHubMinder

}

NSObject <|-- SoftHubMinder
```

#### `Afero.Softhub`

The public implementation for the AferoSofthub can be found in the `Softhub`
class in the `Afero` module. This class, compatible with Objective-C and Swift,
provides a high-level interface for starting and stopping the softhub, as well
as accessing information about the softhub's current state.

#### `AferoLab.SofthubMinder` example code

`Afero.Softhub` provides a high-level interface to manipulating and observing
the softhub, but it delegates determining when to start and stop the softhub
to the SDK user. On iOS, it is important, for example, to stop the softhub when
the app enters the background, except if the softhub is currently serving an
over-the-air update to a connected Afero device. In this case, it's desirable to
allow the softhub to run in the background until all OTAs have been completed.

As an example of this, the `SofthubMinder.swift`, in the `AferoLab` sample code,
manages softhub state based upon application state, OTA state, and whether or not
the softhub should be started at all. While not a part of the official SDK _per se_,
SDK users are free to use this code and modify it to their tastes.

### Internal Implementation

The internal implementation for the Softhub comes from the `AferoIOSSofthub` pod,
which vends the module, `AferoSofthub`.

> **IMPORTANT**
>
> While the namespace and symbols provided by this pod are visible to the SDK
user upon import, it is considered an internal, private implementation, as
exposed symbols and usage semantics are subject to change. Afero does not
support code that links to this module directly, and the APIs vended therein are
subject to change at any time. SDK consumers should use symbols available in the
`Afero` module vended by `AferoSwiftSDK` **only**.

## Using

Use the `Softhub` class vended by `AferoSwiftSDK`, and visible in module `Afero`, to:
* Start and stop the softhub
* Observe softhub state
* Observe active OTA count
* Obtain the Softhub's `deviceId`

### Obtaining a Softhub reference

Because there is only one softhub in operation at any time, the API exposes it
as a shared singleton. This can be obtained as such:

```swift
import Afero
let softhub = Softhub.shared
```

### Starting the Softhub

Starting the Softhub is performed using the start() method, as such:

```swift
Softhub.shared.start(
    with: accountId,
    identifiedBy: hardwareIdentifier,
    logLevel: logLevel,
    associationHandler: associationNeededHandler
) {
    completionReason in
    DDLogInfo("Softhub stopped with status \(String(reflecting: completionReason))")
}
```

#### Parameters

| Parameter | Purpose |
| - | - |
| accountId | A string that is unique to the account to which the softhub will be associated. An actual Afero account id is sufficient, but any string unique to a given account will do. See **Associating**.|             
| cloud | The cloud to which to connect. Defaults to `.prod`, and should not be changed for production applications. |
| identifier | A string which, if present, is added to the HUBBY_HARDWARE_INFO attribute of the softhub's device representation. It can be used to distinguish the local softhub from others. |
| associationhandler | A callback which takes an `associationId` in the form of a string, and performs a call against the appropriate Afero REST API to associate. |
| completionHandler | A callback called when the softhub stops. The reason for stopping is provided as the sole parameter.|

### Stopping the Softhub

Stopping the Softhub is a simple call to the `stop()` method; there are no parameters to this method.

```swift
Softhub.shared.stop()
```

## Softhub Association

The Afero Softhub attaches to an Afero account by acting as another device, and therefor
must be associated with an account before it is able to communicate with
physical Afero peripheral devices. Once associated, it saves its configuration
so that subsequent starts against the same account do not require an association step.

To accomplish association, the Softhub delegates device association to the caller
of `start(with:using:identifiedBy:loglevel:associationHandler:completionHandler)`,
via the `associationHandler: @escaping (String)->Void` parameter. It is expected
that this invocation will result in a POST to the Afero client API:

```
    POST https://api.afero.io/v1/accounts/$accountId$/devices
```

The body of this request should be JSON-formatted, as such:

```
{ associationId: "ASSOCIATION_ID" }
```

If an `AferoAPIClient` implementor is being used, such as `AFNetworkingAferoAPIClient`,
then `associateDevice(with:to:locatedAt:ownershipTransferVerified:expansions)` can be used
for this purpose. See `AferoAPIClient+Device.swift` for more info.

Once a softhub has associated with an account,
it saves its configuration info locally to a path determined in part by
hashing the `accountId` value. Upon subsequent starts using the same `accountId`,
the softhub will connect directly to the Afero service requiring association.
For this reason, its highly desirable that the `accountId` parameter be the same
for each account, and that it differ from one account to another. Afero recommends
using an actual Afero account id, which is a UUID.

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/),
[Mermaid](https://mermaidjs.github.io) for sequence diagrams, and
[PlantUML](http://plantuml.com) for UML.

Creation was done in [Atom](), with rendered output created using [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).
