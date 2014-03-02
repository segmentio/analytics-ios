// AmplitudeIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Amplitude-iOS/Amplitude.h>
#import "AmplitudeIntegration.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation AmplitudeIntegration

#pragma mark - Initialization

+ (void)load {
    [Analytics registerIntegration:self withIdentifier:@"Amplitude"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Amplitude";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [Amplitude initializeApiKey:apiKey];
    SOLog(@"AmplitudeIntegration initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasAPIKey;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    [Amplitude setUserId:userId];
    [Amplitude setGlobalUserProperties:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [Amplitude logEvent:event withCustomProperties:properties];

    // Track any revenue.
    NSNumber *revenue = [AnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        [Amplitude logRevenue:revenue];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // No explicit support for screens, so we'll track an event instead.
    [self track:screenTitle properties:properties options:options];
}

@end
