// KISSmetricsProvider.m
// Copyright 2013 Segment.io

#import "KISSmetricsProvider.h"
#import "KISSMetricsAPI.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation KISSmetricsProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"KISSmetrics"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"KISSmetrics";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    [KISSMetricsAPI sharedAPIWithKey:apiKey];
    SOLog(@"KISSmetricsProvider initialized.");
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
    [[KISSMetricsAPI sharedAPI] identify:userId];
    [[KISSMetricsAPI sharedAPI] setProperties:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [[KISSMetricsAPI sharedAPI] recordEvent:event withProperties:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // No explicit support for screens, so we'll track an event instead.
    [self track:screenTitle properties:properties options:options];
}

@end
