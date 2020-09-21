//
//  MiddlewareTests.swift
//  Analytics
//
//  Created by Tony Xiao on 1/9/17.
//  Copyright © 2017 Segment. All rights reserved.
//


import Segment
import XCTest

// Changing event names and adding custom attributes
let customizeAllTrackCalls = BlockMiddleware { (context, next) in
    if context.eventType == .track {
        next(context.modify { ctx in
            guard let track = ctx.payload as? TrackPayload else {
                return
            }
            let newEvent = "[New] \(track.event)"
            var newProps = track.properties ?? [:]
            newProps["customAttribute"] = "Hello"
            newProps["nullTest"] = NSNull()
            ctx.payload = TrackPayload(
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
let eatAllCalls = BlockMiddleware { (context, next) in
}

class SourceMiddlewareTests: XCTestCase {
    
    func testReceivesEvents() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            passthrough,
        ]
        let analytics = Analytics(configuration: config)
        analytics.identify("testUserId1")
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.identify)
        let identify = passthrough.lastContext?.payload as? IdentifyPayload
        XCTAssertEqual(identify?.userId, "testUserId1")
    }
    
    func testModifiesAndPassesEventToNext() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            customizeAllTrackCalls,
            passthrough,
        ]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let track = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(track?.event, "[New] Purchase Success")
        XCTAssertEqual(track?.properties?["customAttribute"] as? String, "Hello")
        let isNull = (track?.properties?["nullTest"] is NSNull)
        XCTAssert(isNull)
    }
    
    func testExpectsEventToBeSwallowed() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            eatAllCalls,
            passthrough,
        ]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        XCTAssertNil(passthrough.lastContext)
    }
}

class IntegrationMiddlewareTests: XCTestCase {
    
    func testReceivesEvents() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.destinationMiddleware = [DestinationMiddleware(key: SegmentIntegrationFactory().key(), middleware: [passthrough])]
        let analytics = Analytics(configuration: config)
        analytics.identify("testUserId1")
        
        // pump the runloop until we have a last context.
        // integration middleware is held up until initialization is completed.
        let currentTime = Date()
        while(passthrough.lastContext == nil && currentTime < currentTime + 60) {
            sleep(1);
        }
        
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.identify)
        let identify = passthrough.lastContext?.payload as? IdentifyPayload
        XCTAssertEqual(identify?.userId, "testUserId1")
    }
    
    func testModifiesAndPassesEventToNext() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.destinationMiddleware = [DestinationMiddleware(key: SegmentIntegrationFactory().key(), middleware: [customizeAllTrackCalls, passthrough])]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        // pump the runloop until we have a last context.
        // integration middleware is held up until initialization is completed.
        let currentTime = Date()
        while(passthrough.lastContext == nil && currentTime < currentTime + 60) {
            sleep(1)
        }
        
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let track = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(track?.event, "[New] Purchase Success")
        XCTAssertEqual(track?.properties?["customAttribute"] as? String, "Hello")
        let isNull = (track?.properties?["nullTest"] is NSNull)
        XCTAssert(isNull, "Should be true")
    }
    
    func testExpectsEventToBeSwallowedIfOtherIsNotCalled() {
        // Since we're testing that an event is dropped, the previously used run loop pump won't work here.
        var initialized = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SEGAnalyticsIntegrationDidStart), object: nil, queue: nil) { (notification) in
            initialized = true
        }
        
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthrough = PassthroughMiddleware()
        config.destinationMiddleware = [DestinationMiddleware(key: SegmentIntegrationFactory().key(), middleware: [eatAllCalls, passthrough])]
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        while (!initialized) {
            sleep(1)
        }
        
        XCTAssertNil(passthrough.lastContext)
    }
}
