//
//  ViewController.m
//  TestAppIOS
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//


#import "ViewController.h"
#import "Reachability.h"
#import <Analytics/Analytics.h>
#import "Analytics/TSTapstream.h"
#import "Analytics/Private/SegmentioIntegration.h"
#import <Analytics/Flurry.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[Analytics sharedAnalytics] track:@"Test ViewController Load"];
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableOnWWAN = NO;
}

- (IBAction)identify:(id)sender {
    NSLog(@"test identify");
    NSLog(@"can access BugSnag SDK? Here's the userId %@", [Bugsnag instance].userId);
    NSLog(@"can access Google Analytics SDK? %@", [[GAI sharedInstance] defaultTracker]);
    NSLog(@"can access Mixpanel SDK? Here's the distinctId %@", [Mixpanel sharedInstance].distinctId);
    [[Mixpanel sharedInstance].people increment:@"point count" by:@500];
    NSLog(@"can access Flurry SDK?");
    [Flurry setUserID:@"asdfasdf"];
    NSLog(@"can access Crittercism SDK?");
    [Crittercism setUsername:@"asdfasdf"];
    NSLog(@"can access Tapstream SDK? %@", [TSTapstream instance]);
    [[Analytics sharedAnalytics] identify:@"Khan"];
}

- (IBAction)track:(id)sender {
    NSLog(@"test track");
    [[Analytics sharedAnalytics] track:@"Hello Event"
        properties:@{ @"bear" : @"pigbearstrong", @"dog" : @"duckduckgoose", @"cat" : @89, @"domain" : @[@"hothouselabs.com", @"gmail.com"] }];
}

- (IBAction)screen:(id)sender {
    NSLog(@"test screen");
    [[Analytics sharedAnalytics] screen:@"Initial Screen"];
}

- (IBAction)group:(id)sender {
    NSLog(@"test group");
    [[Analytics sharedAnalytics] group:@"segmentio-inc" traits:@{ @"employees": @11 }];
}

- (IBAction)reset:(id)sender {
    NSLog(@"test reset");
    [[Analytics sharedAnalytics] reset];
}

- (IBAction)disable:(id)sender {
    NSLog(@"test disable");
    [[Analytics sharedAnalytics] disable];
}

- (IBAction)enable:(id)sender {
    NSLog(@"test enable");
    [[Analytics sharedAnalytics] enable];
}

- (IBAction)crash:(id)sender {
    // How to crash an app:
    // http://support.crashlytics.com/knowledgebase/articles/92523-why-can-t-i-have-xcode-connected-
    // http://support.crashlytics.com/knowledgebase/articles/92522-is-there-a-quick-way-to-force-a-crash-
    NSLog(@"About to crash on purpose...");
    int *x = NULL;
    *x = 42;
    NSLog(@"Should have crashed :)");
}

@end
