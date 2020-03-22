//
//  MiddlewareTests.swift
//  Analytics
//
//  Created by Tony Xiao on 1/9/17.
//  Copyright © 2017 Segment. All rights reserved.
//


import Quick
import Nimble
import Analytics

// Changing event names and adding custom attributes
let customizeAllTrackCalls = SEGBlockMiddleware { (context, next) in
  if context.eventType == .track {
    next(context.modify { ctx in
      guard let track = ctx.payload as? SEGTrackPayload else {
        return
      }
      let newEvent = "[New] \(track.event)"
      var newProps = track.properties ?? [:]
      newProps["customAttribute"] = "Hello"
      newProps["nullTest"] = NSNull()
      ctx.payload = SEGTrackPayload(
        event: newEvent,
        properties: newProps,
        context: track.context,
        integrations: track.integrations
      )
    })
  } else {
    next(context)
  }
}

// Simply swallows all calls and does not pass events downstream
let eatAllCalls = SEGBlockMiddleware { (context, next) in
}

class MiddlewareTests: QuickSpec {
  override func spec() {
    it("receives events") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.middlewares = [
        passthrough,
      ]
      let analytics = SEGAnalytics(configuration: config)
      analytics.identify("testUserId1")
      expect(passthrough.lastContext?.eventType) == SEGEventType.identify
      let identify = passthrough.lastContext?.payload as? SEGIdentifyPayload
      expect(identify?.userId) == "testUserId1"
    }
    
    it("modifies and passes event to next") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.middlewares = [
        customizeAllTrackCalls,
        passthrough,
      ]
      let analytics = SEGAnalytics(configuration: config)
      analytics.track("Purchase Success")
      expect(passthrough.lastContext?.eventType) == SEGEventType.track
      let track = passthrough.lastContext?.payload as? SEGTrackPayload
      expect(track?.event) == "[New] Purchase Success"
      expect(track?.properties?["customAttribute"] as? String) == "Hello"
      let isNull = (track?.properties?["nullTest"] is NSNull)
      expect(isNull) == true
    }
    
    it("expects event to be swallowed if next is not called") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.middlewares = [
        eatAllCalls,
        passthrough,
      ]
      let analytics = SEGAnalytics(configuration: config)
      analytics.track("Purchase Success")
      expect(passthrough.lastContext).to(beNil())
    }
  }
}
