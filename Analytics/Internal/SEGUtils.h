//
//  SEGUtils.h
//
//

#import <Foundation/Foundation.h>
#import "SEGAnalyticsUtils.h"

NS_ASSUME_NONNULL_BEGIN

@class SEGAnalyticsConfiguration;
@class SEGReachability;

NS_SWIFT_NAME(Utilities)
@interface SEGUtils : NSObject

+ (NSData *_Nullable)dataFromPlist:(nonnull id)plist;
+ (id _Nullable)plistFromData:(NSData *)data;

+ (id _Nullable)traverseJSON:(id _Nullable)object andReplaceWithFilters:(NSDictionary<NSString*, NSString*>*)patterns;

@end

BOOL isUnitTesting(void);

NSString * _Nullable deviceTokenToString(NSData * _Nullable deviceToken);
NSString *getDeviceModel(void);
BOOL getAdTrackingEnabled(SEGAnalyticsConfiguration *configuration);
NSDictionary *getStaticContext(SEGAnalyticsConfiguration *configuration, NSString * _Nullable deviceToken);
NSDictionary *getLiveContext(SEGReachability *reachability, NSDictionary * _Nullable referrer, NSDictionary * _Nullable traits);

NS_ASSUME_NONNULL_END
