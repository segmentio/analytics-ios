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

extension SEGAnalytics {
  func test_integrationsManager() -> SEGIntegrationsManager? {
    return self.value(forKey: "integrationsManager") as? SEGIntegrationsManager
  }
}

extension SEGIntegrationsManager {
  func test_integrations() -> [String: SEGIntegration]? {
    return self.value(forKey: "integrations") as? [String: SEGIntegration]
  }
  func test_segmentIntegration() -> SEGSegmentIntegration? {
    return self.test_integrations()?["Segment.io"] as? SEGSegmentIntegration
  }
  func test_setCachedSettings(settings: NSDictionary) {
    self.perform("setCachedSettings:", with: settings)
  }
}

extension SEGSegmentIntegration {
  func test_userId() -> String? {
    return self.value(forKey: "userId") as? String
  }
}

class AnalyticsTests: QuickSpec {
  override func spec() {
    let config = SEGAnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
    let cachedSettings = [
      "integrations": [
        "Segment.io": ["apiKey": "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"]
      ],
      "plan": ["track": []],
    ] as NSDictionary
    var analytics: SEGAnalytics!
    
    beforeEach {
      analytics = SEGAnalytics(configuration: config)
      analytics.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
    }
    
    afterEach {
      analytics.reset()
    }
    
    it("initialized correctly") {
      expect(analytics.configuration.flushAt) == 20
      expect(analytics.configuration.writeKey) == "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"
      expect(analytics.configuration.shouldUseLocationServices) == false
      expect(analytics.configuration.enableAdvertisingTracking) == true
      expect(analytics.configuration.shouldUseBluetooth) == false
      expect(analytics.getAnonymousId()).toNot(beNil())
    }
    
    it("persists anonymousId") {
      let analytics2 = SEGAnalytics(configuration: config)
      expect(analytics.getAnonymousId()) == analytics2?.getAnonymousId()
    }
    
    it("persists userId") {
      analytics.identify("testUserId1")
      
      let analytics2 = SEGAnalytics(configuration: config)
      analytics2?.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)

      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId()) == "testUserId1"
      expect(analytics2?.test_integrationsManager()?.test_segmentIntegration()?.test_userId()) == "testUserId1"
    }
  }

}
