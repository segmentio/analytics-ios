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
    
    beforeSuite { 
      LSNocilla.sharedInstance().start()
    }
    beforeEach {
      client = SEGHTTPClient(requestFactory: nil)
    }
    afterEach { 
      LSNocilla.sharedInstance().clearStubs()
    }
    afterSuite { 
      LSNocilla.sharedInstance().stop()
    }

    
    describe("defaultRequestFactory") { 
      it("preserves url") {
        let factory = SEGHTTPClient.defaultRequestFactory()
        let url = NSURL(string: "https://api.segment.io/v1/batch")
        let request = factory(url)
        expect(request.URL) == url
      }
    }
    
    describe("settingsForWriteKey") { 
      it("succeeds for 2xx response") {
        stubRequest("GET", "https://cdn.segment.com/v1/projects/foo/settings")
          .withHeaders(["Accept-Encoding" : "gzip" ])
          .andReturn(200)
          .withHeaders(["Content-Type" : "application/json"])
          .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}")

        var done = false
        let task = client.settingsForWriteKey("foo", completionHandler: { success, settings in
          expect(success) == true
          expect(settings) == [
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
        expect(task.state).toEventually(equal(NSURLSessionTaskState.Completed))
        expect(done).toEventually(beTrue())
      }
      
      it("fails for non 2xx response") {
        stubRequest("GET", "https://cdn.segment.com/v1/projects/foo/settings")
          .withHeaders(["Accept-Encoding" : "gzip" ])
          .andReturn(400)
          .withHeaders(["Content-Type" : "application/json" ])
          .withBody("{\"integrations\":{\"Segment.io\":{\"apiKey\":\"foo\"}},\"plan\":{\"track\":{}}}")
        var done = false
        client.settingsForWriteKey("foo", completionHandler: { success, settings in
          expect(success) == false
          expect(settings).to(beNil())
          done = true
        })
        expect(done).toEventually(beTrue())
      }
      
      it("fails for json error") {
        stubRequest("GET", "https://cdn.segment.com/v1/projects/foo/settings")
          .withHeaders(["Accept-Encoding":"gzip"])
          .andReturn(200)
          .withHeaders(["Content-Type":"application/json"])
          .withBody("{\"integrations")

        var done = false
        client.settingsForWriteKey("foo", completionHandler: { success, settings in
          expect(success) == false
          expect(settings).to(beNil())
          done = true
        })
        expect(done).toEventually(beTrue())
      }
    }
    
    describe("upload") { 
      it("does not ask to retry for json error") {
        let batch = [
          // Dates cannot be serialized as is so the json serialzation will fail.
          "sentAt": NSDate(),
          "batch": [["type": "track", "event": "foo"]],
        ]
        var done = false
        let task = client.upload(batch, forWriteKey: "bar", completionHandler: { retry in
          expect(retry) == false
          done = true
        })
        expect(task).to(beNil())
        expect(done).toEventually(beTrue())
      }
    }
  }
}
