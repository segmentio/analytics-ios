@import Foundation;
@import StoreKit;
#import "SEGAnalytics.h"

NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(StoreKitTracker)
@interface SEGStoreKitTracker : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>

+ (instancetype)trackTransactionsForAnalytics:(SEGAnalytics *)analytics;

@end

NS_ASSUME_NONNULL_END
