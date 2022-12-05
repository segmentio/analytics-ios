//
//  ViewController.swift
//  SegmentMac
//
//  Created by Cody Garvin on 7/6/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import Cocoa
import Segment

class ViewController: NSViewController {
    
    @IBOutlet weak var signinButton: NSButton!
    @IBOutlet weak var associateButton: NSButton!
    @IBOutlet weak var signoutButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = AnalyticsConfiguration(writeKey: "GM88xxNqA6PfthZE9ZzA2AREQBMjc6xA")

        // Enable this to record certain application events automatically!
        configuration.trackApplicationLifecycleEvents = true
        // Enable this to record screen views automatically!
        configuration.recordScreenViews = true
        configuration.flushAt = 1
        Analytics.setup(with: configuration)


        // Do any additional setup after loading the view.
        let analytics = Analytics.shared()
        
        // identify screen load
        analytics.screen("SegmentMac")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func signinTapped(_ sender: Any) {
        associateButton.isEnabled = true
        Analytics.shared().track("Signed In")
    }
    
    @IBAction func associateTapped(_ sender: Any) {
        signoutButton.isEnabled = true
        Analytics.shared().alias("New-Associate-ID")
    }
    
    @IBAction func signoutTapped(_ sender: Any) {
        Analytics.shared().track("Signed Out")
    }
}

