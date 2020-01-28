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
        
        // let any async operations above complete.
        queue.sync {}
        
        XCTAssertTrue(passthru.lastContext?.eventType == .identify)
        let identify = passthru.lastContext?.payload as! IdentifyPayload
        XCTAssertTrue(identify.userId == "testUserId1")
    }

    func testModifyAndPassToNextMiddleware() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthru = PassthroughSourceMiddleware()
        let customize = CustomizeTrackSourceMiddleware()
        config.sourceMiddleware = [customize, passthru]
        
        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        // let any async operations above complete.
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
        
        let customize = CustomizeTrackSourceMiddleware()
        customize.swallowEvent = true
        
        config.sourceMiddleware = [customize, passthru]

        let analytics = Analytics(configuration: config)
        analytics.track("Purchase Success")
        
        // let any async operations above complete.
        queue.sync {}

        XCTAssertTrue(passthru.lastContext == nil)
    }

    func testTypedMethodCalls() {
        let config = AnalyticsConfiguration(writeKey: "TESTKEY")
        let passthru = PassthroughSourceMiddleware()
        let track = TypedSourceMiddleware()
        config.sourceMiddleware = [track, passthru]
        
        let analytics = Analytics(configuration: config)
        
        analytics.track("TestTrack")
        // let any async operations above complete.
        queue.sync {}
        let trackPayload = passthru.lastContext?.payload as! TrackPayload
        XCTAssertTrue(trackPayload.event == "TestTrack")
        XCTAssertTrue(trackPayload.properties!["trackCalled"] as! Bool == true)
        
        analytics.identify("MyGuy")
        // let any async operations above complete.
        queue.sync {}
        let identifyPayload = passthru.lastContext?.payload as! IdentifyPayload
        XCTAssertTrue(identifyPayload.userId == "MyGuy")
        XCTAssertTrue(identifyPayload.traits!["identifyCalled"] as! Bool == true)
        
        analytics.alias("someId")
        // let any async operations above complete.
        queue.sync {}
        let aliasPayload = passthru.lastContext?.payload as! AliasPayload
        XCTAssertTrue(aliasPayload.theNewId == "transformedId")
        
        analytics.group("myGroup")
        // let any async operations above complete.
        queue.sync {}
        let groupPayload = passthru.lastContext?.payload as! GroupPayload
        XCTAssertTrue(groupPayload.groupId == "myGroup")
        XCTAssertTrue(groupPayload.traits!["groupCalled"] as! Bool == true)

        analytics.screen("someScreen")
        // let any async operations above complete.
        queue.sync {}
        let screenPayload = passthru.lastContext?.payload as! ScreenPayload
        XCTAssertTrue(screenPayload.name == "someScreen")
        XCTAssertTrue(screenPayload.properties!["screenCalled"] as! Bool == true)
        
        let appLifePayloadIn = ApplicationLifecyclePayload(context: ["foo": "bar"], integrations: [:])
        analytics.run(.applicationLifecycle, payload: appLifePayloadIn)
        // let any async operations above complete.
        queue.sync {}
        let appLifePayloadOut = passthru.lastContext?.payload as! ApplicationLifecyclePayload
        XCTAssertTrue(appLifePayloadOut.context["appLifeCalled"] as! Bool == true)

        analytics.open(URL(string: "http://blah.com")!, options: [:])
        // let any async operations above complete.
        queue.sync {}
        let openUrlPayloadOut = passthru.lastContext?.payload as! OpenURLPayload
        XCTAssertTrue(openUrlPayloadOut.context["openUrlCalled"] as! Bool == true)
    }
}
