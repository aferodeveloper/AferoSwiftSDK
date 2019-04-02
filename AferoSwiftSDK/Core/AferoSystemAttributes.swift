//
//  AferoSystemAttributes.swift
//  iTokui
//
//  Created by Justin Middleton on 11/2/16.
//  Copyright © 2016 Kiban Labs, Inc. All rights reserved.
//

import Foundation

// MARK: -
// MARK: Afero-internal attributes
// MARK: -

public enum AferoSystemAttribute: Int {
    case hachiState = 65013
    case softhubHardwareInfo = 51101
}

/// State of the ASR module in an Afero device. From `AferoSystemAttribute.hachiState` (`== 65013`)
/// * .unknown: "pseudo"-case, in case we are not able to comprehend what we get form the service
/// * .rebooted: The device was rebooted
/// * .linked: The device has linked; communication flowing.
/// *
public enum HachiState: Int {
    
    /// "pseudo"-case, in case we are not able to comprehend what we get form the service
    case unknown = -1
    
    /// The device was rebooted
    case rebooted = 0
    
    /// The device has linked; communication flowing.
    case linked = 1
    
    /// The device is in the process of applying a software update.
    case updating = 2
    
    /// The device has a software update ready to apply.
    case updateReadyToApply = 3
}

public extension DeviceModelable {
    
    func valueForSystemAttribute(_ attribute: AferoSystemAttribute) -> AttributeValue? {
        return valueForAttributeId(attribute.rawValue)
    }
    
    var hachiState: HachiState {
        
        guard
            let attributeValue = valueForSystemAttribute(.hachiState)?.intValue,
            let ret = HachiState(rawValue: attributeValue) else {
                return .unknown
        }
        
        return ret
    }
}

public enum AferoPlatformAttributeRange: Comparable {
    
    public static func <(lhs: AferoPlatformAttributeRange, rhs: AferoPlatformAttributeRange) -> Bool {
        return lhs.range.lowerBound < rhs.range.lowerBound
    }
    
    /// An attribute residing on an external MCU defined by the third party developer.
    /// The size and meaning of these attributes is defined by the developer using the
    /// Afero Profile Editor. In order to get the default value of one of these
    /// attributes, the MCU has to call getAttribute.
    case mcuApplicationSpecific
    
    /// Special attributes whose values represent GPIO pins on the Afero module
    /// or optionally on a port extender. Third party developers can use these
    /// attributes to read/write GPIO pins.
    case gpio
    
    /// These attributes store Afero version IDs which point to actual firmware
    /// version numbers on the Afero service. They are read only.
    case aferoVersions
    
    /// These attributes store MCU version IDs which point to actual firmware version
    /// numbers on the Afero service. They are read only.
    case mcuVersions
    
    case aferoApplicationSpecific
    
    /// This attribute range is specifically assigned to the hub-related attributes.
    case aferoHubSpecific
    
    /// These attributes are used to enable weather related data (including forecasts,
    /// tides, precipitation, weather alerts, etc). Also, in the future, other
    /// environmental data such as income levels, crime statistics, etc.
    case aferoCloudProvided
    
    /// These attributes hold individual temporal event records for defining a schedule
    /// that is executed by the firmware on the peripheral
    case aferoOfflineSchedules
    
    /// These attributes are used to control the behavior of Afero modules. They
    /// allow the Afero service to configure the Afero module in different ways.
    /// They can control things like advertising or wake up interval, flow control
    /// parameters, security parameters and many other configuration items.
    case aferoSystemSpecific
    
    /// All ranges.
    public static var all: [AferoPlatformAttributeRange] {
        return [
            .mcuApplicationSpecific,
            .gpio,
            .aferoVersions,
            .mcuVersions,
            .aferoApplicationSpecific,
            .aferoHubSpecific,
            .aferoCloudProvided,
            .aferoOfflineSchedules,
            .aferoSystemSpecific,
        ]
    }
    
    /// A `ClosedRange<Int>` representing the floor and ceil attributeIds for
    /// this range.
    
    var range: ClosedRange<Int> {
        switch self {
        case .mcuApplicationSpecific: return 1...1023
        case .gpio: return 1024...1065
        case .aferoVersions: return 2001...2010
        case .mcuVersions: return 2011...2020
        case .aferoApplicationSpecific: return 50000...51000
        case .aferoHubSpecific: return 51001...52000
        case .aferoCloudProvided: return 53001...59000
        case .aferoOfflineSchedules: return 59001...59999
        case .aferoSystemSpecific: return 60001...65022
        }
    }
    
    /// Initialize with an integer attribute id.
    /// - parameter attributeId: The attribute id for which to initialize a range.
    /// - note: Fails if the range is invalid.
    
    init?(attributeId: Int) {
        guard let r = AferoPlatformAttributeRange.all.filter({ $0.range.contains(attributeId) }).first else {
            return nil
        }
        self = r
    }
    
}

public extension Int {
    
    var aferoPlatformAttributeRange: AferoPlatformAttributeRange? {
        return AferoPlatformAttributeRange(attributeId: self)
    }
}

