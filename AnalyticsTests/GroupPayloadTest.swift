import Quick
import Nimble
import Analytics

class GroupPayloadTest: QuickSpec {
  override func spec() {
    describe("builder") {
      it("fails for null name") {
        expect { SEGGroupPayload(builder: SEGGroupPayloadBuilder()) }.to(raiseException(reason:"groupId ((null)) must not be null or empty."))
      }
      
      it("fails for empty groupId") {
        let builder = SEGGroupPayloadBuilder()
        builder.groupId = ""
        
        expect { SEGGroupPayload(builder: builder) }.to(raiseException(reason:"groupId () must not be null or empty."))
      }
      
      it("succeeds for valid groupId") {
        let builder = SEGGroupPayloadBuilder()
        builder.groupId = "segment"
        
        let payload = SEGGroupPayload(builder: builder)
        expect(payload.groupId) == "segment"
      }
      
      it("succeeds without traits") {
        let builder = SEGGroupPayloadBuilder()
        builder.groupId = "segment"
        
        let payload = SEGGroupPayload(builder: builder)
        expect(payload.traits).to(beNil())
      }
      
      it("succeeds for valid traits") {
        let builder = SEGGroupPayloadBuilder()
        builder.groupId = "segment"
        builder.traits = ["name" : "Segment.io, Inc."]
        
        let payload = SEGGroupPayload(builder: builder)
        expect((payload.traits as? NSDictionary)) == ["name" : "Segment.io, Inc."] as NSDictionary
      }
    }
  }
}
