//
//  UserDefaultsStorageTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

@testable import Segment
import XCTest

class UserDefaultsStorageTest : XCTestCase {
    
    var storage : UserDefaultsStorage!
    
    override func setUp() {
        super.setUp()
        storage = UserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: nil, crypto: nil)
    }
    
    override func tearDown() {
        super.tearDown()
        storage.resetAll()
    }
    
    func testPersistsAndLoadsData() {
        let dataIn = "segment".data(using: String.Encoding.utf8)!
        storage.setData(dataIn, forKey: "mydata")
        
        let dataOut = storage.data(forKey: "mydata")
        XCTAssertEqual(dataOut, dataIn)
        
        let strOut = String(data: dataOut!, encoding: .utf8)
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
    
    func testShouldWorkWithCrypto() {
        let crypto = AES256Crypto(password: "thetrees")
        let s = UserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: nil, crypto: crypto)
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
    
    func testShouldWorkWithNamespace() {
        let crypto = AES256Crypto(password: "thetrees")
        let s = UserDefaultsStorage(defaults: UserDefaults.standard, namespacePrefix: "segment", crypto: crypto)
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
