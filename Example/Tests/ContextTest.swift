//
//  ContextTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import SwiftTryCatch
import Analytics

class ContextTests: QuickSpec {
  override func spec() {
    
    var analytics: SEGAnalytics!
    
    beforeEach {
      let config = SEGAnalyticsConfiguration(writeKey: "foobar")
      SEGAnalytics.setupWithConfiguration(config)
      analytics = SEGAnalytics.sharedAnalytics()
    }
    
    it("throws when used incorrectly") {
      var context: SEGContext?
      var exception: NSException?
      
      SwiftTryCatch.tryRun({
        context = SEGContext()
      }, catchRun: { e in
        exception = e
      }, finallyRun: nil)
      
      expect(context).to(beNil())
      expect(exception).toNot(beNil())
    }

    
    it("initialized correctly") {
      let context = SEGContext(analytics: analytics)
      expect(context._analytics) == analytics
      expect(context.eventType) == SEGEventType.Undefined
    }
    
    it("accepts modifications") {
      let context = SEGContext(analytics: analytics)
      
      let newContext = context.modify { context in
        context.userId = "sloth"
        context.eventType = .Track;
      }
      expect(newContext.userId) == "sloth"
      expect(newContext.eventType) == SEGEventType.Track;
      
    }
    
    it("modifies copy in debug mode to catch bugs") {
      let context = SEGContext(analytics: analytics).modify { context in
        context.debug = true
      }
      expect(context.debug) == true
      
      let newContext = context.modify { context in
        context.userId = "123"
      }
      expect(context) !== newContext
      expect(newContext.userId) == "123"
      expect(context.userId).to(beNil())
    }
    
    it("modifies self in non-debug mode to optimize perf.") {
      let context = SEGContext(analytics: analytics).modify { context in
        context.debug = false
      }
      expect(context.debug) == false
      
      let newContext = context.modify { context in
        context.userId = "123"
      }
      expect(context) === newContext
      expect(newContext.userId) == "123"
      expect(context.userId) == "123"
    }
    
  }
  
}
