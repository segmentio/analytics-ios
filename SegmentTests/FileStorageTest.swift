//
//  FileStorageTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

import Segment
import XCTest


class FileStorageTest : XCTestCase {
    
    var storage : FileStorage!
    
    override func setUp() {
        super.setUp()
        let url = FileStorage.applicationSupportDirectoryURL()
        XCTAssertNotNil(url, "URL Should not be nil")
        #if os(macOS)
        XCTAssertEqual(url?.lastPathComponent, "segment-test")
        #else
        XCTAssertEqual(url?.lastPathComponent, "Application Support")
        #endif
        storage = FileStorage(folder: url!, crypto: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        storage.resetAll()
    }
    
    func testCreatesCachesDirectory() {
        let url = FileStorage.cachesDirectoryURL()
        XCTAssertNotNil(url, "URL should not be nil")
        XCTAssertEqual(url?.lastPathComponent, "Caches", "Last part of url should be Caches")
    }
    
    func testCreatesFolderIfNoneExists() {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
        let url = tempDir.appendingPathComponent(NSUUID().uuidString)
        
        XCTAssertNil(try? url?.checkResourceIsReachable() ?? true)
        _ = FileStorage(folder: url!, crypto: nil)
        
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url!.path, isDirectory: &isDir)
        
        XCTAssertEqual(exists, true, "Exists should be true")
        XCTAssertEqual(isDir.boolValue, true, "Should be a directory")
    }
    
    func testPersistsAndLoadsData() {
        let dataIn = "segment".data(using: String.Encoding.utf8)!
        storage.setData(dataIn, forKey: "mydata")
        
        let dataOut = storage.data(forKey: "mydata")
        XCTAssertEqual(dataOut, dataIn, "Out and In data should match")
        
        let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
        XCTAssertEqual(strOut, "segment")
    }
    
    func testPersistsAndLoadsString() {
        let str = "san francisco"
        storage.setString(str, forKey: "city")
        XCTAssertEqual(storage.string(forKey: "city"), str)
        
        storage.removeKey("city")
        XCTAssertNil(storage.string(forKey: "city"))
    }
    
    func testPersistsAndLoadsArray() {
        let array = [
          "san francisco",
          "new york",
          "tallinn",
        ]
        storage.setArray(array, forKey: "cities")
        XCTAssertEqual(storage.array(forKey: "cities") as? Array<String>, array)
        
        storage.removeKey("cities")
        XCTAssertNil(storage.array(forKey: "cities"))
    }
    
    func testPersistsAndLoadsDictionary() {
        let dict = [
          "san francisco": "tech",
          "new york": "finance",
          "paris": "fashion",
        ]
        storage.setDictionary(dict, forKey: "cityMap")
        XCTAssertEqual(storage.dictionary(forKey: "cityMap") as? Dictionary<String, String>, dict)
        
        storage.removeKey("cityMap")
        XCTAssertNil(storage.dictionary(forKey: "cityMap"))
    }
    
    func testSavesFileToDiskRemovesFromDisk() {
        let key = "input.txt"
        let url = storage.url(forKey: key)
        XCTAssertNil(try? url.checkResourceIsReachable())
        storage.setString("sloth", forKey: key)
        XCTAssertEqual(try! url.checkResourceIsReachable(), true)
        storage.removeKey(key)
        XCTAssertNil(try? url.checkResourceIsReachable())
    }
    
    func testShouldBeBinaryCompatible() {
        let key = "traits.plist"
        let dictIn = [
          "san francisco": "tech",
          "new york": "finance",
          "paris": "fashion",
        ]
        
        (dictIn as NSDictionary).write(to: storage.url(forKey: key), atomically: true)
        let dictOut = storage.dictionary(forKey: key)
        XCTAssertEqual(dictOut as? [String: String], dictIn)
    }

    func testShouldRemoveDictionaryForInvalidPlistConversion() {
        let key = "invalid.plist"
        let dictIn: [String: Any] = [
          "timestamp": TimeInterval.nan // `.nan` fails JSONSerialization
        ]

        let url = storage.url(forKey: key)
        (dictIn as NSDictionary).write(to: url, atomically: true)
        let dictOut = storage.dictionary(forKey: key)
        XCTAssertNil(dictOut)
        XCTAssertNil(try? url.checkResourceIsReachable())
    }
    
    func testShouldWorkWithCrypto() {
        let url = FileStorage.applicationSupportDirectoryURL()
        let crypto = AES256Crypto(password: "thetrees")
        let s = FileStorage(folder: url!, crypto: crypto)
        let dict = [
          "san francisco": "tech",
          "new york": "finance",
          "paris": "fashion",
        ]
        s.setDictionary(dict, forKey: "cityMap")
        XCTAssertEqual(s.dictionary(forKey: "cityMap") as? Dictionary<String, String>, dict)
        
        s.removeKey("cityMap")
        XCTAssertNil(s.dictionary(forKey: "cityMap"))
    }
}
