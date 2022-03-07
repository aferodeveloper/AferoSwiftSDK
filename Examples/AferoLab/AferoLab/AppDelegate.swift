//
//  AppDelegate.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import CocoaLumberjack
import AppAuth

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // property of the app's AppDelegate
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureLogging()
        return true
    }

    func configureLogging() {
        
        dynamicLogLevel = DDLogLevel.debug
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        #if DEBUG
            DDTTYLogger.sharedInstance.logFormatter = AferoTTYADBLogFormatter()
            DDLog.add(DDTTYLogger.sharedInstance)
        #else
            DDASLLogger.sharedInstance.logFormatter = AferoASLADBLogFormatter()
            DDLog.add(DDASLLogger.sharedInstance)
        #endif
        
        
    }

}

