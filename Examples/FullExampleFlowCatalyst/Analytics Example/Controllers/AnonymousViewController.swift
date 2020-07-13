//
//  AnonymousViewController.swift
//  Analytics Example
//
//  Created by Cody Garvin on 6/3/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import UIKit
import Analytics

class AnonymousViewController: StepsViewController {
    
    let anonymousUserID = "70e4ab26-3c4d-42c9-aed1-2c186738a97d"
    
    private var continueButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionString = "Login with details using identify"
        codeString = """
// Start with the analytics singleton
let analytics = Analytics.shared()

// identify screen load (sends anonymous id)
analytics.screen("Home")

// identify with anonymous user
analytics.identify(nil, traits: ["subscription": "inactive"])

// track CTA tap (sends anonymous id)
analytics.track("CTA Tapped", properties: ["plan": "premium"])
"""
        
        // Add the button
        let trackButton = UIButton.SegmentButton("Track", target: self, action: #selector(trackUser(_:)))
        continueButton = UIButton.SegmentButton("Continue", target: self, action: #selector(continueToNext(_:)))
        continueButton.isEnabled = false
    
        propertyViews = [trackButton, UIView.separator(), continueButton, UIView.separator()]
        
        // Fire off the beginning analytics
        startAnalytics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        continueButton.isEnabled = false
    }
    
    private func startAnalytics() {
        let analytics = Analytics.shared()
        
        // identify screen load
        analytics.screen("Home")
        
        // identify anonymous user
        analytics.identify(nil, traits: ["subscription": "inactive"])
    }
    
    @objc
    private func trackUser(_ sender: Any) {
        let analytics = Analytics.shared()
        // track CTA tap
        analytics.track("CTA Tapped", properties: ["plan": "premium"])
        
        continueButton.isEnabled = true
    }
    
    @objc private func continueToNext(_ sender: Any) {
        let signup = SignupViewController(nibName: nil, bundle: nil)
        navigationController?.pushViewController(signup, animated: true)
    }
}
