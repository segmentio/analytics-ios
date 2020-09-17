//
//  TestUtils.swift
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

// TODO: Uncomment these tests using Nocilla and get rid of Nocilla.

/*
import Nocilla
 */
import Segment
import XCTest

#if os(macOS)
import Cocoa
#else
import UIKit
#endif

class PassthroughMiddleware: Middleware {
    var lastContext: Context?

    func context(_ context: Context, next: @escaping SEGMiddlewareNext) {
        lastContext = context;
        next(context)
    }
}

class TestMiddleware: Middleware {
    var lastContext: Context?
    var swallowEvent = false
    func context(_ context: Context, next: @escaping SEGMiddlewareNext) {
        lastContext = context
        if !swallowEvent {
            next(context)
        }
    }
}

extension Analytics {
    func test_integrationsManager() -> IntegrationsManager? {
        return self.value(forKey: "integrationsManager") as? IntegrationsManager
    }
}

extension IntegrationsManager {
    func test_integrations() -> [String: Integration]? {
        return self.value(forKey: "integrations") as? [String: Integration]
    }
    func test_segmentIntegration() -> SegmentIntegration? {
        return self.test_integrations()?["Segment.io"] as? SegmentIntegration
    }
    func test_setCachedSettings(settings: NSDictionary) {
        self.perform(Selector(("setCachedSettings:")), with: settings)
    }
}

extension SegmentIntegration {
    func test_fileStorage() -> FileStorage? {
        return self.value(forKey: "fileStorage") as? FileStorage
    }
    func test_referrer() -> [String: AnyObject]? {
        return self.value(forKey: "referrer") as? [String: AnyObject]
    }
    func test_userId() -> String? {
        return self.value(forKey: "userId") as? String
    }
    func test_traits() -> [String: AnyObject]? {
        return self.value(forKey: "traits") as? [String: AnyObject]
    }
    func test_flushTimer() -> Timer? {
        return self.value(forKey: "flushTimer") as? Timer
    }
    func test_batchRequest() -> URLSessionUploadTask? {
        return self.value(forKey: "batchRequest") as? URLSessionUploadTask
    }
    func test_queue() -> [AnyObject]? {
        return self.value(forKey: "queue") as? [AnyObject]
    }
    func test_dispatchBackground(block: @escaping @convention(block) () -> Void) {
        self.perform(Selector(("dispatchBackground:")), with: block)
    }
}

/* TODO: Needs Nocilla
class JsonGzippedBody : LSMatcher, LSMatcheable {
    
    let expectedJson: AnyObject
    
    init(_ json: AnyObject) {
        self.expectedJson = json
    }
    
    func matchesJson(_ json: AnyObject) -> Bool {
        let expectedDictionary = expectedJson as? [String: AnyHashable]
        let jsonDictionary = json as? [String: AnyHashable]
        let matches = expectedDictionary == jsonDictionary
//        print("matches=\(matches) expected \(expectedJson) actual \(json)")
        return matches
    }
    
    override func matches(_ string: String!) -> Bool {
        if let data = string.data(using: String.Encoding.utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return matchesJson(json as AnyObject)
        }
        return false
    }
    
    override func matchesData(_ data: Data!) -> Bool {
        if let data = (data as NSData).seg_gunzipped(),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            return matchesJson(json as AnyObject)
        }
        return false
    }
    
    func matcher() -> LSMatcher! {
        return self
    }
    
    func expectedHeaders() -> [String:String] {
        let data = try? JSONSerialization.data(withJSONObject: expectedJson, options: [])
        let contentLength = (data as NSData?)?.seg_gzipped()?.count ?? 0
        return [
            "Content-Encoding": "gzip",
            "Content-Type": "application/json",
            "Content-Length": "\(contentLength)",
            // Accept-Encoding technically doesn't belong here because
            // sending json body doesn't necessarily mean expecting JSON response. But
            // there isn't anywhere else that's suitable and we don't exactly want to copy paste this logic many times over
            // So will leave it here for now.
            "Accept-Encoding": "gzip",
        ]
    }
}

typealias AndJsonGzippedBodyMethod = (AnyObject) -> LSStubRequestDSL

extension LSStubRequestDSL {
    var withJsonGzippedBody: AndJsonGzippedBodyMethod {
        return { json in
            let body = JsonGzippedBody(json)
            return self
                .withHeaders(body.expectedHeaders())!
                .withBody(body)!
        }
    }
}

// MARK: Custom segment extension for dealing with gzipped headers and writeKeys

typealias AndSegmentWriteKeyMethod = (String) -> LSStubRequestDSL

extension LSStubRequestDSL {
    var withWriteKey: AndSegmentWriteKeyMethod {
        return { writeKey in
            let base64Token = HTTPClient.authorizationHeader(writeKey)
            return self.withHeaders([
                "Authorization": "Basic \(base64Token)",
            ])!
        }
    }
}
 */

class TestApplication: NSObject, ApplicationProtocol {
    class BackgroundTask {
        let identifier: Int
        var isEnded = false
    
        init(identifier: Int) {
            self.identifier = identifier
        }
    }

    var backgroundTasks = [BackgroundTask]()
  
    // MARK: - ApplicationProtocol
    #if os(macOS)
    var delegate: NSApplicationDelegate? = nil
    #else
    var delegate: UIApplicationDelegate? = nil
    #endif
    
    func seg_beginBackgroundTask(withName taskName: String?, expirationHandler handler: (() -> Void)? = nil) -> UInt {
        let backgroundTask = BackgroundTask(identifier: (backgroundTasks.map({ $0.identifier }).max() ?? 0) + 1)
        backgroundTasks.append(backgroundTask)
        return UInt(backgroundTask.identifier)
    }
  
    func seg_endBackgroundTask(_ identifier: UInt) {
        guard let index = backgroundTasks.firstIndex(where: { $0.identifier == identifier }) else { return }
        backgroundTasks[index].isEnded = true
    }
}

extension XCTestCase {
    
    func expectUntil(_ time: TimeInterval, expression: @escaping @autoclosure () throws -> Bool) {
        let expectation = self.expectation(description: "Expect Until")
        DispatchQueue.global().async {
            while (true) {
                if try! expression() {
                    expectation.fulfill()
                    return
                }
                usleep(500) // try every half second
            }
        }
        wait(for: [expectation], timeout: time)
    }
}

