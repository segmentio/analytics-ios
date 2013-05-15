// GoogleAnalyticsProvider.m
// Copyright 2013 Segment.io

#import "GoogleAnalyticsProvider.h"
#import "GAI.h"

@implementation GoogleAnalyticsProvider {
    
}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Google Analytics";
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Re-validate
    [self validate];

    // Check that all states are go
    if (self.enabled && self.valid && !self.initialized) {
        NSString *trackingId = [self.settings objectForKey:@"trackingId"];
        [[GAI sharedInstance] trackerWithTrackingId:trackingId];
        self.initialized = YES;
        NSLog(@"GoogleAnalyticsProvider initialized.");
    }
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasTrackingId = [self.settings objectForKey:@"trackingId"] != nil;
    self.valid = hasTrackingId;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // Not allowed to attach the userId in GA because it's prohibited in their terms of service.

    // We can set traits though. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [[[GAI sharedInstance] defaultTracker] set:key value:[traits objectForKey:key]];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // TODO: extract properties.value or properties.revenue for withValue:
    [[[GAI sharedInstance] defaultTracker] sendEventWithCategory:@"All" withAction:event withLabel:nil withValue:nil];
}


@end
