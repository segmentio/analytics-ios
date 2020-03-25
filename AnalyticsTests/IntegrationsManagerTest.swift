import Analytics
import Quick
import Nimble

class IntegrationsManagerTest: QuickSpec {
  
  override func spec() {
    describe("IntegrationsManager") {
      context("is track event enabled for integration in plan") {
        
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
