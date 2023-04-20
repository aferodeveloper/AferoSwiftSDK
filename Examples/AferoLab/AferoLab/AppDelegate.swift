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
        
        if #available(iOS 15.0, *) {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor(red: 0.953, green: 0.686, blue: 0.333, alpha: 1.0)
            
            UINavigationBar.appearance().standardAppearance = navigationBarAppearance
            UINavigationBar.appearance().compactAppearance = navigationBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
        
        return true
    }

    func configureLogging() {
        
        dynamicLogLevel = DDLogLevel.debug
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        #if DEBUG
            guard let logger: DDTTYLogger = DDTTYLogger.sharedInstance else {
                return
            }
            logger.logFormatter = AferoTTYADBLogFormatter()
            DDLog.add(logger)
        #else
            guard let logger: DDTTYLogger = DDTTYLogger.sharedInstance else {
                return
            }
            logger.logFormatter = AferoASLADBLogFormatter()
            DDLog.add(logger)
    
        #endif
        
        
    }

}

