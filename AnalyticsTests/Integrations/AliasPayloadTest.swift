import Quick
import Nimble
import Analytics

class AliasPayloadTest: QuickSpec {
  override func spec() {
    describe("builder") {
      it("fails for null newId") {
        expect { SEGAliasPayload(builder: SEGAliasPayloadBuilder()) }.to(raiseException(reason:"newId ((null)) must not be null or empty."))
      }
      
      it("fails for empty newId") {
        let builder = SEGAliasPayloadBuilder()
        builder.theNewId = ""
        
        expect { SEGAliasPayload(builder: builder) }.to(raiseException(reason:"newId () must not be null or empty."))
      }
      
      it("succeeds for valid new id") {
        let builder = SEGAliasPayloadBuilder()
        builder.theNewId = "prateek2"
        
        let payload = SEGAliasPayload(builder: builder)
        expect(payload.theNewId) == "prateek2"
      }
    }
  }
}
