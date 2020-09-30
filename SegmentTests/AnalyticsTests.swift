//
//  AnalyticsTests.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//


@testable import Segment
import XCTest

class AnalyticsTests: XCTestCase {
    
    let config = AnalyticsConfiguration(writeKey: "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
    let cachedSettings = [
        "integrations": [
            "Segment.io": ["apiKey": "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"]
        ],
        "plan": ["track": [:]],
        ] as NSDictionary
    var analytics: Analytics!
    var testMiddleware: TestMiddleware!
    var testApplication: TestApplication!
    
    override func setUp() {
        super.setUp()
        testMiddleware = TestMiddleware()
        config.sourceMiddleware = [testMiddleware]
        testApplication = TestApplication()
        config.application = testApplication
        config.trackApplicationLifecycleEvents = true
        
        UserDefaults.standard.set("test SEGQueue should be removed", forKey: "SEGQueue")
        // pump the run loop so we can be sure the value was written.
        RunLoop.current.run(until: Date.distantPast)
        XCTAssertNotNil(UserDefaults.standard.string(forKey: "SEGQueue"))

        analytics = Analytics(configuration: config)
        analytics.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
    }
    
    override func tearDown() {
        super.tearDown()
        analytics.reset()
    }
    
    func testInitializedCorrectly() {
        XCTAssertEqual(config.flushAt, 20)
        XCTAssertEqual(config.flushInterval, 30)
        XCTAssertEqual(config.maxQueueSize, 1000)
        XCTAssertEqual(config.writeKey, "QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE")
        XCTAssertEqual(config.shouldUseLocationServices, false)
        XCTAssertEqual(config.enableAdvertisingTracking, true)
        XCTAssertEqual(config.shouldUseBluetooth,  false)
        XCTAssertNil(config.httpSessionDelegate)
        XCTAssertNotNil(analytics.getAnonymousId())
    }

    func testWebhookIntegrationInitializedCorrectly() {
        let webhookIntegration = WebhookIntegrationFactory.init(name: "dest1", webhookUrl: "blah")
        let webhookIntegrationKey = webhookIntegration.key()
        var initialized = false
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: SEGAnalyticsIntegrationDidStart), object: nil, queue: nil) { (notification) in
            let key = notification.object as? String
            if (key == webhookIntegrationKey) {
                initialized = true
            }
        }
        let config2 = AnalyticsConfiguration(writeKey: "TESTKEY")
        config2.use(webhookIntegration)
        let analytics2 = Analytics(configuration: config2)
        let factoryList = (config2.value(forKey: "factories") as? NSMutableArray)
        XCTAssertEqual(factoryList?.count, 1)

        while (!initialized) { // wait for WebhookIntegration to get setup
            sleep(1)
        }
        XCTAssertNotNil(analytics2.test_integrationsManager()?.test_integrations()?[webhookIntegrationKey])
    }
    
    func testClearsSEGQueueFromUserDefaults() {
        expectUntil(2.0, expression: UserDefaults.standard.string(forKey: "SEGQueue") == nil)
    }
    
    /* TODO: Fix me when the Context object isn't so wild.
     func testCollectsIDFA() {
     testMiddleware.swallowEvent = true
     analytics.configuration.enableAdvertisingTracking = true
     analytics.configuration.adSupportBlock = { () -> String in
     return "1234AdsNoMore!"
     }
     
     analytics.track("test");
     
     let event = testMiddleware.lastContext?.payload as? TrackPayload
     XCTAssertEqual(event?.properties?["url"] as? String, "myapp://auth?token=((redacted/my-auth))&other=stuff")
     }*/
    
    func testPersistsAnonymousId() {
        let analytics2 = Analytics(configuration: config)
        XCTAssertEqual(analytics.getAnonymousId(), analytics2.getAnonymousId())
    }
    
    func testPersistsUserId() {
        analytics.identify("testUserId1")
        
        let analytics2 = Analytics(configuration: config)
        analytics2.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
        
        XCTAssertEqual(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId(), "testUserId1")
        XCTAssertEqual(analytics2.test_integrationsManager()?.test_segmentIntegration()?.test_userId(), "testUserId1")
    }
    
    func testPersistsTraits() {
        analytics.identify("testUserId1", traits: ["trait1": "someTrait"])
        
        let analytics2 = Analytics(configuration: config)
        analytics2.test_integrationsManager()?.test_setCachedSettings(settings: cachedSettings)
        
        XCTAssertEqual(analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId(), "testUserId1")
        XCTAssertEqual(analytics2.test_integrationsManager()?.test_segmentIntegration()?.test_userId(), "testUserId1")
        
        var traits = analytics.test_integrationsManager()?.test_segmentIntegration()?.test_traits()
        var storedTraits = analytics2.test_integrationsManager()?.test_segmentIntegration()?.test_traits()
        
        if let trait1 = traits?["trait1"] as? String {
            XCTAssertEqual(trait1, "someTrait")
        } else {
            XCTAssert(false, "Traits are nil!")
        }
        
        if let storedTrait1 = storedTraits?["trait1"] as? String {
            XCTAssertEqual(storedTrait1, "someTrait")
        } else {
            XCTAssert(false, "Traits were not stored!")
        }
        
        analytics.identify("testUserId1", traits: ["trait2": "someOtherTrait"])
        
        traits = analytics.test_integrationsManager()?.test_segmentIntegration()?.test_traits()
        storedTraits = analytics2.test_integrationsManager()?.test_segmentIntegration()?.test_traits()
        
        if let trait1 = traits?["trait2"] as? String {
            XCTAssertEqual(trait1, "someOtherTrait")
        } else {
            XCTAssert(false, "Traits are nil!")
        }
        
        if let storedTrait1 = storedTraits?["trait2"] as? String {
            XCTAssertEqual(storedTrait1, "someOtherTrait")
        } else {
            XCTAssert(false, "Traits were not stored!")
        }
        

    }
    
    func testClearsUserData() {
        analytics.identify("testUserId1", traits: [ "Test trait key" : "Test trait value"])
        analytics.reset()
        
        expectUntil(2.0, expression: self.analytics.test_integrationsManager()?.test_segmentIntegration()?.test_userId() == nil)
        
        expectUntil(2.0, expression: self.analytics.test_integrationsManager()?.test_segmentIntegration()?.test_traits()?.count == 0)
    }
    
    #if os(iOS)
    func testFiresApplicationOpenedForAppLaunchingEvent() {
        testMiddleware.swallowEvent = true
        NotificationCenter.default.post(name: UIApplication.didFinishLaunchingNotification, object: testApplication, userInfo: [
            UIApplication.LaunchOptionsKey.sourceApplication: "testApp",
            UIApplication.LaunchOptionsKey.url: "test://test",
        ])
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Application Opened")
        XCTAssertEqual(event?.properties?["from_background"] as? Bool, false)
        XCTAssertEqual(event?.properties?["referring_application"] as? String, "testApp")
        XCTAssertEqual(event?.properties?["url"] as? String, "test://test")
    }
    #else
    #endif
    
    func testFiresApplicationEnterForeground() {
        testMiddleware.swallowEvent = true
        #if os(macOS)
        NotificationCenter.default.post(name: NSApplication.willBecomeActiveNotification, object: testApplication)
        #else
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: testApplication)
        #endif
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Application Opened")
        XCTAssertEqual(event?.properties?["from_background"] as? Bool, true)
    }
    
    func testFiresApplicationDuringEnterBackground() {
        testMiddleware.swallowEvent = true
        #if os(macOS)
        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: testApplication)
        #else
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: testApplication)
        #endif
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Application Backgrounded")
    }
    
    func testFlushesWhenApplicationBackgroundIsFired() {
        analytics.track("test")
        #if os(macOS)
        NotificationCenter.default.post(name: NSApplication.didResignActiveNotification, object: testApplication)
        #else
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: testApplication)
        #endif
        
        expectUntil(2.0, expression: self.testApplication.backgroundTasks.count == 1)
        expectUntil(2.0, expression: self.testApplication.backgroundTasks[0].isEnded == false)
    }
    
    func testRespectsMaxQueueSize() {
        let max = 72
        config.maxQueueSize = UInt(max)
        
        for i in 1...max * 2 {
            analytics.track("test #\(i)")
        }
        
        let integration = analytics.test_integrationsManager()?.test_segmentIntegration()
        XCTAssertNotNil(integration)
        
        analytics.flush()
        let currentTime = Date()
        while(integration?.test_queue()?.count != max && currentTime < currentTime + 60) {
            sleep(1)
        }
    }
    
    #if !os(macOS)
    func testProtocolConformanceShouldNotInterfere() {
        // In Xcode8/iOS10, UIApplication.h typedefs UIBackgroundTaskIdentifier as NSUInteger,
        // whereas Swift has UIBackgroundTaskIdentifier typealiaed to Int.
        // This is likely due to a custom Swift mapping for UIApplication which got out of sync.
        // If we extract the exact UIApplication method names in SEGApplicationProtocol,
        // it will cause a type mismatch between the return value from beginBackgroundTask
        // and the argument for endBackgroundTask.
        // This would impact all code in a project that imports the Segment framework.
        // Note that this doesn't appear to be an issue any longer in Xcode9b3.
        let task = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        UIApplication.shared.endBackgroundTask(task)
    }
    #endif
    
    func testFlushesUsingFlushTimer() {
        let integration = analytics.test_integrationsManager()?.test_segmentIntegration()
        
        analytics.track("test")
        
        expectUntil(2.0, expression: integration?.test_flushTimer() != nil)
        XCTAssertNil(integration?.test_batchRequest())
        
        integration?.test_flushTimer()?.fire()
        expectUntil(2.0, expression: integration?.test_batchRequest() != nil)
    }
    
    func testRespectsFlushIntervale() {
        let timer = analytics
            .test_integrationsManager()?
            .test_segmentIntegration()?
            .test_flushTimer()
        
        XCTAssertNotNil(timer)
        XCTAssertEqual(timer?.timeInterval, config.flushInterval)
    }
    
    func testRedactsSensibleURLsFromDeepLinksTracking() {
        testMiddleware.swallowEvent = true
        config.trackDeepLinks = true
        analytics.open(URL(string: "fb123456789://authorize#access_token=hastoberedacted")!, options: [:])
        
        
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Deep Link Opened")
        XCTAssertEqual(event?.properties?["url"] as? String, "fb123456789://authorize#access_token=((redacted/fb-auth-token))")
    }
    
    func testRedactsSensibleURLsFromDeepLinksWithFilters() {
        testMiddleware.swallowEvent = true
        config.payloadFilters["(myapp://auth\\?token=)([^&]+)"] = "$1((redacted/my-auth))"
        config.trackDeepLinks = true
        analytics.open(URL(string: "myapp://auth?token=hastoberedacted&other=stuff")!, options: [:])
        
        
        let event = testMiddleware.lastContext?.payload as? TrackPayload
        XCTAssertEqual(event?.event, "Deep Link Opened")
        XCTAssertEqual(event?.properties?["url"] as? String, "myapp://auth?token=((redacted/my-auth))&other=stuff")
    }
    
    func testDefaultsSEGQueueToEmptyArray() {
        let integration = analytics.test_integrationsManager()?.test_segmentIntegration()
        XCTAssertNotNil(integration)
        integration?.test_fileStorage()?.resetAll()
        XCTAssert(integration?.test_queue()?.isEmpty ?? false)
    }
    
    func testDeviceTokenRegistration() {
        func getStringFrom(token: Data) -> String {
            return token.reduce("") { $0 + String(format: "%02.2hhx", $1) }
        }
        
        let deviceToken = GenerateUUIDString()
        let data = deviceToken.data(using: .utf8)
        if let data = data {
            analytics.registeredForRemoteNotifications(withDeviceToken: data)
            let deviceTokenString = getStringFrom(token: data)
            XCTAssertTrue(deviceTokenString == analytics.getDeviceToken())

        } else {
            XCTAssertNotNil(data)
        }
    }
}
