//
//  StoreKitTrackerTest.swift
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

import Quick
import Nimble
import Analytics

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

class StoreKitTrackerTests: QuickSpec {
  override func spec() {

    var test: TestMiddleware!
    var tracker: SEGStoreKitTracker!
    var analytics: Analytics!

    beforeEach {
      let config = AnalyticsConfiguration(writeKey: "foobar")
      test = TestMiddleware()
      config.middlewares = [test]
      analytics = Analytics(configuration: config)
      tracker = SEGStoreKitTracker.trackTransactions(for: analytics)
    }

    it("SKPaymentQueue Observer") {
      let transaction = mockTransaction()
      expect(transaction.transactionIdentifier) == "tid"
      tracker.paymentQueue(SKPaymentQueue(), updatedTransactions: [transaction])
      
      tracker.productsRequest(SKProductsRequest(), didReceive: mockProductResponse())
      
      let payload = test.lastContext?.payload as? TrackPayload
      
      expect(payload?.event) == "Order Completed"
    }

  }

}
