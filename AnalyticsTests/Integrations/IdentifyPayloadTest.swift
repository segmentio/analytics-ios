import Quick
import Nimble
import Analytics

class IdentifyPayloadTest: QuickSpec {
  override func spec() {
    describe("builder") {
      it("fails for all null fields") {
        expect { SEGIdentifyPayload(builder: SEGIdentifyPayloadBuilder()) }.to(raiseException(reason:"either userId ((null)), anonymousId ((null)) or traits ((null)) must be provided."))
      }
      
      it("fails for empty userId and anonymousId") {
        let builder = SEGIdentifyPayloadBuilder()
        builder.userId = ""
        builder.anonymousId = ""
        
        expect { SEGIdentifyPayload(builder: builder) }.to(raiseException(reason:"either userId (), anonymousId () or traits ((null)) must be provided."))
      }
      
      it("succeeds for valid userId") {
        let builder = SEGIdentifyPayloadBuilder()
        builder.userId = "prateek"
        
        let payload = SEGIdentifyPayload(builder: builder)
        expect(payload.userId) == "prateek"
        expect(payload.anonymousId).to(beNil())
      }
      
      it("succeeds for valid anonymousId") {
        let builder = SEGIdentifyPayloadBuilder()
        builder.anonymousId = "foo"
        
        let payload = SEGIdentifyPayload(builder: builder)
        expect(payload.userId).to(beNil())
        expect(payload.anonymousId) == "foo"
      }
      
      it("succeeds without traits") {
        let builder = SEGIdentifyPayloadBuilder()
        builder.anonymousId = "foo"
        
        let payload = SEGIdentifyPayload(builder: builder)
        expect(payload.traits).to(beNil())
      }
      
      it("succeeds for valid traits") {
        let builder = SEGIdentifyPayloadBuilder()
        builder.traits = ["age" : 25]
        
        let payload = SEGIdentifyPayload(builder: builder)
        expect(payload.userId).to(beNil())
        expect(payload.anonymousId).to(beNil())
        expect((payload.traits as? NSDictionary)) == ["age" : 25] as NSDictionary
      }
    }
  }
}
