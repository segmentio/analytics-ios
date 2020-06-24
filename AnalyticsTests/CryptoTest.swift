//
//  CryptoTest.swift
//  Analytics
//
//  Copyright © 2016 Segment. All rights reserved.
//

import Analytics
import XCTest

class CryptoTest : XCTestCase {
    
    var crypto: AES256Crypto!
    override func setUp() {
        super.setUp()
        crypto = AES256Crypto(password: "slothysloth")
    }
    
    func testEncryptDecryptSuccess() {
        let strIn = "segment"
        let dataIn = strIn.data(using: String.Encoding.utf8)!
        let encryptedData = crypto.encrypt(dataIn)
        XCTAssert(encryptedData != nil, "Encrypted data should not be nil")
        
        let dataOut = crypto.decrypt(encryptedData!)
        XCTAssert(dataOut == dataIn, "Data should be the same")
        
        let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
        XCTAssertEqual(strOut, "segment", "Strings should be the same")
    }
    
    func testIncorrectPassword() {
        let strIn = "segment"
        let dataIn = strIn.data(using: String.Encoding.utf8)!
        let encryptedData = crypto.encrypt(dataIn)
        XCTAssert(encryptedData != nil, "Encrypted data should not be nil")
        
        let crypto2 = AES256Crypto(password: "wolf", salt: crypto.salt, iv: crypto.iv)
        let dataOut = crypto2.decrypt(encryptedData!)
        XCTAssertNotEqual(dataOut, dataIn, "In and out should not match")
        
        let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
        // no built in way to check password correctness
        // http://stackoverflow.com/questions/27712173/determine-if-key-is-incorrect-with-cccrypt-kccoptionpkcs7padding-objective-c
        XCTAssertNotEqual(strOut ?? "", strIn, "String in and out should not match")
    }
    
    func testFailureForIVAndSault() {
        let strIn = "segment"
        let dataIn = strIn.data(using: String.Encoding.utf8)!
        let encryptedData = crypto.encrypt(dataIn)
        XCTAssertNotNil(encryptedData, "Encrypted data should not be nil")
        
        let crypto2 = AES256Crypto(password: crypto.password)
        let dataOut = crypto2.decrypt(encryptedData!)
        XCTAssertNotEqual(dataOut, dataIn, "Out and In data should not match")
        
        let strOut = String(data: dataOut!, encoding: String.Encoding.utf8)
        XCTAssertNotEqual(strOut ?? "", strIn, "Out and In strings should not match")
    }
}
