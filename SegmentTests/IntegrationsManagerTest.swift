import Segment
import XCTest
class IntegrationsManagerTest: XCTestCase {
    
    func testValidValueTypesInIntegrationEnablementFlags() {
        let exception = objc_tryCatch {
            IntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": ["blah": 1]])
            IntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": true])
        }
        
        XCTAssertNil(exception)
    }
    
    func testAssertsWhenInvalidValueTypesUsedIntegrationEnablement() {
        let exception = objc_tryCatch {
            IntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": "blah"])
        }
        
        XCTAssertNotNil(exception)
    }
    
    func testAssertsWhenInvalidValueTypesIntegrationEnableFlags() {
        let exception = objc_tryCatch {
            // we don't accept array's as values.
            IntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": ["key", 1]])
        }
        
        XCTAssertNotNil(exception)
    }
    
    func testPullsValidIntegrationDataWhenSupplied() {
        let enabled = IntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": true])
        XCTAssert(enabled)
    }
    
    func testFallsBackCorrectlyWhenNotSpecified() {
        let enabled = IntegrationsManager.isIntegration("comScore", enabledInOptions: ["all": true])
        XCTAssert(enabled)
        let allEnabled = IntegrationsManager.isIntegration("comScore", enabledInOptions: ["All": true])
        XCTAssert(allEnabled)
    }
    
    func testReturnsTrueWhenThereisNoPlan() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Amplitude", inPlan:[:])
        XCTAssert(enabled)
    }
    
    func testReturnsTrueWhenPlanIsEmpty() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":[:]])
        XCTAssert(enabled)
    }
    
    func testReturnsTrueWhenPlanEnablesEvent() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true]]])
        XCTAssert(enabled)
    }
    
    func testReturnsFalseWhenPlanDisablesEvent() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Amplitude", inPlan:["track":["hello world":["enabled":false]]])
        XCTAssertFalse(enabled)
    }
    
    func testReturnsTrueForSegmentIntegrationWhenDisablesEvent() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Segment.io", inPlan:["track":["hello world":["enabled":false]]])
        XCTAssert(enabled)
    }
    
    func testReturnsTrueWhenPlanEnablesEventForIntegration() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true, "integrations":["Mixpanel":true]]]])
        XCTAssert(enabled)
    }
    
    func testReturnsFalseWhenPlanDisablesEventForIntegration() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true, "integrations":["Mixpanel":false]]]])
        XCTAssertFalse(enabled)
    }
    
    func testReturnsFalseWhenPlanDisablesNewEvents() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["__default":["enabled":false]]])
        XCTAssertFalse(enabled)
    }
    
    func testReturnsUsesEventPlanRatherOverDefaults() {
        let enabled = IntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["__default":["enabled":false],"hello world":["enabled":true]]])
        XCTAssert(enabled)
    }
}
