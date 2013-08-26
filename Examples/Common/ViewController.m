//
//  ViewController.m
//  TestAppIOS
//
//  Created by Tony Xiao on 8/17/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//


#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[Analytics sharedAnalytics] track:@"Test View Load Event"];
}

- (IBAction)identify:(id)sender {
    NSLog(@"test identify");
    [[Analytics sharedAnalytics] identify:@"Khan"];
}

- (IBAction)track:(id)sender {
    NSLog(@"test track");
    [[Analytics sharedAnalytics] track:@"Hello Event"];
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
