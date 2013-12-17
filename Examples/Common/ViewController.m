//
//  ViewController.m
//  TestAppIOS
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//


#import "ViewController.h"
#import "Reachability.h"
#import "Analytics/TSTapstream.h"
#import "Analytics/Private/SegmentioProvider.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[Analytics sharedAnalytics] track:@"Test View Load Event"];
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableOnWWAN = NO;
}

- (IBAction)identify:(id)sender {
    NSLog(@"test identify");
    NSLog(@"can access BugSnag SDK? Here's the userId %@", [Bugsnag instance].userId);
    NSLog(@"can access Google Analytics SDK? %@", [[GAI sharedInstance] defaultTracker]);
    NSLog(@"can access Mixpanel SDK? Here's the distinctId %@", [Mixpanel sharedInstance].distinctId);
    NSLog(@"can access Flurry SDK?");
    [Flurry setUserID:@"asdfasdf"];
    NSLog(@"can access Crittercism SDK?");
    [Crittercism setUsername:@"asdfasdf"];
    NSLog(@"can access Chartbeat SDK? %@", [CBTracker sharedTracker]);
    NSLog(@"can access Tapstream SDK? %@", [TSTapstream instance]);
    [[Analytics sharedAnalytics] identify:@"Khan"];
}

- (IBAction)track:(id)sender {
    NSLog(@"test track");
    [[Analytics sharedAnalytics] track:@"Hello Event"
        properties:@{ @"bear" : @"pigbearstrong", @"dog" : @"duckduckgoose", @"cat" : @89 }];
}

- (IBAction)screen:(id)sender {
    NSLog(@"test screen");
    [[Analytics sharedAnalytics] screen:@"Initial Screen"];
}

- (IBAction)flush:(id)sender {
    SegmentioProvider *segmentio = [[Analytics sharedAnalytics] providers][@"Segment.io"];
    [segmentio flush];
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
