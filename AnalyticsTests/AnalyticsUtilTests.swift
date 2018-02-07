//
//  AnalyticsUtilTests.swift
//  Analytics
//
//  Created by David Fink on 10/18/17.
//  Copyright © 2017 Segment. All rights reserved.
//


import Quick
import Nimble
import Analytics

class AnalyticsUtilTests: QuickSpec {
  override func spec() {

    it("format NSDate objects to RFC 3339 complaint string") {
      let date = Date(timeIntervalSince1970: 0)
      let formattedString = iso8601FormattedString(date)
      expect(formattedString) == "1970-01-01T00:00:00.000Z"

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
      expect(formattedString2) == "1992-08-06T11:32:04.335Z"
    }

    describe("trimQueue", {
      it("does nothing when count < max") {
        let queue = NSMutableArray(array: [])
        for i in 1...4 {
          queue.add(i)
        }
        trimQueue(queue, 5)
        expect(queue) == [1, 2, 3, 4]
      }

      it("trims when count > max") {
        let queue = NSMutableArray(array: [])
        for i in 1...10 {
          queue.add(i)
        }
        trimQueue(queue, 5)
        expect(queue) == [6, 7, 8, 9, 10]
      }

      it("does not trim when count == max") {
        let queue = NSMutableArray(array: [])
        for i in 1...5 {
          queue.add(i)
        }
        trimQueue(queue, 5)
        expect(queue) == [1, 2, 3, 4, 5]
      }
    })
  }
}
