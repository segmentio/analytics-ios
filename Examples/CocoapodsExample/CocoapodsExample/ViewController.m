//
//  ViewController.m
//  CocoapodsExample
//
//  Created by Tony Xiao on 11/28/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Analytics/SEGAnalytics.h>
// TODO: Test and see if this works
// @import Analytics;
#import "ViewController.h"


@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    userActivity.webpageURL = [NSURL URLWithString:@"http://www.segment.com"];
    [[SEGAnalytics sharedAnalytics] continueUserActivity:userActivity];
    [[SEGAnalytics sharedAnalytics] track:@"test"];
    [[SEGAnalytics sharedAnalytics] flush];
}

- (IBAction)fireEvent:(id)sender
{
    [[SEGAnalytics sharedAnalytics] track:@"Cocoapods Example Button"];
    [[SEGAnalytics sharedAnalytics] flush];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
