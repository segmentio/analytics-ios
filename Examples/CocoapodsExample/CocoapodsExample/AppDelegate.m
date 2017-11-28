//
//  AppDelegate.m
//  CocoapodsExample
//
//  Created by Tony Xiao on 11/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Analytics/SEGAnalytics.h>
#import "AppDelegate.h"


@interface AppDelegate ()

@end

// https://segment.com/segment-mobile/sources/ios_cocoapods_example/overview
NSString *const SEGMENT_WRITE_KEY = @"zr5x22gUVBDM3hO3uHkbMkVe6Pd6sCna";


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [SEGAnalytics debug:YES];
    SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:SEGMENT_WRITE_KEY];
    configuration.trackApplicationLifecycleEvents = YES;
    configuration.trackAttributionData = YES;
    configuration.flushAt = 1;
    [SEGAnalytics setupWithConfiguration:configuration];
    [[SEGAnalytics sharedAnalytics] track:@"Cocoapods Example Launched"];
    [[SEGAnalytics sharedAnalytics] flush];
    NSLog(@"application:didFinishLaunchingWithOptions: %@", launchOptions);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive:");
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground:");
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground:");
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive:");
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"applicationWillTerminate:");
}

@end
