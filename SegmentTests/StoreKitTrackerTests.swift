//
//  StoreKitTrackerTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Analytics
import XCTest

class mockTransaction: SKPaymentTransaction {
  override var transactionIdentifier: String? {
    return "tid"
  }
  override var transactionState: SKPaymentTransactionState {
    return SKPaymentTransactionState.purchased
  }
  override var payment: SKPayment {
    return mockPayment()
  }
}

class mockPayment: SKPayment {
  override var productIdentifier: String { return "pid" }
}

class mockProduct: SKProduct {
  override var productIdentifier: String { return "pid" }
  override var price: NSDecimalNumber { return 3 }
  override var localizedTitle: String { return "lt" }

}

class mockProductResponse: SKProductsResponse {
  override var products: [SKProduct] {
    return [mockProduct()]
  }
}

class StoreKitTrackerTests: XCTestCase {

    var test: TestMiddleware!
    var tracker: StoreKitTracker!
    var analytics: Analytics!
    
    override func setUp() {
        super.setUp()
        let config = AnalyticsConfiguration(writeKey: "foobar")
        test = TestMiddleware()
        config.sourceMiddleware = [test]
        analytics = Analytics(configuration: config)
        tracker = StoreKitTracker.trackTransactions(for: analytics)
    }
    
    func testSKPaymentQueueObserver() {
        let transaction = mockTransaction()
        XCTAssertEqual(transaction.transactionIdentifier, "tid")
        tracker.paymentQueue(SKPaymentQueue(), updatedTransactions: [transaction])
        
        tracker.productsRequest(SKProductsRequest(), didReceive: mockProductResponse())
        
        let payload = test.lastContext?.payload as? TrackPayload
        
        XCTAssertEqual(payload?.event, "Order Completed")
    }
}
