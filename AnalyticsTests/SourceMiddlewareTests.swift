//
//  SourceMiddlewareTests.swift
//  AnalyticsTests
//
//  Created by Brandon Sneed on 1/23/20.
//  Copyright © 2020 Segment. All rights reserved.
//

import XCTest
import Analytics

class SourceMiddlewareTests: XCTestCase {
    let queue = DispatchQueue(label: "SourceMiddlewareTests")

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testReceiveEvents() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthru = PassthroughSourceMiddleware()
        config.sourceMiddleware = [passthru]
        
        let analytics = Analytics(configuration: config)
        analytics.identify("testUserId1")
        
        // let the async operation above complete.
        queue.sync {}
        
        XCTAssertTrue(passthru.lastContext?.eventType == .identify)
        let identify = passthru.lastContext?.payload as! IdentifyPayload
        XCTAssertTrue(identify.userId == "testUserId1")
    }

    func testModifyAndPassToNextMiddleware() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthru = PassthroughSourceMiddleware()
        let customize = CustomizeTrackMiddleware()
        config.sourceMiddleware = [customize, passthru]
        
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        // let any possible async operations above complete.
        queue.sync {}
        
        XCTAssertTrue(passthru.lastContext?.eventType == .track)
        let track = passthru.lastContext?.payload as! TrackPayload
        XCTAssertTrue(track.event == "[New] Purchase Success")
        XCTAssertTrue(track.properties!["customAttribute"] as! String == "Hello")
        XCTAssertTrue(track.properties!["nullTest"] is NSNull)
    }
    
    func testEventSwallowing() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthru = PassthroughSourceMiddleware()
        
        let customize = CustomizeTrackMiddleware()
        customize.swallowEvent = true
        
        config.sourceMiddleware = [customize, passthru]

        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        // let the async operation above complete.
        queue.sync {}
        
        XCTAssertTrue(passthru.lastContext == nil)
    }


}
