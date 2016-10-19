//
//  AnalyticsTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//


import Quick
import Nimble
import Analytics

class AnalyticsTests: QuickSpec {
  override func spec() {
    
    var analytics: SEGAnalytics!
    
    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
      SEGAnalytics.setup(with: config)
      analytics = SEGAnalytics.shared()
    }
    
    it("initialized correctly") {
      expect(analytics.configuration.flushAt) == 20
      expect(analytics.configuration.writeKey) == "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"
      expect(analytics.configuration.shouldUseLocationServices) == false
      expect(analytics.configuration.enableAdvertisingTracking) == true
      expect(analytics.configuration.shouldUseBluetooth) == false
    }
  }

}
