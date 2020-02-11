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
    
    it("Creates caches directory") {
      let url = SEGFileStorage.cachesDirectoryURL()
      expect(url).toNot(beNil())
      expect(url?.lastPathComponent) == "Caches"
    }
    
    it("creates folder if none exists") {
      let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
      let url = tempDir.appendingPathComponent(NSUUID().uuidString)
      
      expect(try? url?.checkResourceIsReachable()).to(beNil())
      _ = SEGFileStorage(folder: url!, crypto: nil)
      
      var isDir: ObjCBool = false
      let exists = FileManager.default.fileExists(atPath: url!.path, isDirectory: &isDir)
      
      expect(exists) == true
      expect(isDir.boolValue) == true
    }
    
    it("persists and loads data") {
      let dataIn = "segment".data(using: String.Encoding.utf8)!
      storage.setData(dataIn, forKey: "mydata")
      
      let dataOut = storage.data(forKey: "mydata")
      expect(dataOut) == dataIn
      
      let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
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
    
    it("saves file to disk and removes from disk") {
      let key = "input.txt"
      let url = storage.url(forKey: key)
      expect(try? url.checkResourceIsReachable()).to(beNil())
      storage.setString("sloth", forKey: key)
      expect(try! url.checkResourceIsReachable()) == true
      storage.removeKey(key)
      expect(try? url.checkResourceIsReachable()).to(beNil())
    }
    
    it("should be binary compatible with old SDKs") {
      let key = "traits.plist"
      let dictIn = [
        "san francisco": "tech",
        "new york": "finance",
        "paris": "fashion",
      ]
      
      (dictIn as NSDictionary).write(to: storage.url(forKey: key), atomically: true)
      let dictOut = storage.dictionary(forKey: key)
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
      expect(s.dictionary(forKey: "cityMap") as? Dictionary<String, String>) == dict
      
      s.removeKey("cityMap")
      expect(s.dictionary(forKey: "cityMap")).to(beNil())
    }
    
    afterEach {
      storage.resetAll()
    }
  }
}
