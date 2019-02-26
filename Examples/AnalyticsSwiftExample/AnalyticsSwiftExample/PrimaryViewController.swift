//
//  PrimaryViewController.swift
//  AnalyticsSwiftExample
//
//  Created by William Grosset on 2/12/19.
//  Copyright © 2019 Segment. All rights reserved.
//

import UIKit
import Analytics

class PrimaryViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SEGAnalytics.shared().screen("Home")
        SEGAnalytics.shared().flush()
    }
}
