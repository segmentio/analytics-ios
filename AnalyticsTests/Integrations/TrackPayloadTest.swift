import Quick
import Nimble
import Analytics

class TrackPayloadTest: QuickSpec {
  override func spec() {
    describe("builder") {
      it("fails for null event") {
        expect { SEGTrackPayload(builder: SEGTrackPayloadBuilder()) }.to(raiseException(reason:"event ((null)) must not be null or empty."))
      }
      
      it("fails for empty event") {
        let builder = SEGTrackPayloadBuilder()
        builder.event = ""
        expect { SEGTrackPayload(builder: builder) }.to(raiseException(reason:"event () must not be null or empty."))
      }
      
      it("succeeds for valid event") {
        let builder = SEGTrackPayloadBuilder()
        builder.event = "Completed Order"
        
        let payload = SEGTrackPayload(builder: builder)
        expect(payload.event) == "Completed Order"
      }
      
      it("creates empty properties") {
        let builder = SEGTrackPayloadBuilder()
        builder.event = "Completed Order"
        
        let payload = SEGTrackPayload(builder: builder)
        expect(payload.properties).to(beNil())
      }
      
      it("succeeds for valid properties") {
        let builder = SEGTrackPayloadBuilder()
        builder.event = "Completed Order"
        builder.properties = ["revenue" : 10.99]
        
        let payload = SEGTrackPayload(builder: builder)
        expect((payload.properties as! NSDictionary)) == ["revenue" : 10.99] as NSDictionary
      }
    }
  }
}
