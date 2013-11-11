// ChartbeatProvider.m
// Copyright 2013 Segment.io

#import "ChartbeatProvider.h"
#import "CBTracker.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation ChartbeatProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Chartbeat"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Chartbeat";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSInteger uid = [[self.settings objectForKey:@"uid"] integerValue];
    [[CBTracker sharedTracker] startTrackerWithAccountID:uid];
    SOLog(@"ChartbeatProvider initialized with uid %d", uid);
}

- (void)stop
{
    // Chartbeat sends pings, which we need to disable.
    [[CBTracker sharedTracker] stopTracker];
    SOLog(@"ChartbeatProvider stopped.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasUID = [self.settings objectForKey:@"uid"] != nil;
    self.valid = hasUID;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // Chartbeat has no support for identity information.
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Chartbeat has no support for event tracking.
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [[CBTracker sharedTracker] trackView:nil viewId:screenTitle title:screenTitle];
}

@end
