//
//  AnalyticsUtilTests.swift
//  Analytics
//
//  Created by David Fink on 10/18/17.
//  Copyright © 2017 Segment. All rights reserved.
//


import Segment
import XCTest

class AnalyticsUtilTests: XCTestCase {
    
    let filters = [
        "(foo)": "$1-bar"
    ]
    
    func equals(a: Any, b: Any) -> Bool {
        let aData = try! JSONSerialization.data(withJSONObject: a, options: .prettyPrinted) as NSData
        let bData = try! JSONSerialization.data(withJSONObject: b, options: .prettyPrinted)
        
        return aData.isEqual(to: bData)
    }
    
    func testFormatNSDateObjects() {
        let date = Date(timeIntervalSince1970: 0)
        let formattedString = iso8601FormattedString(date)
        XCTAssertEqual(formattedString, "1970-01-01T00:00:00.000Z")
        
        var components = DateComponents()
        components.year = 1992
        components.month = 8
        components.day = 6
        components.hour = 7
        components.minute = 32
        components.second = 4
        components.nanosecond = 335000000
        let calendar = NSCalendar(calendarIdentifier: .gregorian)!
        calendar.timeZone = TimeZone(secondsFromGMT: -4 * 60 * 60)!
        let date2 = calendar.date(from: components)!
        let formattedString2 = iso8601FormattedString(date2)
        XCTAssertEqual(formattedString2, "1992-08-06T11:32:04.335Z")
    }
    
    func testFormatNSDateRFC3339() {
        let date = Date(timeIntervalSince1970: 0)
        let formattedString = iso8601NanoFormattedString(date)
        XCTAssertEqual(formattedString, "1970-01-01T00:00:00.000000000Z")
        
        var components = DateComponents()
        components.year = 1992
        components.month = 8
        components.day = 6
        components.hour = 7
        components.minute = 32
        components.second = 4
        components.nanosecond = 335000008
        let calendar = NSCalendar(calendarIdentifier: .gregorian)!
        calendar.timeZone = TimeZone(secondsFromGMT: -4 * 60 * 60)!
        let date2 = calendar.date(from: components)!
        let formattedString2 = iso8601NanoFormattedString(date2)
        XCTAssertEqual(formattedString2, "1992-08-06T11:32:04.335000008Z")
    }
    
    func testTrimQueueDoesNothingCountLessThan() {
        let queue = NSMutableArray(array: [])
        for i in 1...4 {
            queue.add(i)
        }
        trimQueue(queue, 5)
        XCTAssertEqual(queue, [1, 2, 3, 4])
    }
    
    func testTrimQueueWhenCountGreaterThan() {
        let queue = NSMutableArray(array: [])
        for i in 1...10 {
            queue.add(i)
        }
        trimQueue(queue, 5)
        XCTAssertEqual(queue, [6, 7, 8, 9, 10])
    }
    
    func testTrimQueueWhenCountEqual() {
        let queue = NSMutableArray(array: [])
        for i in 1...5 {
            queue.add(i)
        }
        trimQueue(queue, 5)
        XCTAssertEqual(queue, [1, 2, 3, 4, 5])
    }
    
    func testJSONTraverseWithStrings() {
        XCTAssertEqual(Utilities.traverseJSON("a b foo c", andReplaceWithFilters: filters) as? String, "a b foo-bar c")
    }
    
    func testJSONTraverseRecursively() {
        XCTAssertEqual(Utilities.traverseJSON("a b foo foo c", andReplaceWithFilters: filters) as? String, "a b foo-bar foo-bar c")
    }
    
    func testJSONWorksNestedDictionaries() {
        let data = [
            "foo": [1, nil, "qfoob", ["baz": "foo"]],
            "bar": "foo"
            ] as [String: Any]
        
        guard let input = Utilities.traverseJSON(data, andReplaceWithFilters: filters) as? [String: Any] else {
            XCTFail("Failed to create actual result from traversed JSON replace")
            return
        }
        
        let output = [
            "foo": [1, nil, "qfoo-barb", ["baz": "foo-bar"]],
            "bar": "foo-bar"
            ] as [String: Any]
        
        XCTAssertEqual(NSDictionary(dictionary: output).isEqual(to: input), true)
    }
    
    func testJSONWorksNestedArrays() {
        let data = [
            [1, nil, "qfoob", ["baz": "foo"]],
            "foo"
            ] as [Any]
        let input = Utilities.traverseJSON(data, andReplaceWithFilters: filters)
        let output = [
            [1, nil, "qfoo-barb", ["baz": "foo-bar"]],
            "foo-bar"
            ] as [Any]
        
        XCTAssertEqual(equals(a: input!, b: output), true)
    }
}
