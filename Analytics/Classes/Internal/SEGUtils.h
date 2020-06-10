//
//  SEGUtils.h
//
//

#import <Foundation/Foundation.h>
#import "SEGAnalyticsUtils.h"


NS_SWIFT_NAME(Utilities)
@interface SEGUtils : NSObject

+ (NSData *_Nullable)dataFromPlist:(nonnull id)plist;
+ (id _Nullable)plistFromData:(NSData *_Nonnull)data;

+ (id _Nullable)traverseJSON:(id _Nullable)object andReplaceWithFilters:(nonnull NSDictionary<NSString*, NSString*>*)patterns;

@end

BOOL isUnitTesting(void);
