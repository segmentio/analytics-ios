//
//  SecondaryViewController.swift
//  AnalyticsSwiftExample
//
//  Created by William Grosset on 2/12/19.
//  Copyright © 2019 Segment. All rights reserved.
//

import UIKit
import Analytics

class SecondaryViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button.layer.cornerRadius = 10
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 5)
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.4
        button.titleLabel?.textAlignment = NSTextAlignment.center
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SEGAnalytics.shared().screen("About")
        SEGAnalytics.shared().flush()
    }

    @IBAction func buttonClicked(_ sender: Any) {
        SEGAnalytics.shared().track("Learn About Segment Clicked")
        guard let url = URL(string: "https://github.com/segmentio/analytics-ios/blob/master/README.md#quickstart") else { return }
        UIApplication.shared.open(url)
    }
}
