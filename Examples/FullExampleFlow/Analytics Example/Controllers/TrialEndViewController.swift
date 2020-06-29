//
//  TrialEndViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/29/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit
import Analytics

class TrialEndViewController: StepsViewController {
    
    let anonymousUserID = "70e4ab26-3c4d-42c9-aed1-2c186738a97d"
    
    private var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionString = "Login with details using identify"
        codeString = """
// Start with the analytics singleton
let analytics = Analytics.shared()

// identify screen load
analytics.screen("Dashboard")

// identify anonymous user
analytics.track("Trial Ended", properties: [...])

// track delete request
analytics.track("Account Delete request", properties: ["account_id": "AA-BB-CC-USER-ID"])
        
// removed user
analytics.track("Account Deleted", properties: ["username": "pgibbons", "account_id": "AA-BB-CC-USER-ID"])
        
// Signed out
analytics.track("Signed Out", properties: ["username": "pgibbons"])
"""
        
        // Add the button
        let deleteButton = UIButton.SegmentButton("Request Delete Account", target: self, action: #selector(deleteUser(_:)))
        continueButton = UIButton.SegmentButton("Done", target: self, action: #selector(continueToNext(_:)))
        continueButton.isEnabled = false
    
        propertyViews = [deleteButton, UIView.separator(), continueButton, UIView.separator()]
        
        // Fire off the beginning analytics
        startAnalytics()
    }
    
    private func startAnalytics() {
        let analytics = Analytics.shared()
        
        // identify screen load
        analytics.screen("Dashboard")
        
        // identify anonymous user
        analytics.track("Trial Ended", properties: ["trial_start": "2020-06-29", "trial_end": "2020-06-30", "trial_plan": "premium"])
    }
    
    @objc
    private func deleteUser(_ sender: Any) {
        let analytics = Analytics.shared()
        // track delete request
        analytics.track("Account Delete request", properties: ["account_id": "AA-BB-CC-USER-ID"])
        
        // Some async request
        DispatchQueue.global().async {
            // removed user
            analytics.track("Account Deleted", properties: ["username": "pgibbons", "account_id": "AA-BB-CC-USER-ID"])
            // Signed out
            analytics.track("Signed Out", properties: ["username": "pgibbons"])
            DispatchQueue.main.async {
                self.continueButton.isEnabled = true
            }
        }
    }
    
    @objc private func continueToNext(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
