import Quick
import Nimble
import Analytics
import Alamofire
import Alamofire_Synchronous

func hasMatchingId(messageId: String) -> Bool {
  // End to End tests require some private credentials, so we can't embed them in source.
  // On CI, we inject these values with build settings (see Makefile test task).
  let runE2E = ProcessInfo.processInfo.environment["RUN_E2E_TESTS"]

  if runE2E != "true" {
    return true
  }

  guard let auth = ProcessInfo.processInfo.environment["WEBHOOK_AUTH_USERNAME"] else {
    fail("Cannot find webhook username")
    return false
  }

  let base64Token = SEGHTTPClient.authorizationHeader(auth)

  let headers: HTTPHeaders = [
    "Authorization": "Basic \(base64Token)",
  ]

  let response = Alamofire.request("https://webhook-e2e.segment.com/buckets/ios?limit=100", headers: headers).responseJSON()

  // TODO: This should be more strongly typed.
  let messages = response.result.value as! [String]

  for message in messages {
    if (message.contains("\"properties\":{\"id\":\"\(messageId)\"}")) {
      return true
    }
  }

  return false
}

// End to End tests as described in https://paper.dropbox.com/doc/Libraries-End-to-End-Tests-ESEakc3LxFrqcHz69AmyN.
// We connect a webhook destination to a Segment source, send some data to the source using the libray. Then we
// verify that the data was sent to the source by finding it from the Webhook destination.
class AnalyticsE2ETests: QuickSpec {
  override func spec() {
    var analytics: SEGAnalytics!

    beforeEach {
      // Write Key for https://app.segment.com/segment-libraries/sources/analytics_ios_e2e_test/overview
      let config = SEGAnalyticsConfiguration(writeKey: "3VxTfPsVOoEOSbbzzbFqVNcYMNu2vjnr")
      config.flushAt = 1

      SEGAnalytics.setup(with: config)

      analytics = SEGAnalytics.shared()
    }

    afterEach {
      analytics.reset()
    }

    it("track") {
      let uuid = UUID().uuidString
      self.expectation(forNotification: NSNotification.Name("SegmentRequestDidSucceed"), object: nil, handler: nil)

      analytics.track("E2E Test", properties: ["id": uuid])

      self.waitForExpectations(timeout: 20)

      for _ in 1...5 {
        sleep(2)
        if hasMatchingId(messageId: uuid) {
          return
        }
      }

      fail("could not find message with id \(uuid) in Runscope")
    }
  }
}
