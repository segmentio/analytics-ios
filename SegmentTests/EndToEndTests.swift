@testable import Analytics
import XCTest

class EndToEndTests: XCTestCase {
    
    var analytics: Analytics!
    var configuration: AnalyticsConfiguration!
    
    override func setUp() {
        super.setUp()
        
        // Write Key for https://app.segment.com/segment-libraries/sources/analytics_ios_e2e_test/overview
        configuration = AnalyticsConfiguration(writeKey: "3VxTfPsVOoEOSbbzzbFqVNcYMNu2vjnr")
        configuration.flushAt = 1

        Analytics.setup(with: configuration)

        analytics = Analytics.shared()
    }
    
    override func tearDown() {
        super.tearDown()
        
        analytics.reset()
    }
    
    func testTrack() {
        let uuid = UUID().uuidString
        let expectation = XCTestExpectation(description: "SegmentRequestDidSucceed")
        
        configuration.experimental.rawSegmentModificationBlock = { data in
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
