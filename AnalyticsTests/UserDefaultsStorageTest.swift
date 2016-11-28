//
//  UserDefaultsStorageTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

class UserDefaultsStorageTest : QuickSpec {
  override func spec() {
    var storage : SEGUserDefaultsStorage!
    beforeEach {
//      let crypto = SEGAES256Crypto(password: "thetrees")
//      storage = SEGUserDefaultsStorage(defaults: NSUserDefaults.standardUserDefaults(), namespacePrefix: "segment", crypto: crypto)
//      storage = SEGUserDefaultsStorage(defaults: NSUserDefaults.standardUserDefaults(), namespacePrefix: nil, crypto: crypto)
      storage = SEGUserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: nil, crypto: nil)
    }
    
    it("persists and loads data") {
      let dataIn = "segment".data(using: String.Encoding.utf8)!
      storage.setData(dataIn, forKey: "mydata")
      
      let dataOut = storage.data(forKey: "mydata")
      expect(dataOut) == dataIn
      
      let strOut = String(data: dataOut!, encoding: .utf8)
      expect(strOut) == "segment"
    }
    
    it("persists and loads string") {
      let str = "san francisco"
      storage.setString(str, forKey: "city")
      expect(storage.string(forKey: "city")) == str
      
      storage.removeKey("city")
      expect(storage.string(forKey: "city")).to(beNil())
    }
    
    it("persists and loads array") {
      let array = [
        "san francisco",
        "new york",
        "tallinn",
      ]
      storage.setArray(array, forKey: "cities")
      expect(storage.array(forKey: "cities") as? Array<String>) == array
      
      storage.removeKey("cities")
      expect(storage.array(forKey: "cities")).to(beNil())
    }
    
    it("persists and loads dictionary") {
      let dict = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      storage.setDictionary(dict, forKey: "cityMap")
      expect(storage.dictionary(forKey: "cityMap") as? Dictionary<String, String>) == dict
      
      storage.removeKey("cityMap")
      expect(storage.dictionary(forKey: "cityMap")).to(beNil())
    }
    
    it("should work with crypto") {
      let crypto = SEGAES256Crypto(password: "thetrees")
      let s = SEGUserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: nil, crypto: crypto)
      let dict = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      s.setDictionary(dict, forKey: "cityMap")
      expect(s.dictionary(forKey: "cityMap") as? Dictionary<String, String>) == dict
      
      s.removeKey("cityMap")
      expect(s.dictionary(forKey: "cityMap")).to(beNil())
    }
    
    
    it("should work with namespace") {
      let crypto = SEGAES256Crypto(password: "thetrees")
      let s = SEGUserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: "segment", crypto: crypto)
      let dict = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      s.setDictionary(dict, forKey: "cityMap")
      expect(s.dictionary(forKey: "cityMap") as? Dictionary<String, String>) == dict
      
      s.removeKey("cityMap")
      expect(s.dictionary(forKey: "cityMap")).to(beNil())
    }
    
    afterEach {
      storage.resetAll()
    }
  }
}
