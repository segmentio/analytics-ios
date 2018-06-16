//
//  HTTPClientTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Nocilla
import Analytics

class HTTPClientTest: QuickSpec {
  override func spec() {

    var client: SEGHTTPClient!

    beforeEach {
      LSNocilla.sharedInstance().start()
      client = SEGHTTPClient(requestFactory: nil)
    }
    afterEach {
      LSNocilla.sharedInstance().clearStubs()
      LSNocilla.sharedInstance().stop()
    }

    describe("defaultRequestFactory") {
      it("preserves url") {
        let factory = SEGHTTPClient.defaultRequestFactory()
        let url = URL(string: "https://api.segment.io/v1/batch")
        let request = factory(url!)
        expect(request.url) == url
      }
    }

    describe("settingsForWriteKey") {
      it("succeeds for 2xx response") {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withHeaders(["Accept-Encoding" : "gzip" ])!
          .andReturn(200)!
          .withHeaders(["Content-Type" : "application/json"])!
          .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}" as NSString)

        var done = false
        let task = client.settings(forWriteKey: "foo", completionHandler: { success, settings in
          expect(success) == true
          expect(settings as NSDictionary?) == [
            "integrations": [
              "Segment.io": [
                "apiKey":"foo"
              ]
            ],
            "plan":[
              "track": [:]
            ]
          ] as NSDictionary
          done = true
        })
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
        expect(done).toEventually(beTrue())
      }

      it("fails for non 2xx response") {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withHeaders(["Accept-Encoding" : "gzip" ])!
          .andReturn(400)!
          .withHeaders(["Content-Type" : "application/json" ])!
          .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}" as NSString)
        var done = false
        client.settings(forWriteKey: "foo", completionHandler: { success, settings in
          expect(success) == false
          expect(settings).to(beNil())
          done = true
        })
        expect(done).toEventually(beTrue())
      }

      it("fails for json error") {
        _ = stubRequest("GET", "https://cdn-settings.segment.com/v1/projects/foo/settings" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withHeaders(["Accept-Encoding":"gzip"])!
          .andReturn(200)!
          .withHeaders(["Content-Type":"application/json"])!
          .withBody("{\"integrations" as NSString)

        var done = false
        client.settings(forWriteKey: "foo", completionHandler: { success, settings in
          expect(success) == false
          expect(settings).to(beNil())
          done = true
        })
        expect(done).toEventually(beTrue())
      }
    }

    describe("upload") {
      it("does not ask to retry for json error") {
        let batch: [String: Any] = [
          // Dates cannot be serialized as is so the json serialzation will fail.
          "sentAt": NSDate(),
          "batch": [["type": "track", "event": "foo"]],
        ]
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == false
          done = true
        }
        expect(task).to(beNil())
        expect(done).toEventually(beTrue())
      }

      let batch: [String: Any] = ["sentAt":"2016-07-19'T'19:25:06Z", "batch":[["type":"track", "event":"foo"]]]


      it("does not ask to retry for 2xx response") {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withJsonGzippedBody(batch as AnyObject)
          .withWriteKey("bar")
          .andReturn(200)
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == false
          done = true
        }
        expect(done).toEventually(beTrue())
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
      }

      it("asks to retry for 3xx response") {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withJsonGzippedBody(batch as AnyObject)
          .withWriteKey("bar")
          .andReturn(304)
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == true
          done = true
        }
        expect(done).toEventually(beTrue())
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
      }

      it("does not ask to retry for 4xx response") {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withJsonGzippedBody(batch as AnyObject)
          .withWriteKey("bar")
          .andReturn(401)
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == false
          done = true
        }
        expect(done).toEventually(beTrue())
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
      }

      it("asks to retry for 429 response") {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withJsonGzippedBody(batch as AnyObject)
          .withWriteKey("bar")
          .andReturn(429)
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == true
          done = true
        }
        expect(done).toEventually(beTrue())
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
      }

      it("asks to retry for 5xx response") {
        _ = stubRequest("POST", "https://api.segment.io/v1/batch" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withJsonGzippedBody(batch as AnyObject)
          .withWriteKey("bar")
          .andReturn(504)
        var done = false
        let task = client.upload(batch, forWriteKey: "bar") { retry in
          expect(retry) == true
          done = true
        }
        expect(done).toEventually(beTrue())
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
      }
    }

    describe("attribution") {
      it("fails for json error") {
        let device = [
          // Dates cannot be serialized as is so the json serialzation will fail.
          "sentAt": NSDate(),
        ]
        var done = false
        let task = client.attribution(withWriteKey: "bar", forDevice: device) { success, properties in
          expect(success) == false
          done = true
        }
        expect(task).to(beNil())
        expect(done).toEventually(beTrue())
      }

      let context: [String: Any] = [
        "os": [
          "name": "iPhone OS",
          "version" : "8.1.3",
        ],
        "ip": "8.8.8.8",
      ]

      it("succeeds for 2xx response") {
        _ = stubRequest("POST", "https://mobile-service.segment.com/v1/attribution" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withWriteKey("foo")
          .andReturn(200)!
          .withBody("{\"provider\": \"mock\"}" as NSString)

        var done = false
        let task = client.attribution(withWriteKey: "foo", forDevice: context) { success, properties in
          expect(success) == true
          expect(properties as? [String: String]) == [
            "provider": "mock"
          ]
          done = true
        }
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
        expect(done).toEventually(beTrue())
      }

      it("fails for non 2xx response") {
        _ = stubRequest("POST", "https://mobile-service.segment.com/v1/attribution" as NSString)
          .withHeader("User-Agent", "analytics-ios/" + SEGAnalytics.version())!
          .withWriteKey("foo")
          .andReturn(404)!
          .withBody("not found" as NSString)
        var done = false
        let task = client.attribution(withWriteKey: "foo", forDevice: context) { success, properties in
          expect(success) == false
          expect(properties).to(beNil())
          done = true
        }
        expect(task.state).toEventually(equal(URLSessionTask.State.completed))
        expect(done).toEventually(beTrue())
      }
    }
  }
}
