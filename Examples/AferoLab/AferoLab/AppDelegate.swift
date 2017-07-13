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
        
        defaultDebugLevel = DDLogLevel.debug
        
        DDTTYLogger.sharedInstance.logFormatter = AferoTTYADBLogFormatter()
        DDASLLogger.sharedInstance.logFormatter = AferoASLADBLogFormatter()
        
        DDLog.add(DDTTYLogger.sharedInstance)
        DDLog.add(DDASLLogger.sharedInstance)
        
    }

}

