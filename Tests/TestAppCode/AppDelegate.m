//
//  AppDelegate.m
//  AnalyticsPodApp
//
//  Created by Peter Reinhardt on 7/11/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AppDelegate.h"
#import "Analytics/Analytics.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // initialize the analytics-app project
    [Analytics withSecret:@"k5l6rrye0hsv566zwuk7"];
    
    // during development: reset the settings cache frequently so that
    // as you change settings on your integrations page, the settings update quickly here.
    [[Analytics sharedAnalytics] debug:YES]; // remove before app store release
    [[Analytics sharedAnalytics] reset]; // remove before app store release
    
    // Override point for customization after application launch.
    return YES;
}


@end
