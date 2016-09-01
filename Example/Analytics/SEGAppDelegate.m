#import "SEGAppDelegate.h"
#import <Analytics/SEGAnalytics.h>


@implementation SEGAppDelegate

// https://segment.com/segment-engineering/sources/ios/overview
NSString *const SEGMENT_WRITE_KEY = @"QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.trackAttributionData = YES;
    [SEGAnalytics setupWithConfiguration:configuration];
    return YES;
}

@end
