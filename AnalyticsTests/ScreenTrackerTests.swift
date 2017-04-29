//
//  ScreenTrackerTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

var staticMockVC: UIViewController!

class mockViewController: UIViewController {
  override class func seg_top() -> UIViewController? {
    return staticMockVC
  }
}

class ScreenTrackerTests: QuickSpec {
  override func spec() {

    var test: TestMiddleware!

    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "foobar")
      test = TestMiddleware()
      config.middlewares = [test]
      // This is really not ideal to be using a global
      // singleton, but don't have better choices atm
      SEGAnalytics.setup(with: config)
    }

    it("tracks screen with correct title") {
      UIViewController.seg_swizzleViewDidAppear()
      staticMockVC = mockViewController()
      staticMockVC.title = "Mock Screen"
      staticMockVC.viewDidLoad()
      staticMockVC.viewWillAppear(true)
      staticMockVC.viewDidAppear(true)
    
      let payload = test.lastContext?.payload as? SEGScreenPayload
      expect(payload?.name) == "Mock Screen"
    }

  }

}
