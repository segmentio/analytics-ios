#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "SEGAnalytics.h"


@interface SEGStoreKitTracker : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

+ (instancetype)trackTransactionsForAnalytics:(SEGAnalytics *)analytics;

@end
