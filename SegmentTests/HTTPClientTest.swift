//
//  HTTPClientTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//

// TODO: Uncomment these tests and get rid of Nocilla.

/*
import Nocilla
import Analytics
import XCTest

class HTTPClientTest: XCTestCase {
    
    var client: HTTPClient!
    let batch: [String: Any] = ["sentAt":"2016-07-19'T'19:25:06Z", "batch":[["type":"track", "event":"foo"]]]
    let context: [String: Any] = [
        "os": [
            "name": "iPhone OS",
            "version" : "8.1.3",
        ],
        "ip": "8.8.8.8",
    ]
    
    override func setUp() {
        super.setUp()
        LSNocilla.sharedInstance().start()
        client = HTTPClient(requestFactory: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        LSNocilla.sharedInstance().clearStubs()
        LSNocilla.sharedInstance().stop()
    }
    
    func testDefaultRequestFactor() {
        let factory = HTTPClient.defaultRequestFactory()
        let url = URL(string: "https://api.segment.io/v1/batch")
        let request = factory(url!)
        XCTAssertEqual(request.url, url, "URLs should be the same")
    }
    
    func testSettingsForWriteKeySucceeds2xx() {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withHeaders(["Accept-Encoding" : "gzip" ])!
            .andReturn(200)!
            .withHeaders(["Content-Type" : "application/json"])!
            .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}" as NSString)
        
        let doneExpectation = expectation(description: "Done with url session task")
        
        _ = client.settings(forWriteKey: "foo", completionHandler: { success, settings in
            
            XCTAssert(success, "Should be successful")
            XCTAssertEqual(settings as NSDictionary?, [
                "integrations": [
                    "Segment.io": [
                        "apiKey":"foo"
                    ]
                ],
                "plan":[
                    "track": [:]
                ]
                ] as NSDictionary)
            doneExpectation.fulfill()
        })
        
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testSettingsWriteKey2xxResponse() {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withHeaders(["Accept-Encoding" : "gzip" ])!
            .andReturn(400)!
            .withHeaders(["Content-Type" : "application/json" ])!
            .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}" as NSString)
        
        let doneExpectation = expectation(description: "Done with url session task")
        
        client.settings(forWriteKey: "foo", completionHandler: { success, settings in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertNil(settings, "Failure should have nil settings")
            
            doneExpectation.fulfill()
        })
        
        wait(for: [doneExpectation], timeout: 1.0)
        
    }
    
    func testSettingsWriteKey2xxJSONErrorResponse() {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withHeaders(["Accept-Encoding":"gzip"])!
            .andReturn(200)!
            .withHeaders(["Content-Type":"application/json"])!
            .withBody("{\"integrations" as NSString)
        
        let doneExpectation = expectation(description: "Done with url session task")
        
        client.settings(forWriteKey: "foo", completionHandler: { success, settings in
            XCTAssertFalse(success, "Success should be false")
            XCTAssertNil(settings, "Failure should have nil settings")
            doneExpectation.fulfill()
        })
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testUploadNoRetry() {
        let batch: [String: Any] = [
            // Dates cannot be serialized as is so the json serialzation will fail.
            "sentAt": NSDate(),
            "batch": [["type": "track", "event": "foo"]],
        ]
        let doneExpectation = expectation(description: "Done with url session task")
        let task = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssertFalse(retry, "Retry should be false")
            doneExpectation.fulfill()
        }
        XCTAssertNil(task, "Task should be nil")
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testUploadNoRetry2xx() {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withJsonGzippedBody(batch as AnyObject)
            .withWriteKey("bar")
            .andReturn(200)
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssertFalse(retry, "Retry should be false")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testUploadRetry3xx() {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withJsonGzippedBody(batch as AnyObject)
            .withWriteKey("bar")
            .andReturn(304)
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssert(retry, "Retry should be true")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testUploadNoRetry4xx() {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withJsonGzippedBody(batch as AnyObject)
            .withWriteKey("bar")
            .andReturn(401)
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssertFalse(retry, "Retry should be false")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testRetryFor429() {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withJsonGzippedBody(batch as AnyObject)
            .withWriteKey("bar")
            .andReturn(429)
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssert(retry, "Retry should be true")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testRetryFor5xx() {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
            .withHeader("User-Agent", "analytics-ios/" + Analytics.version())!
            .withJsonGzippedBody(batch as AnyObject)
            .withWriteKey("bar")
            .andReturn(504)
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(batch, forWriteKey: "bar") { retry in
            XCTAssert(retry, "Retry should be true")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
    
    func testBatchSizeFailure() {
        let oversizedBatch: [String: Any] = ["sentAt":"2016-07-19'T'19:25:06Z",
                                             "batch": Array(repeating: ["type":"track", "event":"foo"], count: 16000)]
        let doneExpectation = expectation(description: "Done with url session task")
        _ = client.upload(oversizedBatch, forWriteKey: "bar") { retry in
            XCTAssertFalse(retry, "Retry should be false")
            doneExpectation.fulfill()
        }
        wait(for: [doneExpectation], timeout: 1.0)
    }
}
*/

