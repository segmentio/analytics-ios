//
//  HTTPClientTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/16/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Mockingjay
import Analytics

class HTTPClientTest: QuickSpec {
  override func spec() {
    
    describe("defaultRequestFactory") { 
      it("preserves url") {
        let factory = SEGHTTPClient.defaultRequestFactory()
        let url = NSURL(string: "https://api.segment.io/v1/batch")
        let request = factory(url)
        expect(request.URL) == url
      }
    }
  }
}
