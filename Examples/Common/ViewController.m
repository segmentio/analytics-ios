//
//  ViewController.m
//  TestAppIOS
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//


#import "ViewController.h"
#import "Reachability.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[Analytics sharedAnalytics] track:@"Test View Load Event"];
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    reach.reachableOnWWAN = NO;
}

- (IBAction)identify:(id)sender {
    NSLog(@"test identify");
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

@end
