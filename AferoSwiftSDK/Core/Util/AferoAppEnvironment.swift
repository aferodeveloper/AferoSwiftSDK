//
//  AppEnvironmet.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import Foundation
import RSEnvironment

// MARK: - Environment Info

public struct AferoAppEnvironment {
    
    static var apnsToken: Data?
    
    static let systemOSVersion = RSEnvironment.system.version.string
    static let systemBaseSDK = RSEnvironment.baseSDK.version.string
    static let systemDeploymentTarget = RSEnvironment.deploymentTarget.version.string
    
    static let screenSize = RSEnvironment.screen.size
    static let screenResolution = RSEnvironment.screen.resolution
    static let screenScale = RSEnvironment.screen.scale
    
    static let modelId = RSEnvironment.hardware.modelID
    static let modelName = RSEnvironment.hardware.modelName
    static let isSimulator = RSEnvironment.hardware.isSimulator
    static let vendorId = UIDevice.current.identifierForVendor?.uuidString
    static let deviceName = UIDevice.current.name
    
    static let appVersion = RSEnvironment.app.version.string
    static let appBuildNumber: AnyObject = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as AnyObject? ?? "<unknown>" as AnyObject
    
    static let appBundleName: String! = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as! String
    
    static let appGroupName: String! = Bundle.main.object(forInfoDictionaryKey: "KIAppGroupKey") as! String
    
    static let appName = RSEnvironment.app.name
    static let appIdentifier = RSEnvironment.app.bundleID
    
    static var scaleAndLocale: [String: String] {
        return [
            "locale": Locale.autoupdatingCurrent.identifier,
            "imageSize": "\(UInt(RSEnvironment.screen.scale))x"
        ]
    }
    
    #if DEBUG
    static let appBuildType = "DEBUG"
    #elseif ADHOC
    static let appBuildType = "ADHOC"
    #elseif RELEASE
    static let appBuildType = "RELEASE"
    #else
    static let appBuildType = "<unknown>"
    #endif
    
    static let buildIdentifier = "\(appIdentifier!):\(shortBuildIdentifier)"
    
    static let shortBuildIdentifier = "\(appVersion!)#\(appBuildNumber) \(appBuildType)"
    
    static var environmentString: String {
        let dict = environmentInfoDict
        var ret = "-=< App Environment >=-\n"
        let defaultStringValue = "<unknown>"
        
        if let apnsTokenString = apnsToken?.base64EncodedString(options: NSData.Base64EncodingOptions()) {
            ret += "apnsToken: \(apnsTokenString)\n"
        } else {
            ret += "apnsToken: NONE\n"
        }
        
        ret += environmentInfoDict.keys.sorted().map { "\($0): \(dict[$0] ?? defaultStringValue )" }.joined(separator: "\n")
        ret += "-=< End App Environment >=-\n"
        return ret
    }
    
    static var environmentInfoDict: [String: Any] {
        var ret: [String: Any] = [:]
        
        if let systemOSVersion = systemOSVersion {
            ret["system_os_version"] = systemOSVersion
        }
        
        if let systemBaseSDK = systemBaseSDK {
            ret["system_base_sdk"] = systemBaseSDK
        }
        
        if let systemDeploymentTarget = systemDeploymentTarget {
            ret["system_deployment_target"] = systemDeploymentTarget
        }
        
        ret["hardware_screen_size"] = "\(screenSize.width)x\(screenSize.height)"
        
        ret["hardware_screen_resolution"] = "\(screenResolution.width)x\(screenResolution.height)"
        
        ret["hardware_screen_scale"] = screenScale
        
        if let modelId = modelId {
            ret["hardware_model_id"] = modelId
        }
        
        if let modelName = modelName {
            ret["hardware_model_name"] = modelName
        }
        
        ret["hardware_is_simulator"] = isSimulator
        
        if let vendorId = vendorId {
            ret["hardware_vendor_id"] = vendorId
        } else {
            ret["hardware_vendor_id"] = "<unknown>"
        }
        
        ret["hardware_device_name"] = deviceName
        
        if let appVersion = appVersion {
            ret["app_version"] = appVersion
        }
        
        ret["app_build_number"] = appBuildNumber
        
        if let appBundleName = appBundleName {
            ret["app_bundle_name"] = appBundleName
        }
        
        if let appName = appName {
            ret["app_name"] = appName
        }
        
        if let appIdentifier = appIdentifier {
            ret["app_identifier"] = appIdentifier
        }
        
        return ret
        
    }
    
}

