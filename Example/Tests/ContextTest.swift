//
//  ContextTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

class ContextTests: QuickSpec {
  override func spec() {
    
    var analytics: SEGAnalytics!
    
    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "foobar")
      SEGAnalytics.setupWithConfiguration(config)
      analytics = SEGAnalytics.sharedAnalytics()
    }
    
    it("initialized correctly") {
      let context = SEGContext(analytics: analytics)
      expect(context._analytics) == analytics
      expect(context.eventType) == SEGEventType.Undefined
    }
    
    xit("accepts modifications") {
      let context = SEGContext(analytics: analytics)
      let newContext = context.modify { context in
        context.userId = "sloth"
        context.eventType = .Track;
      }
      expect(newContext.userId) == "sloth"
      expect(newContext.eventType) == SEGEventType.Track;
    }
  }
  
}
