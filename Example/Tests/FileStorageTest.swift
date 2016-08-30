//
//  FileStorageTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

class FileStorageTest : QuickSpec {
  override func spec() {
    var storage : SEGFileStorage!
    beforeEach {
      let url = SEGFileStorage.applicationSupportDirectoryURL()
      expect(url).toNot(beNil())
      expect(url?.lastPathComponent) == "Application Support"
      storage = SEGFileStorage(folder: url!, crypto: nil)
    }
    
    it("creates folder if none exists") {
      let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
      let url = tempDir.URLByAppendingPathComponent(NSUUID().UUIDString)
      expect(url.checkResourceIsReachableAndReturnError(nil)) == false
      _ = SEGFileStorage(folder: url, crypto: nil)
      
      var isDir: ObjCBool = false
      let exists = NSFileManager.defaultManager().fileExistsAtPath(url.path!, isDirectory: &isDir)
      
      expect(exists) == true
      expect(Bool(isDir)) == true
    }
    
    it("persists and loads data") {
      let dataIn = "segment".dataUsingEncoding(NSUTF8StringEncoding)!
      storage.setData(dataIn, forKey: "mydata")
      
      let dataOut = storage.dataForKey("mydata")
      expect(dataOut) == dataIn
      
      let strOut = String(data: dataOut!, encoding: NSUTF8StringEncoding)
      expect(strOut) == "segment"
    }
    
    it("persists and loads string") {
      let str = "san francisco"
      storage.setString(str, forKey: "city")
      expect(storage.stringForKey("city")) == str
      
      storage.removeKey("city")
      expect(storage.stringForKey("city")).to(beNil())
    }
    
    it("persists and loads array") {
      let array = [
        "san francisco",
        "new york",
        "tallinn",
      ]
      storage.setArray(array, forKey: "cities")
      expect(storage.arrayForKey("cities") as? Array<String>) == array
      
      storage.removeKey("cities")
      expect(storage.arrayForKey("cities")).to(beNil())
    }
    
    it("persists and loads dictionary") {
      let dict = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      storage.setDictionary(dict, forKey: "cityMap")
      expect(storage.dictionaryForKey("cityMap") as? Dictionary<String, String>) == dict
      
      storage.removeKey("cityMap")
      expect(storage.dictionaryForKey("cityMap")).to(beNil())
    }
    
    it("saves file to disk and removes from disk") {
      let key = "input.txt"
      let url = storage.urlForKey(key)
      expect(url.checkResourceIsReachableAndReturnError(nil)) == false
      storage.setString("sloth", forKey: key)
      expect(url.checkResourceIsReachableAndReturnError(nil)) == true
      storage.removeKey(key)
      expect(url.checkResourceIsReachableAndReturnError(nil)) == false
    }
    
    it("should be binary compatible with old SDKs") {
      let key = "traits.plist"
      let dictIn = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      (dictIn as NSDictionary).writeToURL(storage.urlForKey(key), atomically: true)
      let dictOut = storage.dictionaryForKey(key)
      expect(dictOut as? [String: String]) == dictIn
    }
    
    it("should work with crypto") {
      let url = SEGFileStorage.applicationSupportDirectoryURL()
      let crypto = SEGAES256Crypto(password: "thetrees")
      let s = SEGFileStorage(folder: url!, crypto: crypto)
      let dict = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      s.setDictionary(dict, forKey: "cityMap")
      expect(s.dictionaryForKey("cityMap") as? Dictionary<String, String>) == dict
      
      s.removeKey("cityMap")
      expect(s.dictionaryForKey("cityMap")).to(beNil())
    }
    
    afterEach {
      storage.resetAll()
    }
  }
}
