// AmplitudeProvider.m
// Copyright 2013 Segment.io

#import <Amplitude-iOS/Amplitude.h>
#import "AmplitudeProvider.h"
#import "SOUtils.h"
#import "Analytics.h"

@implementation AmplitudeProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Amplitude"];
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
    SOLog(@"AmplitudeProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAPIKey = [self.settings objectForKey:@"apiKey"] != nil;
    self.valid = hasAPIKey;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    [Amplitude setUserId:userId];
    [Amplitude setGlobalUserProperties:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [Amplitude logEvent:event withCustomProperties:properties];

    // Track any revenue.
    NSNumber *revenue = [AnalyticsProvider extractRevenue:properties];
    if (revenue) {
        [Amplitude logRevenue:revenue];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // No explicit support for screens, so we'll track an event instead.
    [self track:screenTitle properties:properties context:context];
}

@end
