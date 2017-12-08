//
//  AppDelegate.swift
//  AferoLab
//
//  Created by Justin Middleton on 3/17/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit
import CocoaLumberjack

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        configureLogging()
        return true
    }

    func configureLogging() {
        
        defaultDebugLevel = DDLogLevel.verbose
        
        #if DEBUG
            DDTTYLogger.sharedInstance.logFormatter = AferoTTYADBLogFormatter()
            DDLog.add(DDTTYLogger.sharedInstance)
        #else
            DDASLLogger.sharedInstance.logFormatter = AferoASLADBLogFormatter()
            DDLog.add(DDASLLogger.sharedInstance)
        #endif
        
        
    }

}

