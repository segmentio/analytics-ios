//
//  TrackingTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//


import Quick
import Nimble
import Analytics

class TrackingTests: QuickSpec {
  override func spec() {
    var passthrough: SEGPassthroughMiddleware!
    var analytics: SEGAnalytics!
    
    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
      passthrough = SEGPassthroughMiddleware()
      config.middlewares = [
        passthrough,
      ]
      analytics = SEGAnalytics(configuration: config)
    }
    
    afterEach {
      analytics.reset()
    }
    
    it("handles identify:") {
      analytics.identify("testUserId1", traits: [
        "firstName": "Peter"
      ])
      expect(passthrough.lastContext?.eventType) == SEGEventType.identify
      let identify = passthrough.lastContext?.payload as? SEGIdentifyPayload
      expect(identify?.userId) == "testUserId1"
      expect(identify?.traits?["firstName"] as? String) == "Peter"
    }
    
    it("handles track:") {
      analytics.track("User Signup", properties: [
        "method": "SSO"
        ])
      expect(passthrough.lastContext?.eventType) == SEGEventType.track
      let payload = passthrough.lastContext?.payload as? SEGTrackPayload
      expect(payload?.event) == "User Signup"
      expect(payload?.properties?["method"] as? String) == "SSO"
    }
    
    it("handles alias:") {
      analytics.alias("persistentUserId")
      expect(passthrough.lastContext?.eventType) == SEGEventType.alias
      let payload = passthrough.lastContext?.payload as? SEGAliasPayload
      expect(payload?.theNewId) == "persistentUserId"
    }
    
    it("handles screen:") {
      analytics.screen("Home", properties: [
        "referrer": "Google"
      ])
      expect(passthrough.lastContext?.eventType) == SEGEventType.screen
      let screen = passthrough.lastContext?.payload as? SEGScreenPayload
      expect(screen?.name) == "Home"
      expect(screen?.properties?["referrer"] as? String) == "Google"
    }
    
    it("handles group:") {
      analytics.group("acme-company", traits: [
        "employees": 2333
      ])
      expect(passthrough.lastContext?.eventType) == SEGEventType.group
      let payload = passthrough.lastContext?.payload as? SEGGroupPayload
      expect(payload?.groupId) == "acme-company"
      expect(payload?.traits?["employees"] as? Int) == 2333
    }
  }

}
