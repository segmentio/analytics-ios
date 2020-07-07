//
//  ViewController.swift
//  SegmentMac
//
//  Created by Cody Garvin on 7/6/20.
//  Copyright © 2020 Cody Garvin. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var signinButton: NSButton!
    @IBOutlet weak var associateButton: NSButton!
    @IBOutlet weak var signoutButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func signinTapped(_ sender: Any) {
        print("No \(sender)")
        associateButton.isEnabled = true
    }
}

