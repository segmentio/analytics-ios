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
    var testApplication: TestApplication!

    beforeEach {
      testMiddleware = TestMiddleware()
      config.middlewares = [testMiddleware]
      testApplication = TestApplication()
      config.application = testApplication
      config.trackApplicationLifecycleEvents = true

      analytics = SEGAnalytics(configuration: config)
      analytics.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
    }

    afterEach {
      analytics.reset()
    }

    it("initialized correctly") {
      expect(analytics.configuration.flushAt) == 20
      expect(analytics.configuration.flushInterval) == 30
      expect(analytics.configuration.maxQueueSize) == 1000
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

    /* This test is pretty flaky.
    it("continues user activity") {
      let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
      activity.webpageURL = URL(string: "http://www.segment.com")
      analytics.continue(activity)
      let referrer = analytics.test_integrationsManager()?.test_segmentIntegration()?.test_referrer()
      expect(referrer?["url"] as? String).toEventually(equal("http://www.segment.com"))
    }
    */

    it("clears user data") {
      analytics.identify("testUserId1", traits: [ "Test trait key" : "Test trait value"])
      analytics.reset()
      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId()).toEventually(beNil())
      expect(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_traits()?.count).toEventually(equal(0))
    }

    it("fires Application Opened for UIApplicationDidFinishLaunching") {
      testMiddleware.swallowEvent = true
      NotificationCenter.default.post(name: .UIApplicationDidFinishLaunching, object: testApplication, userInfo: [
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
      NotificationCenter.default.post(name: .UIApplicationWillEnterForeground, object: testApplication)
      let event = testMiddleware.lastContext?.payload as? SEGTrackPayload
      expect(event?.event) == "Application Opened"
      expect(event?.properties?["from_background"] as? Bool) == true
    }

    it("flushes when UIApplicationDidEnterBackgroundNotification is fired") {
      analytics.track("test")
      NotificationCenter.default.post(name: .UIApplicationDidEnterBackground, object: testApplication)
      expect(testApplication.backgroundTasks.count).toEventually(equal(1))
      expect(testApplication.backgroundTasks[0].isEnded).toEventually(beFalse())
    }
    
    it("respects maxQueueSize") {
      let max = 72
      config.maxQueueSize = UInt(max)

      for i in 1...max * 2 {
        analytics.track("test #\(i)")
      }

      let integration = analytics.test_integrationsManager()?.test_segmentIntegration()
      expect(integration).notTo(beNil())
      
      var sent = 0

      analytics.flush()
      integration?.test_dispatchBackground {
        if let count = integration?.test_queue()?.count {
          sent = count
        }
        else {
          sent = -1
        }
      }
      
      expect(sent).toEventually(equal(max))
    }

    it("protocol conformance should not interfere with UIApplication interface") {
      // In Xcode8/iOS10, UIApplication.h typedefs UIBackgroundTaskIdentifier as NSUInteger,
      // whereas Swift has UIBackgroundTaskIdentifier typealiaed to Int.
      // This is likely due to a custom Swift mapping for UIApplication which got out of sync.
      // If we extract the exact UIApplication method names in SEGApplicationProtocol,
      // it will cause a type mismatch between the return value from beginBackgroundTask
      // and the argument for endBackgroundTask.
      // This would impact all code in a project that imports the Segment framework.
      // Note that this doesn't appear to be an issue any longer in Xcode9b3.
      let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
      UIApplication.shared.endBackgroundTask(task)
    }
    
    it("flushes using flushTimer") {
      let integration = analytics.test_integrationsManager()?.test_segmentIntegration()

      analytics.track("test")

      expect(integration?.test_flushTimer()).toEventuallyNot(beNil())
      expect(integration?.test_batchRequest()).to(beNil())

      integration?.test_flushTimer()?.fire()
      
      expect(integration?.test_batchRequest()).toEventuallyNot(beNil())
    }

    it("respects flushInterval") {
      let timer = analytics
        .test_integrationsManager()?
        .test_segmentIntegration()?
        .test_flushTimer()
      
      expect(timer).toNot(beNil())
      expect(timer?.timeInterval) == config.flushInterval
    }
  }

}
