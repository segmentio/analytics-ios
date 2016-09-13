#if TARGET_OS_IOS
#import <UIKit/UIKit.h>

@interface UIViewController (SEGScreen)

+ (void)seg_swizzleViewDidAppear;

@end

#endif