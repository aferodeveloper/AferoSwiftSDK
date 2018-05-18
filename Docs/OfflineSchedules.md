---
author: Justin Middleton <jrmiddle@afero.io>
title: "Offline Schedules"
date: May 18, 2018 11:18 AM
status: DRAFT
version: 0.1

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
* [Key Tasks](#key-tasks)
	* [Obtain an Offline Schedule reference](#obtain-an-offline-schedule-reference)
	* [Interrogate an Offline Schedule's Events](#interrogate-an-offline-schedules-events)
	* [Examine an individual Offline Schedule Event](#examine-an-individual-offline-schedule-event)
		* [Time specification](#time-specification)
		* [Attributes](#attributes)
	* [Observe changes to an Offline Schedule](#observe-changes-to-an-offline-schedule)
	* [Miscellaneous Informational Properties and Methods](#miscellaneous-informational-properties-and-methods)
	* [Manipulate an Offline Schedule's Events](#manipulate-an-offline-schedules-events)
		* [Create an individual Offline Schedule Event](#create-an-individual-offline-schedule-event)
		* [Removing Schedule Events](#removing-schedule-events)
		* [Adding Schedule Events](#adding-schedule-events)
		* [Replacing Schedule Events](#replacing-schedule-events)
		* [Committing Changes](#committing-changes)
* [Colophon](#colophon)

<!-- /code_chunk_output -->

## Overview

**Offline Schedules** provide a means for Afero Connected Devices to perform
scheduled actions independently, without being continually connected to the
Afero cloud.

This document describes the **iOS API for working with offline schedules**.

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

### Interrogate an Offline Schedule's Events

```swift
extension OfflineSchedule {

    /// The number of events currently stored in this schedule
    public var numberOfEvents: Int { get }

    /// Get the schedule event at the specified index.
    /// - warning: 0 ≤ index < numberOfEvents must be true, otherwise
    ///            an out-of-bounds will be thrown.
    public func scheduleEvent(_ index: Int) -> OfflineSchedule.ScheduleEvent
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

### Miscellaneous Informational Properties and Methods

```swift
public extension OfflineSchedule {

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

### Manipulate an Offline Schedule's Events

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

The following methods are available for removing schedule events.

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

## Colophon

This document was created using a combination of  [Github-Flavored Markdown](https://github.github.com/gfm/),
[Mermaid](https://mermaidjs.github.io) for sequence diagrams, and
[PlantUML](http://plantuml.com) for UML.

Creation was done in [Atom](), with rendered output created using [markdown-preview-enhanced](https://github.com/shd101wyy/markdown-preview-enhanced).
