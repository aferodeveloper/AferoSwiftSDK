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
    
    public func valueForSystemAttribute(_ attribute: AferoSystemAttribute) -> AttributeValue? {
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

