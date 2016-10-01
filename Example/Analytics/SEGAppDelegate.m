#import "SEGAppDelegate.h"
#import <Analytics/SEGAnalytics.h>


@implementation SEGAppDelegate

// https://segment.com/segment-engineering/sources/ios/overview
NSString *const SEGMENT_WRITE_KEY = @"Ad056ODmzqJo9wU4v40sfeh8h1dlUcpP";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SEGAnalytics debug:YES];
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.trackAttributionData = YES;
    configuration.flushAt = 1;
    [SEGAnalytics setupWithConfiguration:configuration];
    return YES;
}

@end
