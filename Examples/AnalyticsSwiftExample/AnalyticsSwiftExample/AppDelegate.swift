//
//  AppDelegate.swift
//  AnalyticsSwiftExample
//
//  Created by William Grosset on 2/12/19.
//  Copyright © 2019 Segment. All rights reserved.
//

import UIKit
import Analytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = SEGAnalyticsConfiguration(writeKey: "YOUR_WRITE_KEY")
        config.trackApplicationLifecycleEvents = true
        SEGAnalytics.setup(with: config)
        return true
    }
}
