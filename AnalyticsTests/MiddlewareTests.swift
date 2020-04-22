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

class SourceMiddlewareTests: QuickSpec {
  override func spec() {
    it("receives events") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.sourceMiddleware = [
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
      config.sourceMiddleware = [
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
      config.sourceMiddleware = [
        eatAllCalls,
        passthrough,
      ]
      let analytics = SEGAnalytics(configuration: config)
      analytics.track("Purchase Success")
      expect(passthrough.lastContext).to(beNil())
    }
  }
}

class IntegrationMiddlewareTests: QuickSpec {
  override func spec() {
    it("receives events") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.integrationMiddleware = [SEGIntegrationMiddleware(key: SEGSegmentIntegrationFactory().key(), middleware: [passthrough])]
      let analytics = SEGAnalytics(configuration: config)
      analytics.identify("testUserId1")
      
      // pump the runloop until we have a last context.
      // integration middleware is held up until initialization is completed.
      waitUntil(timeout: 60) { done in
        let queue = DispatchQueue(label: "test")
        queue.async {
          while(passthrough.lastContext == nil) {
            sleep(1);
          }
          done()
        }
      }
      
      expect(passthrough.lastContext?.eventType) == SEGEventType.identify
      let identify = passthrough.lastContext?.payload as? SEGIdentifyPayload
      expect(identify?.userId) == "testUserId1"
    }
    
    it("modifies and passes event to next") {
      let config = SEGAnalyticsConfiguration(writeKey: "TESTKEY")
      let passthrough = SEGPassthroughMiddleware()
      config.integrationMiddleware = [SEGIntegrationMiddleware(key: SEGSegmentIntegrationFactory().key(), middleware: [customizeAllTrackCalls, passthrough])]
      let analytics = SEGAnalytics(configuration: config)
      analytics.track("Purchase Success")
      
      // pump the runloop until we have a last context.
      // integration middleware is held up until initialization is completed.
      waitUntil(timeout: 60) { done in
        let queue = DispatchQueue(label: "test")
        queue.async {
          while(passthrough.lastContext == nil) {
            sleep(1)
          }
          done()
        }
      }
      
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
      config.integrationMiddleware = [SEGIntegrationMiddleware(key: SEGSegmentIntegrationFactory().key(), middleware: [eatAllCalls, passthrough])]
      let analytics = SEGAnalytics(configuration: config)
      analytics.track("Purchase Success")

      // Since we're testing that an event is dropped, the previously used run loop pump won't work here.
      var initialized = false;
      NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SEGAnalyticsIntegrationDidStart), object: nil, queue: nil) { (notification) in
        initialized = true;
      }
      waitUntil(timeout: 60) { done in
        let queue = DispatchQueue(label: "test")
        queue.async {
          while (initialized != true) {
            sleep(1)
          }
          done()
        }
      }

      expect(passthrough.lastContext).to(beNil())
    }
  }
}
