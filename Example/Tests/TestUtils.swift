//
//  TestUtils.swift
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

@testable import Nimble
import Nocilla

class JSONGzippedBody : LSMatcher, LSMatcheable {
    
    let expectedJson: AnyObject
    
    init(_ json: AnyObject) {
        self.expectedJson = json
    }
    
    func matchesJson(json: AnyObject) -> Bool {
        let actualValue : () -> NSObject! = {
            return json as! NSObject
        }
        let failureMessage = FailureMessage()
        let location = SourceLocation()
        let matches = Nimble.equal(expectedJson).matches(actualValue, failureMessage: failureMessage, location: location)
        print("matches=\(matches) expected \(expectedJson) actual \(json)")
        return matches
    }
    
    override func matches(string: String!) -> Bool {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
            return matchesJson(json)
        }
        return false
    }
    
    override func matchesData(data: NSData!) -> Bool {
        if let data = data.seg_gunzippedData(),
            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []) {
            return matchesJson(json)
        }
        return false
    }
    
    func matcher() -> LSMatcher! {
        return self
    }
}
