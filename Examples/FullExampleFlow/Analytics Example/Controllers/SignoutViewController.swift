//
//  SignoutViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/9/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit
import Analytics

class SignoutViewController: StepsViewController {
    
    private var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionString = "Login with details using identify"
        codeString = """
// Start with the analytics singleton
let analytics = Analytics.shared()

// Screen
analytics.screen("Signout")

// Signout user
analytics.track("Signed Out", properties: ["username": "pgibbons"])
"""
        
        // Add the button
        let signoutButton = UIButton.SegmentButton("Signout", target: self, action: #selector(signout(_:)))
        continueButton = UIButton.SegmentButton("Continue", target: self, action: #selector(continueToNext(_:)))
        continueButton.isEnabled = false
    
        propertyViews = [signoutButton, UIView.separator(), continueButton, UIView.separator()]
        
        // Fire off the beginning analytics
        startAnalytics()
    }
    
    private
    func startAnalytics() {
        let analytics = Analytics.shared()
        
        // identify screen load
        analytics.screen("Signout")
    }
    
    @objc
    func signout(_ sender: Any) {
        let analytics = Analytics.shared()
        // track CTA tap
        analytics.track("Signed Out", properties: ["username": "pgibbons"])
        continueButton.isEnabled = true
    }
    
    @objc
    func continueToNext(_ sender: Any) {
        let signinVC = SigninViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(signinVC, animated: true)
    }
}
