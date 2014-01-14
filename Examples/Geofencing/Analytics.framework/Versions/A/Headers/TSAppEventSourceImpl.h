#pragma once
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "TSHelpers.h"
#import "TSAppEventSource.h"

@interface TSAppEventSourceImpl : NSObject<TSAppEventSource, SKPaymentTransactionObserver, SKProductsRequestDelegate> {
@private
	id<NSObject> foregroundedEventObserver;
	TSOpenHandler onOpen;
	TSTransactionHandler onTransaction;
    NSMutableDictionary *requestTransactions;
}

- (void)setOpenHandler:(TSOpenHandler)handler;
- (void)setTransactionHandler:(TSTransactionHandler)handler;

@end
