@testable import Analytics
import XCTest

class EndToEndTests: XCTestCase {
    
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        
        // Write Key for https://app.segment.com/segment-libraries/sources/analytics_ios_e2e_test/overview
        let config = AnalyticsConfiguration(writeKey: "3VxTfPsVOoEOSbbzzbFqVNcYMNu2vjnr")
        config.flushAt = 1

        Analytics.setup(with: config)

        analytics = Analytics.shared()
    }
    
    override func tearDown() {
        super.tearDown()
        
        analytics.reset()
    }
    
    func testTrack() {
        let uuid = UUID().uuidString
        let expectation = XCTestExpectation(description: "SegmentRequestDidSucceed")
        
        Analytics.shared().configuration.experimental.rawSegmentModificationBlock = { data in
            if let properties = data["properties"] as? Dictionary<String, Any?>,
                let tempUUID = properties["id"] as? String, tempUUID == uuid {
                expectation.fulfill()
            }
            return data
        }

        analytics.track("E2E Test", properties: ["id": uuid])
        
        wait(for: [expectation], timeout: 2.0)
    }
}
