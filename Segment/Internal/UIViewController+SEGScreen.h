#import "SEGSerializableValue.h"

#if TARGET_OS_IPHONE && !TARGET_OS_WATCH
@import UIKit;

@interface UIViewController (SEGScreen)

+ (void)seg_swizzleViewDidAppear;
+ (UIViewController *)seg_rootViewControllerFromView:(UIView *)view;

@end

#endif
