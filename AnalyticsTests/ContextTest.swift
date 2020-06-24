//
//  ContextTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import SwiftTryCatch
import Analytics
import XCTest

class ContextTests: XCTestCase {
    
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "foobar")
        analytics = Analytics(configuration: config)
    }
    
    func testThrowsWhenUsedIncorrectly() {
        var context: Context?
        var exception: NSException?
        
        SwiftTryCatch.tryRun({
            context = Context()
        }, catchRun: { e in
            exception = e
        }, finallyRun: nil)
        
        XCTAssertNil(context)
        XCTAssertNotNil(exception)
    }
    
    func testInitializedCorrectly() {
        let context = Context(analytics: analytics)
        XCTAssertEqual(context._analytics, analytics)
        XCTAssertEqual(context.eventType, EventType.undefined)
    }
    
    func testAcceptsModifications() {
        let context = Context(analytics: analytics)
        
        let newContext = context.modify { context in
            context.userId = "sloth"
            context.eventType = .track;
        }
        XCTAssertEqual(newContext.userId, "sloth")
        XCTAssertEqual(newContext.eventType,  EventType.track)
    }
    
    func testModifiesCopyInDebugMode() {
        let context = Context(analytics: analytics).modify { context in
            context.debug = true
        }
        XCTAssertEqual(context.debug, true)
        
        let newContext = context.modify { context in
            context.userId = "123"
        }
        XCTAssertNotEqual(context, newContext)
        XCTAssertEqual(newContext.userId, "123")
        XCTAssertNil(context.userId)
    }
    
    func testModifiesSelfInNonDebug() {
        let context = Context(analytics: analytics).modify { context in
            context.debug = false
        }
        XCTAssertFalse(context.debug)
        
        let newContext = context.modify { context in
            context.userId = "123"
        }
        XCTAssertEqual(context, newContext)
        XCTAssertEqual(newContext.userId, "123")
        XCTAssertEqual(context.userId, "123")
    }
}
