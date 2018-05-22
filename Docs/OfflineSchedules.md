---
author: Justin Middleton <jrmiddle@afero.io>
title: "Offline Schedules"
date: 5/21/2018
status: DRAFT
version: 0.2

toc:
    depth_from: 1
    depth_to: 6
    ordered: true

ebook:
    title: Attribute Semantics
    authors: Justin Middleton
    margin: 18
    base-font-size: 10
    pdf:
        default-font-size: 12
        page-numbers: true

export-on-save:
    html: true
---

# Offline Schedules

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

---

## In This Document

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->
<!-- code_chunk_output -->

* [In This Document](#in-this-document)
* [Overview](#overview)
* [Key Concepts](#key-concepts)
	* [The Offline Schedule object](#the-offline-schedule-object)
	* [Daylight Savings Time](#daylight-savings-time)
	* [Time Zones](#time-zones)
	* [Explicitly Setting Device TimeZone](#explicitly-setting-device-timezone)
	* [Cloud Inference of Device TimeZone](#cloud-inference-of-device-timezone)
	* [Class Diagram](#class-diagram)
		* [`class DeviceModel`](#class-devicemodel)
		* [`class OfflineSchedule`](#class-offlineschedule)
		* [`struct OfflineSchedule.ScheduleEvent`](#struct-offlineschedulescheduleevent)
		* [`struct OfflineSchedule.ScheduleEvent.TimeSpecification`](#struct-offlineschedulescheduleeventtimespecification)
		* [`attributes`](#attributes)
* [Key Tasks](#key-tasks)
	* [Obtain an Offline Schedule reference](#obtain-an-offline-schedule-reference)
	* [Interrogating an Offline Schedule](#interrogating-an-offline-schedule)
	* [Examine an individual Offline Schedule Event](#examine-an-individual-offline-schedule-event)
		* [Time specification](#time-specification)
		* [Attributes](#attributes-1)
	* [Observe changes to an Offline Schedule](#observe-changes-to-an-offline-schedule)
	* [Manipulate an Offline Schedule's Events](#manipulate-an-offline-schedules-events)
		* [Create an individual Offline Schedule Event](#create-an-individual-offline-schedule-event)
		* [Removing Schedule Events](#removing-schedule-events)
		* [Adding Schedule Events](#adding-schedule-events)
		* [Replacing Schedule Events](#replacing-schedule-events)
		* [Committing Changes](#committing-changes)
* [See Also](#see-also)
* [Colophon](#colophon)

<!-- /code_chunk_output -->

---

## Overview

**Offline Schedules** provide a means for Afero Connected Devices to perform
scheduled actions independently, without being continually connected to the
Afero cloud.

This document describes the **iOS API for working with offline schedules**.

> **NOTE**
>
> This document contains diagrams produced using [PlantUML]. An easy way to render them
> is to open this document in the [Atom] text editor, and preview using the
> [Markdown Preview Enhanced] package.


## Key Concepts

This section describes the key concepts of Afero Offline Schedules.

### The Offline Schedule object

The Offline Schedule object (class `OfflineSchedule`) vended by the `DeviceModel`
provides a high-level interface for interacting with offline schedules, eliminating
the need for the developer to concern herself with encoding and decoding schedule events,
interpreting flags, working with time zones and daylight savings time details,

### Daylight Savings Time

It is important to note that Afero devices which support Offline Schedules
automatically maintain schedules across time zones and Daylight Savings Time
switchovers. This is done in a straightforward way:

* Time specifications are stored in the local time of the device (note that while there
  are deprecated methods for using UTC, these must be avoided for DST support).

* Afero Devices, in cooperation with the Afero cloud, maintain their internal times
  in UTC, and are also informed by the Afero cloud what their current UTC offset should
  be.

* Every time an Afero device links with the Afero cloud, the cloud supplies the
  device with its UTC offset as per the [IANA Time Zone Database][TZDB].
  The time zone assigned to the device can come either from:

  * A timezone explicitly set on the `DeviceModel` instance representing the
    Afero device.

  * A timezone inferred by the Afero cloud from the device's location.

  See [Time Zones](#time-zones), below, for more detail.


> **IMPORTANT**
>
> While the SDK currently exposes deprecated methods for using UTC times, it
is crucial to note that only events which are scheduled in local times will be
accurately maintained across DST switchovers.

### Time Zones

Because offline schedule event fire times are specified in local time, it is
unnecessary for a scheduler interface to know the timezone of an Afero device,
unless it is desired to show the fire time in the time zone local to the mobile
client displaying the schedule.

However, it is crucial that a device's `timeZone` be set. This can be done in one
of two ways:

### Explicitly Setting Device TimeZone

A `DeviceModel`'s timezone can be explicitly set using
`DeviceModel.setTimeZone(timeZone:isUserOverride)`:

```swift
public extension DeviceModelable {

    /// The device's timeZone, if set.
    public var timeZone: TimeZone? { get }

    /// Set the timezone for a device.
    /// - parameter timeZone: The timezone to associate with the device.
    /// - parameter isUserOverride: If true, indicates the user has explicitly set the timezone
    ///                             on this device (rather than it being inferred by location).
    ///                             If false, timeZone is the default timeZone of the phone.
    public func setTimeZone(as timeZone: TimeZone, isUserOverride: Bool) -> Promise<SetTimeZoneResult>

}
```

### Cloud Inference of Device TimeZone

If a `DeviceModel`'s `timeZone` has not been explicitly set, the Afero cloud will
infer the `timeZone` from the device's location. If the device's location has not
been explictly set (either at association time, or afterward), the Afero cloud
will attempt to infer the device's location from IP information.

### Class Diagram

```puml

class DeviceModel {
    {field} timeZone: TimeZone?
    {method} setTimeZone(as: TimeZone, isUserOverride: Bool) -> Promise<SetTimeZoneResult>
    {field} supportsOfflineSchedules: Bool
    {method} offlineSchedule(using: OfflineScheduleCollator = default) -> OfflineSchedule?
}

class OfflineSchedule {
    {field} ...    
    {method} ...
}

DeviceModel "vends" ..> "is vended by" OfflineSchedule

class "OfflineSchedule.ScheduleEvent" as ScheduleEvent << (S,orchid) >> {
    {field} timeSpecification: TimeSpecification
    {field} attributes: [Int: AttributeValue]
}

OfflineSchedule "1" o-- "0..n" ScheduleEvent

enum AttributeValue

class "OfflineSchedule.ScheduleEvent.TimeSpecification" as TimeSpecification << (S,orchid) >> {
    {field} repeats: Bool
    {field} dayOfWeek: DayOfWeek
    {field} hour: UInt
    {field} minute: UInt
}

ScheduleEvent "1" o-- "1" TimeSpecification
ScheduleEvent "1" o-- "0..n" AttributeValue

```


#### `class DeviceModel`

Every Afero-enabled device is represented by an instance of the `DeviceModel`
class; each `DeviceModel` which represents an offline-schedule-aware device vends
`OfflineSchedule` instances which can be used to view and manipulate that device's
offline schedule.

#### `class OfflineSchedule`

An offline schedule is the set of all scheduled events, represented by
`OfflineSchedule.ScheduleEvent` instances, that a supporting Afero-enabled
persists in internal storage. Logically, the schedule is a collection `RAWBYTES`
attributes in a private range.

#### `struct OfflineSchedule.ScheduleEvent`

`OfflineSchedule.ScheduleEvent` (hereafter, simply `ScheduleEvent`) instances comprise
the information required for applying a set of attribute value states to an Afero
device. Each `ScheduleEvent` contains a single `TimeSpecification` and a set of
actions represented by a mapping of attribute `id`s to attribute values.

#### `struct OfflineSchedule.ScheduleEvent.TimeSpecification`

`OfflineSchedule.ScheduleEvent.TimeSpecification` (hereafter, simply
`TimeSpecification`) describes the fire time of a `ScheduleEvent` in terms of
day of week and time of day that an event fires, as well as whether or not
the event repeats. Some key points about `TimeSpecification`s include:

* All times are expected to be represented in a device's **local** time. This
is necessary for maintenance of schedule times across **Daylight Savings Time**
switchovers. While the interface does include **deprecated** methods related to
use of UTC times, these are a historical artifact and should not be used. See
[Time Zones and Daylight Savings Time](#time-zones-and-daylight-savings-time)
for more information.

* If the `repeats` flag is set to `true`, then the event associated with a given
`TimeSpecification` fires on a weekly basis.
If it is set to `false`, then the associated event will fire only once, and then
internally be marked by the firmware to not fire again.

> **IMPORTANT**
>
> As of this writing, there is no public API for determining whether or not a
> non-repeating event has fired. For this reason, it is expected that any user
> interface for manipulating offline schedules work only with `ScheduleEvent`s
> whose `timeSpecification.repeats` flags are set to `true`


#### `attributes`

The second aspect of a `ScheduleEvent` is the set of attributes it the event applies
when it fires. This is represented in Swift by a `Dictionary<Int,Afero.AttributeValue>`.

## Key Tasks

> **NOTE:**
>
> While it is possible to obtain "last known" offline schedule information from the Afero
> device if it is not connected to the Afero cloud, manipulation of offline schedules
> requires that the device be connected to the Afero cloud.

---

### Obtain an Offline Schedule reference

`DeviceModelable` implementing instances, such as `DeviceModel` representing peripherals that support offline schedules
expose the following symbols interpretation and manipulation of offline schedules.

> **NOTE**
>
> The `OfflineScheduleCollator` referenced below is responsible for maintaining a stable
> and compact map of events to attributes. While it is currently exposed in the API,
> **using a collator other than the default is not supported.**

```plantuml
App -> DeviceModel: offlineSchedule()
DeviceModel ->App: return
```

```swift
public extension DeviceModelable {
    /// If this `DeviceModelable` supports offline schedules, then this returns an
    /// offline schedule instance. Otherwise, returns nil.
    /// - parameter collator: An `OfflineScheduleCollator` instance. If omitted, defaults to
    ///                       a `DefaultOfflineScheduleCollator` instance.

    public func offlineSchedule(with collator: OfflineScheduleCollator =  DefaultOfflineScheduleCollator()) -> OfflineSchedule? {
}
```

---

### Interrogating an Offline Schedule

```plantuml
App -> OfflineSchedule: numberOfEvents
activate App
OfflineSchedule --> App: n
deactivate App

App -> OfflineSchedule: event(at index: Int)
activate App
OfflineSchedule --> App: e
deactivate App
```

```swift
extension OfflineSchedule {

    /// The number of events currently stored in this schedule
    public var numberOfEvents: Int { get }

    /// Get the schedule event at the specified index.
    /// - warning: 0 ≤ index < numberOfEvents must be true, otherwise
    ///            an out-of-bounds will be thrown.
    public func scheduleEvent(_ index: Int) -> OfflineSchedule.ScheduleEvent

    /// The total number of events this device supports
    public var numberOfSupportedEvents: Int { get }

    /// The total number of events per day that this device supports
    public var numberOfSupportedEventsPerDay: Int { get }

    /// Local days in the schedule which which have maxed out their event count.
    public var unavailableDays: Set<ScheduleEvent.TimeSpecification.DayOfWeek> { get }

    /// Local days in the schedule which which have *not* maxed out their event count.
    public var availableDays: Set<ScheduleEvent.TimeSpecification.DayOfWeek> { get }

    /// A map of `DayOfWeek` to the number of events currently scheduled on that local day.
    public var dayEventCounts: [ScheduleEvent.TimeSpecification.DayOfWeek: Int] { get }

    /// Return all events for a given local day of week
    /// - parameter localDayOfWeek: The local-timezone day of week for which to query.
    public func events(forDayOfWeek dayOfWeek: ScheduleEvent.TimeSpecification.DayOfWeek) -> [ScheduleEvent]

    /// Return all events whose local day of week is in `localDaysOfWeek`
    /// - parameter localDaysOfWeek: The local days for which to filter

    public func events<T: Sequence>(forDaysOfWeek daysOfWeek: T) -> [ScheduleEvent]
        where T.Iterator.Element == ScheduleEvent.TimeSpecification.DayOfWeek

    /// Return all events matching the given predicate.
    /// - parameter predicate: The predicate which to evaluate each `ScheduleEvent` against.
    ///                        defaults to matching all.
    public func events(matching predicate: ScheduleEventPredicate = { _ in return true }) -> [ScheduleEvent]
}

```

---

### Examine an individual Offline Schedule Event

An `OfflineSchedule.ScheduleEvent` comprises two kinds of information:
* When an event will fire. This is described by `OfflineSchedule.ScheduleEvent.TimeSpecification`.
* What happens when the event fires. This is described by a collection of `AttributeValue`s which
  will be committed to their assigned attributes when the event's fire time arrives.

#### Time specification

An `Offline.ScheduleEvent`'s `TimeSpecification` provides timing info for the event:

```swift
public class OfflineSchedule {

    public struct TimeSpecification {

        /// whether the event repeats
        public var repeats: Bool { get set }

        /// The day of week that this event should fire.
        /// - note: Currently ScheduleEvents can only be assigned
        ///         to individual days.
        public var dayOfWeek: OfflineSchedule.TimeSpecification.DayOfWeek { get set }

        /// The hour, 0 ≤ hour ≤ 23, when an event is to occur.
        /// - note: This is expected to be in device-local time.
        public var hour: OfflineSchedule.TimeSpecification.Hour { get set }

        /// The minute, 0 ≤ minute ≤ 59, when an event is to occur.
        public var minute: OfflineSchedule.TimeSpecification.Minute { get set }
    }

    public class ScheduleEvent {

        var timeSpecification: OfflineSchedule.Time

        /// Convenience accessor for whether the event repeats
        var repeats: Bool { get set }

        /// Convenience accessor
        var dayOfWeek: OfflineSchedule.TimeSpecification.DayOfWeek { get set }

        /// Convenience accessor
        var hour: OfflineSchedule.TimeSpecification.Hour { get set }

        /// Convenience accessor
        var minute: OfflineSchedule.TimeSpecification.Minute { get set }

    }
}
```

#### Attributes

The `attributes` property of an `OfflineSchedule.ScheduleEvent` provides the
attribute ids and values which will be committed to an Afero device's state when
the associated fire time described by the event's `TimeSpecification` arrives.

```swift
    public class OfflineSchedule {
        public struct ScheduleEvent {
            public var attributes: [Int, AttributeValue] = [:]
        }
    }
```

---

### Observe changes to an Offline Schedule

```swift

public class OfflineSchedule {

    /// Reactive events emitted by an Offline Schedule on its event signal
    /// - note: This is related to changes to the contents of an offline schedule.
    ///         For information about individual scheduled events, see
    ///         OfflineSchedule.ScheduleEvent

    public enum Event {

        /// The flag indicating whether offline schedules are enabled
        /// or disabled on the device that owns this scheudle has changed.
        case offlineSchedulesEnabledStateChanged(enabled: Bool)

        /// One or more ScheduleEvents contained in this schedule have changed.
        case scheduleEventsChanged(deltas: OfflineScheduleIndexDeltas)

        /// All schedule events have been updated
        case scheduleEventsReloaded
    }

    /// Type for signal emitting schedule-related events
    typealias OfflineSchedule.EventSignal = Signal<OfflineSchedule.Event,NoError>

    /// Reactive signal producing `OfflineSchedule.Event` instances
    public var offlineScheduleEventSignal: OfflineSchedule.EventSignal { get }


}
```


---

### Manipulate an Offline Schedule's Events

With all of the methods below for manipulating an `OfflineSchedule`'s events,
the following basic operations take place:

1. Events are added, removed, or modified using the `OfflineSchedule`'s methods.
2. The `OfflineSchedule` commits changes to the underlying `DeviceModel`'s attributes.
3. The changes are applied to the Afero cloud, and the Afero cloud relays success/failure
   (in the form of `Promise<>` fulfillment/rejection) to the caller.
4. Separately, as the changes apply to the physical device, and the Afero Cloud receives
   notification of said changes, the asynchronous attribute update messages are translated
   by the `OfflineSchedule` into `OfflineSchedule.Event` events, emitted by
   `OfflineSchedule.offlineScheduleEventSignal`.

#### Create an individual Offline Schedule Event

```swift
public class OfflineSchedule {
    public struct ScheduleEvent {

        /// Create a ScheduleEvent with the given TimeSpecification and attributes.
        /// - param timeSpecification: The TimeSpecification to use. Defaults to `nil`,
        ///                            which will in turn be interpreted as Sunday 00:00 local time
        /// - param attributes: The attributes to set when the event fires.

        init(timeSpecification: TimeSpecification? = nil, attributes: [Int: AttributeValue] = [:])
    }
}
```

#### Removing Schedule Events

The following methods are available for removing schedule events. Each of these follow
the same basic pattern:

```plantuml

participant App
participant OfflineSchedule
participant DeviceModel
participant APIClient
participant Cloud

App -> OfflineSchedule: removeScheduleEvent(atIndex:commit:)
activate App
OfflineSchedule -> APIClient: postBatchActions
APIClient -> Cloud: POST []
Cloud --> APIClient: HTTP resp
APIClient --> App: success/failure
deactivate App

Cloud --> DeviceModel: attrUpdate
DeviceModel --> OfflineSchedule: attributeUpdate
OfflineSchedule --> App: .scheduleEventsChanged(deltas:)
```


> **NOTE**:
> Some of the methods below support a `commit` parameter. In these cases, the changes made
> by calling these events to not take effect on the Afero device until a later `commit`
> is issued. Where `commit` is not parameterized, it can be assumed that changes are
> committed immediately. See [Committing Changes](#committing-changes) below for more info.

```swift
public extension OfflineSchedule {

    /// Remove an event at the given index as per the collator.
    /// - parameter index: the collator-index of the event to remove.
    /// - parameter commit: If true (the default), will automatically commit the attribute.
    /// - returns: A `Promise<Set<Int>>`, which resolves to a set containing the
    ///            `attributeId` of the uncommitted attribute, if any.
    /// - note: If `commit == true`, then the promise will resolve to an empty set,
    ///         since there's nothing remaining to commit.
    @discardableResult
    public func removeScheduleEvent(atIndex index: Int, commit: Bool = true) -> Promise<Set<Int>>

    /// Remove all events in the schedule.
    public func removeAllEvents() -> Promise<Void> {

    /// Remove all events for a given `localDayOfWeek`, and commit the removal.
    public func removeEvents(forDayOfWeek dayOfWeek: ScheduleEvent.TimeSpecification.DayOfWeek) -> Promise<Void>

    /// Remove all events with `localDayOfWeek` in the given sequence, and commit the removal.
    public func removeEvents<T>(forDaysOfWeek daysOfWeek: T) -> Promise<Void>

    /// Remove all events matching the given predicate, and commit the removal.
    /// - parameter predicate: The predicate for which matching events will be removed.
    /// - note: Because of the destructive nature of this operation, there is no default
    ///         predicate.
    public func removeEvents(matching predicate: ScheduleEventPredicate) -> Promise<Void>

}
```

#### Adding Schedule Events

As with event removal, adding events follow the same basic flow as described in the
sequence diagram below.

```plantuml

participant App
participant OfflineSchedule
participant DeviceModel
participant APIClient
participant Cloud

App -> OfflineSchedule: addScheduleEvent(atIndex:commit:)
activate App
OfflineSchedule -> APIClient: postBatchActions
APIClient -> Cloud: POST []
Cloud --> APIClient: HTTP resp
APIClient --> App: success/failure
deactivate App

Cloud --> DeviceModel: attrUpdate
DeviceModel --> OfflineSchedule: attributeUpdate
OfflineSchedule --> App: .scheduleEventsChanged(deltas:)
```

```swift
public extension OfflineSchedule {

    /// Add an event. Promise reject called if there's no more room.
    /// - parameter event: the event to add.
    /// - parameter commit: If true (the default), will automatically commit the attribute, if any changes were made.
    /// - returns: A `Promise<Set<Int>>`, which resolves to a set containing the
    ///            `attributeId` of the uncommitted attribute, if any.
    /// - note: The promise will resolve to an empty set if either of the following conditions are met:
    ///         1. `commit == true`.
    ///         2. No actual changes were made, because the even matches an existing event.
    @discardableResult
    public func addScheduleEvent(_ event: OfflineSchedule.ScheduleEvent, commit: Bool = true) -> Promise<Set<Int>>

    /// Add a collection of `OfflineSchedule.ScheduleEvent`s.
    /// - parameter events: The events to add.
    /// - parameter commit: If true, commit automatically
    /// - returns: A `Promise<Set<Int>>`, which resolves to a set containing the
    ///            `attributeId` of uncommitted attributes, if any.
    /// - warning: If any of the adds fail (e.g. due to capacity), autocommit is cancelled,
    ///            but successful uncommitted changes to the schedule will persist.
    public func addScheduleEvents<T>(_ events: T, commit: Bool = true) -> Promise<Set<Int>>
}
```

#### Replacing Schedule Events

```swift
public extension OfflineSchedule {
    /// Replace one event with another, essentially "updating" the event.
    /// - parameter oldEvent: The event to replace
    /// - parameter newEvent: The replacement event
    /// - parameter commit: If true, automatically commit results. If false, do not, and have the returned
    ///                     promise resolve the attributeIds that need to be committed.
    public func replaceScheduleEvent(_ oldEvent: OfflineSchedule.ScheduleEvent, with newEvent: OfflineSchedule.ScheduleEvent, commit: Bool = true) -> Promise<ReplaceEventResult> {
}
```
#### Committing Changes

Some CRUD methods on an `OfflineSchedule` optionally commit their changes to their
underlying `DeviceModel`; this is to minimize traffing and provide some semblance of
atomicity in certain cases.

```swift
public extension OfflineSchedule {

    /// Commit schedule events identified by event index (as per the collator).
    /// - parameter forEventIds: A `Sequence` of `eventIds` referencing the events
    ///                          to commit.
    public func commitEvents<T>(forEventIds eventIds: T?) -> Promise<[AttributeInstance]>

}
```

---

## See Also

| Title/Link | Description |
| - | - |
| [IANA Time Zone Database][TZDB] |  |

[TZDB]: https://www.iana.org/time-zones "IANA Time Zone Database"
[PlantUML]: http://plantuml.com "Plant UML"
[Markdown Preview Enhanced]: https://github.com/shd101wyy/markdown-preview-enhanced "Markdown Preview Enhanced"
[Atom]: https://atom.io "Atom"

---

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/) and
[PlantUML] for UML.

Creation was done in [Atom], with rendered output created using [Markdown Preview Enhanced].
