//
//  AppDelegate.m
//  TestAppIOS
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //[Analytics withSecret:@"k5l6rrye0hsv566zwuk7"];
    //[[Analytics sharedAnalytics] debug:YES];
    //[[Analytics sharedAnalytics] reset];
    [Analytics debug:YES];
    [Analytics initializeWithSecret:@"k5l6rrye0hsv566zwuk7"];
    //[[Analytics sharedAnalytics] identify:nil];
    [[Analytics sharedAnalytics] track:@"Anonymous Event"];
    [[Analytics sharedAnalytics] identify:@"Test User"];
    [[Analytics sharedAnalytics] track:@"Logged In Event"];
    return YES;
}
    
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[Analytics sharedAnalytics] track:@"Background Event"];
}

@end
