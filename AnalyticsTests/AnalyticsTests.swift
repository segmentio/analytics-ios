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
    let config = SEGAnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
    let cachedSettings = [
      "integrations": [
        "Segment.io": ["apiKey": "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"]
      ],
      "plan": ["track": [:]],
    ] as NSDictionary
    var analytics: SEGAnalytics!
    var testMiddleware: TestMiddleware!
    
    beforeEach {
      testMiddleware = TestMiddleware()
      config.middlewares = [testMiddleware]
      config.trackApplicationLifecycleEvents = true
      
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
      expect(analytics.getAnonymousId()) == analytics2.getAnonymousId()
    }
    
    it("persists userId") {
      analytics.identify("testUserId1")
      
      let analytics2 = SEGAnalytics(configuration: config)
      analytics2.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)

      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId()) == "testUserId1"
      expect(analytics2.test_integrationsManager()?.test_segmentIntegration()?.test_userId()) == "testUserId1"
    }
    
    it("continues user activity") {
      let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
      activity.webpageURL = URL(string: "http://www.segment.com")
      analytics.continue(activity)
      let referrer = analytics.test_integrationsManager()?.test_segmentIntegration()?.test_referrer()
      expect(referrer?["url"] as? String) == "http://www.segment.com"
    }
    
    it("clear user data") {
      analytics.identify("testUserId1", traits: [ "Test trait key" : "Test trait value"])
      analytics.clearUserData()
      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId()).toEventually(beNil())
      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_traits()?.count).toEventually(equal(0))
    }

    it("fires Application Opened for UIApplicationDidFinishLaunching") {
      testMiddleware.swallowEvent = true
      NotificationCenter.default.post(name: .UIApplicationDidFinishLaunching, object: nil, userInfo: [
        UIApplicationLaunchOptionsKey.sourceApplication: "testApp",
        UIApplicationLaunchOptionsKey.url: "test://test",
      ])
      let event = testMiddleware.lastContext?.payload as? SEGTrackPayload
      expect(event?.event) == "Application Opened"
      expect(event?.properties?["from_background"] as? Bool) == false
      expect(event?.properties?["referring_application"] as? String) == "testApp"
      expect(event?.properties?["url"] as? String) == "test://test"
    }
    
    it("fires Application Opened during UIApplicationWillEnterForeground") {
      testMiddleware.swallowEvent = true
      NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: nil)
      let event = testMiddleware.lastContext?.payload as? SEGTrackPayload
      expect(event?.event) == "Application Opened"
      expect(event?.properties?["from_background"] as? Bool) == true
    }
  }

}
