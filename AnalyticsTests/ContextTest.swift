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
        
        var analytics: Analytics!
        
        beforeEach {
            let config = AnalyticsConfiguration(writeKey: "foobar")
            analytics = Analytics(configuration: config)
        }
        
        it("throws when used incorrectly") {
            var context: Context?
            var exception: NSException?
            
            SwiftTryCatch.tryRun({
                context = Context()
            }, catchRun: { e in
                exception = e
            }, finallyRun: nil)
            
            expect(context).to(beNil())
            expect(exception).toNot(beNil())
        }
        
        
        it("initialized correctly") {
            let context = Context(analytics: analytics)
            expect(context._analytics) == analytics
            expect(context.eventType) == .undefined
        }
        
        it("accepts modifications") {
            let context = Context(analytics: analytics)
            
            let newContext = context.modify { context in
                context.userId = "sloth"
                context.eventType = .track;
            }
            expect(newContext.userId) == "sloth"
            expect(newContext.eventType) == .track;
            
        }
        
        it("modifies copy in debug mode to catch bugs") {
            let context = Context(analytics: analytics).modify { context in
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
            let context = Context(analytics: analytics).modify { context in
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
