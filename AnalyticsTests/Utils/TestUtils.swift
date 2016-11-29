//
//  TestUtils.swift
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

@testable import Nimble
import Nocilla
import Analytics

class JsonGzippedBody : LSMatcher, LSMatcheable {
    
    let expectedJson: AnyObject
    
    init(_ json: AnyObject) {
        self.expectedJson = json
    }
    
    func matchesJson(_ json: AnyObject) -> Bool {
        let actualValue : () -> NSObject! = {
            return json as! NSObject
        }
        let failureMessage = FailureMessage()
        let location = SourceLocation()
        let matches = Nimble.equal(expectedJson).matches(actualValue, failureMessage: failureMessage, location: location)
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
            let base64Token = SEGHTTPClient.authorizationHeader(writeKey)
            return self.withHeaders([
                "Authorization": "Basic \(base64Token)",
            ])!
        }
    }
}
