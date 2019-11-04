#import <Foundation/Foundation.h>

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#else
#import <UIKit/UIKit.h>
#endif


#if TARGET_OS_OSX

@interface NSViewController (SEGScreen)

+ (void)seg_swizzleViewDidAppear;

+ (NSViewController *)seg_topViewController;

@end

#else

@interface UIViewController (SEGScreen)

+ (void)seg_swizzleViewDidAppear;

+ (UIViewController *)seg_topViewController;

@end

#endif
