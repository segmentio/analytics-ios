import Quick
import Nimble
import Analytics

class ScreenPayloadTest: QuickSpec {
  override func spec() {
    describe("builder") {
      it("fails for null name") {
        expect { SEGScreenPayload(builder: SEGScreenPayloadBuilder()) }.to(raiseException(reason:"name ((null)) must not be null or empty."))
      }
      
      it("fails for empty name") {
        let builder = SEGScreenPayloadBuilder()
        builder.name = ""
        expect { SEGScreenPayload(builder: builder) }.to(raiseException(reason:"name () must not be null or empty."))
      }
      
      it("succeeds for valid name") {
        let builder = SEGScreenPayloadBuilder()
        builder.name = "Home"
        
        let payload = SEGScreenPayload(builder: builder)
        expect(payload.name) == "Home"
      }
      
      it("creates empty properties") {
        let builder = SEGScreenPayloadBuilder()
        builder.name = "Home"
      
        let payload = SEGScreenPayload(builder: builder)
        expect(payload.properties).to(beNil())
      }
      
      it("succeeds for valid properties") {
        let builder = SEGScreenPayloadBuilder()
        builder.name = "Products"
        builder.properties = ["category" : "Sports"]
        
        let payload = SEGScreenPayload(builder: builder)
        expect((payload.properties as? NSDictionary)) == ["category" : "Sports"] as NSDictionary
      }
    }
  }
}
