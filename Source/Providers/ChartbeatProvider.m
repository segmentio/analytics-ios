// ChartbeatProvider.m
// Copyright 2013 Segment.io

#import "ChartbeatProvider.h"

#import "CBTracker.h"


@implementation ChartbeatProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Chartbeat";
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *accountId = [self.settings objectForKey:@"accountId"];
    [[CBTracker sharedTracker] startTrackerWithAccountID:accountId];
    NSLog(@"ChartbeatProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAccountId = [self.settings objectForKey:@"accountId"] != nil;
    self.valid = hasAccountId;
}


#pragma mark - Analytics API

// Chartbeat has no event tracking or user identification.

@end
