//
//  TrackingTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//


import Segment
import XCTest

class TrackingTests: XCTestCase {
    
    var passthrough: PassthroughMiddleware!
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
        passthrough = PassthroughMiddleware()
        config.sourceMiddleware = [
            passthrough,
        ]
        analytics = Analytics(configuration: config)
    }
    
    override func tearDown() {
        super.tearDown()
        analytics.reset()
    }
    
    func testHandlesIdentify() {
        analytics.identify("testUserId1", traits: [
            "firstName": "Peter"
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.identify)
        let identify = passthrough.lastContext?.payload as? IdentifyPayload
        XCTAssertEqual(identify?.userId, "testUserId1")
        XCTAssertNotNil(identify?.anonymousId)
        XCTAssertEqual(identify?.traits?["firstName"] as? String, "Peter")
    }
    
    func testHandlesIdentifyWithCustomAnonymousId() {
        analytics.identify("testUserId1", traits: [
            "firstName": "Peter"
            ], options: [
                "anonymousId": "a_custom_anonymous_id"
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.identify)
        let identify = passthrough.lastContext?.payload as? IdentifyPayload
        XCTAssertEqual(identify?.userId, "testUserId1")
        XCTAssertEqual(identify?.anonymousId, "a_custom_anonymous_id")
        XCTAssertEqual(identify?.traits?["firstName"] as? String, "Peter")
    }
    
    func testHandlesTrack() {
        analytics.track("User Signup", properties: [
            "method": "SSO"
            ], options: [
                "context": [
                    "device": [
                        "token": "1234"
                    ]
                ]
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.track)
        let payload = passthrough.lastContext?.payload as? TrackPayload
        XCTAssertEqual(payload?.event, "User Signup")
        XCTAssertEqual(payload?.properties?["method"] as? String, "SSO")
    }
    
    func testHandlesAlias() {
        analytics.alias("persistentUserId")
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.alias)
        let payload = passthrough.lastContext?.payload as? AliasPayload
        XCTAssertEqual(payload?.theNewId, "persistentUserId")
    }
    
    func testHandlesScreen() {
        analytics.screen("Home", properties: [
            "referrer": "Google"
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.screen)
        let screen = passthrough.lastContext?.payload as? ScreenPayload
        XCTAssertEqual(screen?.name, "Home")
        XCTAssertEqual(screen?.properties?["referrer"] as? String, "Google")
    }
    
    func testHandlesGroup() {
        analytics.group("acme-company", traits: [
            "employees": 2333
        ])
        XCTAssertEqual(passthrough.lastContext?.eventType, EventType.group)
        let payload = passthrough.lastContext?.payload as? GroupPayload
        XCTAssertEqual(payload?.groupId, "acme-company")
        XCTAssertEqual(payload?.traits?["employees"] as? Int, 2333)
    }
    
    func testHandlesNullValues() {
        analytics.track("null test", properties: [
            "nullTest": NSNull()
        ])
        let payload = passthrough.lastContext?.payload as? TrackPayload
        let isNull = (payload?.properties?["nullTest"] is NSNull)
        XCTAssert(isNull)
    }
}
