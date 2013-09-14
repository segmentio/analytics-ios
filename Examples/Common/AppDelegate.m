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
    [Analytics initializeWithSecret:@"k5l6rrye0hsv566zwuk7"];
    [[Analytics sharedAnalytics] debug:YES];
    [[Analytics sharedAnalytics] reset];
    [[Analytics sharedAnalytics] identify:@"Test User"];
    [[Analytics sharedAnalytics] track:@"First App Launch"];
    return YES;
}
    
- (void)applicationDidEnterBackground:(UIApplication *)application {
    //[[Analytics sharedAnalytics] track:@"Background Event"];
}

@end
