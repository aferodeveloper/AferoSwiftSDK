//
//  AferoSofthub+Utils.swift
//  AferoSwiftSDK
//
//  Created by Justin Middleton on 1/29/18.
//

import Foundation
import AferoSofthub


extension AferoSofthubError:  Error {

    public var localizedDescription: String {
        switch self {
        case .conclaveAccessEncoding: return "Conclave access token uses unrecognized encoding."
        case .invalidRSSIDecibelValue: return "Unrecognized RSSI decibel value"
        case .invalidStateForCmd: return "The softhub was asked to perform a command while in an invalid state. See AferoSofthub.state for current value."
        }
    }
    
}

extension AferoSofthubState: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .starting: return "Softhub starting."
        case .started: return "Softhub started."
        case .stopping: return "Softhub stopping."
        case .stopped: return "Softhub stopped."
        }
    }
    
    public var debugDescription: String {
        return "<AferoSofthubState> \(rawValue): \(description)"
    }
    
}

extension AferoSofthubCompleteReason: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .stopCalled: return "Softhub stopped as requested."
        case .missingSofthubSetupPath: return "Run was called without the ConfigName::SOFT_HUB_SETUP_PATH config value being set."
        case .setupFailed: return "The setup process for the embedded softhub has failed. (no other reason given)."
        case .fileIOError: return "I/O Error reading config values."
        case .unhandledService: return "Asked to start with an unrecognized Afero cloud."
        }
    }
    
    public var debugDescription: String {
        return "<AferoSofthubCompleteReason> \(rawValue): \(description)"
    }
    
}

extension AferoService: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        switch self {
        case .prod: return "Afero production cloud"
        case .dev: return "Afero development cloud"
        }
    }

    public var debugDescription: String {
        return "<AferoService> \(rawValue): \(description)"
    }

}
