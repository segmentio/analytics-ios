//
//  ViewController.m
//  ManualExample
//
//  Created by Tony Xiao on 6/30/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Analytics/Analytics.h>
#import "ViewController.h"


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[SEGAnalytics sharedAnalytics] track:@"Manual Example Main View Loaded"];
    [[SEGAnalytics sharedAnalytics] flush];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)fireEvent:(id)sender
{
    [[SEGAnalytics sharedAnalytics] track:@"Manual Example Fire Event"];
    [[SEGAnalytics sharedAnalytics] flush];
}

@end
