import Analytics
import Quick
import Nimble
import SwiftTryCatch

class IntegrationsManagerTest: QuickSpec {
  
  override func spec() {
    describe("IntegrationsManager") {
      context("is track event enabled for integration in plan") {
        
        it("valid value types are used in integration enablement flags") {
          var exception: NSException? = nil
          SwiftTryCatch.tryRun({
            SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": ["blah": 1]])
            SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": true])
          }, catchRun: { e in
            exception = e
          }, finallyRun: nil)
          
          expect(exception).to(beNil())
        }
        
        it("asserts when invalid value types are used integration enablement flags") {
          var exception: NSException? = nil
          SwiftTryCatch.tryRun({
            SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": "blah"])
          }, catchRun: { e in
            exception = e
          }, finallyRun: nil)
          
          expect(exception).toNot(beNil())
        }
        
        it("asserts when invalid value types are used integration enablement flags") {
          var exception: NSException? = nil
          SwiftTryCatch.tryRun({
            // we don't accept array's as values.
            SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": ["key", 1]])
          }, catchRun: { e in
            exception = e
          }, finallyRun: nil)
          
          expect(exception).toNot(beNil())
        }
        
        it("pulls valid integration data when supplied") {
          let enabled = SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["comScore": true])
          expect(enabled).to(beTrue())
        }

        it("falls back correctly when values aren't explicitly specified") {
          let enabled = SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["all": true])
          expect(enabled).to(beTrue())
          let allEnabled = SEGIntegrationsManager.isIntegration("comScore", enabledInOptions: ["All": true])
          expect(allEnabled).to(beTrue())
        }

        it("returns true when there is no plan") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Amplitude", inPlan:[:])
          expect(enabled).to(beTrue())
        }
        
        it("returns true when plan is empty") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":[:]])
          expect(enabled).to(beTrue())
        }
        
        it("returns true when plan enables event") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true]]])
          expect(enabled).to(beTrue())
        }
        
        it("returns false when plan disables event") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Amplitude", inPlan:["track":["hello world":["enabled":false]]])
          expect(enabled).to(beFalse())
        }
        
        it("returns true for Segment integration even when plan disables event") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Segment.io", inPlan:["track":["hello world":["enabled":false]]])
          expect(enabled).to(beTrue())
        }
        
        it("returns true when plan enables event for integration") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true, "integrations":["Mixpanel":true]]]])
          expect(enabled).to(beTrue())
        }
        
        it("returns false when plan disables event for integration") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["hello world":["enabled":true, "integrations":["Mixpanel":false]]]])
          expect(enabled).to(beFalse())
        }
        
        it("returns false when plan disables new events by default") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["__default":["enabled":false]]])
          expect(enabled).to(beFalse())
        }
        
        it("returns uses event plan rather over defaults") {
          let enabled = SEGIntegrationsManager.isTrackEvent("hello world", enabledForIntegration: "Mixpanel", inPlan:["track":["__default":["enabled":false],"hello world":["enabled":true]]])
          expect(enabled).to(beTrue())
        }
      }
    }
  }
}
