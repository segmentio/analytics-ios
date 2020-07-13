//
//  SignupViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/9/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit
import Analytics

class SignupViewController: StepsViewController {
    
    private var continueButton: UIButton!
    private var trackButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionString = "Login with details using identify"
        codeString = """
// Start with the analytics singleton
let analytics = Analytics.shared()

// Screen
analytics.screen("Signup")

// create user
analytics.track("Create Account", properties: ["Signed Up": ...])
        
// Alias new user id with anonymous id
analytics.alias("AA-BB-CC-NEW-ID")
        
// Start trial
analytics.track("Trial Started", properties: ...)
"""
        
        // Add the button
        let createButton = UIButton.SegmentButton("Create Account", target: self, action: #selector(createUser(_:)))
        trackButton = UIButton.SegmentButton("Start Trial", target: self, action: #selector(trackUser(_:)))
        trackButton.isEnabled = false
        continueButton = UIButton.SegmentButton("Continue", target: self, action: #selector(continueToNext(_:)))
        continueButton.isEnabled = false
    
        propertyViews = [createButton, UIView.separator(), trackButton, UIView.separator(), continueButton, UIView.separator()]
        
        // Fire off the beginning analytics
        startAnalytics()
    }
    
    private
    func startAnalytics() {
        let analytics = Analytics.shared()
        
        // identify screen load
        analytics.screen("Signup")
    }
    
    @objc
    func createUser(_ sender: Any) {
        let analytics = Analytics.shared()
        // track CTA tap
        analytics.track("Create Account", properties: ["Signed Up": ["first": "Peter", "last": "Gibbons", "phone": "pgibbons"]])
        analytics.alias("AA-BB-CC-NEW-ID")
        trackButton.isEnabled = true
    }
    
    @objc func trackUser(_ sender: Any) {
        let analytics = Analytics.shared()
        // track user
        analytics.track("Trial Started", properties: ["start_date": "2018-08-27"])
        
        continueButton.isEnabled = true
    }
    
    @objc
    func continueToNext(_ sender: Any) {
        let invite = InviteViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(invite, animated: true)
    }
}
