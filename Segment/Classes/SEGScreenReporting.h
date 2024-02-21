#if TARGET_OS_IPHONE
@import UIKit;
#elif TARGET_OS_OSX
@import Cocoa;
#endif

#import "SEGSerializableValue.h"

/** Implement this protocol to override automatic screen reporting
 */

NS_ASSUME_NONNULL_BEGIN

@protocol SEGScreenReporting
@optional
#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
- (void)seg_trackScreen:(UIViewController*)screen name:(NSString*)name;
@property (readonly, nullable) UIViewController *seg_mainViewController;
#elif TARGET_OS_OSX
- (void)seg_trackScreen:(NSViewController*)screen name:(NSString*)name;
@property (readonly, nullable) NSViewController *seg_mainViewController;
#endif
@end

NS_ASSUME_NONNULL_END


