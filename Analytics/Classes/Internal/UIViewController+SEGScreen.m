#import "UIViewController+SEGScreen.h"
#import <objc/runtime.h>
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"


@implementation UIViewController (SEGScreen)

+ (void)seg_swizzleViewDidAppear
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(seg_viewDidAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


+ (UIViewController *)seg_topViewController
{
    UIViewController *root = [UIApplication sharedApplication].delegate.window.rootViewController;
    return [self seg_topViewController:root];
}

+ (UIViewController *)seg_topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }
    
    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self seg_topViewController:lastViewController];
    }
    
    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self seg_topViewController:presentedViewController];
}

- (void)seg_viewDidAppear:(BOOL)animated
{
    UIViewController *top = [UIViewController seg_topViewController];
    if (!top) {
        return;
    }
    
    NSString *name = [top title];
    if (name.length == 0) {
        name = [[[top class] description] stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
        // Class name could be just "ViewController".
        if (name.length == 0) {
            SEGLog(@"Could not infer screen name.");
            name = @"Unknown";
        }
    }
    [[SEGAnalytics sharedAnalytics] screen:name properties:nil options:nil];
    
    [self seg_viewDidAppear:animated];
}

@end