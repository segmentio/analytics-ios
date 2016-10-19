//
//  CryptoTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

class CryptoTest : QuickSpec {
  override func spec() {
    var crypto : SEGAES256Crypto!
    beforeEach {
      crypto = SEGAES256Crypto(password: "slothysloth")
    }
    
    it("encrypts and decrypts data") {
      let strIn = "segment"
      let dataIn = strIn.data(using: String.Encoding.utf8)!
      let encryptedData = crypto.encrypt(dataIn)
      expect(encryptedData).toNot(beNil())
      
      let dataOut = crypto.decrypt(encryptedData!)
      expect(dataOut) == dataIn
      
      let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
      expect(strOut) == "segment"
    }
    
    it("fails for incorrect password") {
      let strIn = "segment"
      let dataIn = strIn.data(using: String.Encoding.utf8)!
      let encryptedData = crypto.encrypt(dataIn)
      expect(encryptedData).toNot(beNil())
      
      let crypto2 = SEGAES256Crypto(password: "wolf", salt: crypto.salt, iv: crypto.iv)
      let dataOut = crypto2.decrypt(encryptedData!)
      expect(dataOut) != dataIn
      let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
      // no built in way to check password correctness
      // http://stackoverflow.com/questions/27712173/determine-if-key-is-incorrect-with-cccrypt-kccoptionpkcs7padding-objective-c
      expect(strOut ?? "") != strIn
    }
    
    it("fails for incorrect iv and sault") {
      let strIn = "segment"
      let dataIn = strIn.data(using: String.Encoding.utf8)!
      let encryptedData = crypto.encrypt(dataIn)
      expect(encryptedData).toNot(beNil())
      
      let crypto2 = SEGAES256Crypto(password: crypto.password)
      let dataOut = crypto2.decrypt(encryptedData!)
      expect(dataOut) != dataIn
      
      let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
      expect(strOut ?? "") != strIn
    }
  }
}
