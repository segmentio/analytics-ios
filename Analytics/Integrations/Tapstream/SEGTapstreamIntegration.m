// TapstreamIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGTapstreamIntegration.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGTapstreamIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Tapstream"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Tapstream";
        self.valid = NO;
        self.initialized = NO;
        self.tapstreamClass = [TSTapstream class];
    }
    return self;
}

- (void)start
{
    TSConfig *config = [TSConfig configWithDefaults];

    // Load any values that the TSConfig object supports
    for (NSString *key in self.settings) {
        if ([config respondsToSelector:NSSelectorFromString(key)]) {
            [config setValue:[self.settings objectForKey:key] forKey:key];
        }
    }

    if (SEGIDFA())
        [config setValue:SEGIDFA() forKey:@"idfa"];

    NSString *accountName = [self.settings objectForKey:@"accountName"];
    NSString *sdkSecret = [self.settings objectForKey:@"sdkSecret"];

    [self.tapstreamClass createWithAccountName:accountName developerSecret:sdkSecret config:config];

    SEGLog(@"TapstreamIntegration initialized with accountName %@ and developerSecret %@", accountName, sdkSecret);

    [super start];
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAccountName = [self.settings objectForKey:@"accountName"] != nil;
    BOOL hasSDKSecret = [self.settings objectForKey:@"sdkSecret"] != nil;
    self.valid = hasAccountName && hasSDKSecret;
}


#pragma mark - Analytics API

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    TSEvent *e = [self makeEvent:event properties:properties options:options];
    [[self.tapstreamClass instance] fireEvent:e];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    TSEvent *e = [self makeEvent:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
    [[self.tapstreamClass instance] fireEvent:e];
}

- (TSEvent *)makeEvent:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Add support for Tapstream's "one-time-only" events by looking for a field in the context dict.
    // One time only will be false by default.
    NSNumber *oneTimeOnly = [options objectForKey:@"oneTimeOnly"];
    BOOL oto = oneTimeOnly != nil && [oneTimeOnly boolValue] == YES;

    TSEvent *e = [TSEvent eventWithName:event oneTimeOnly:oto];

    for (NSString *key in properties) {
        id value = [properties objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            [e addValue:(NSString *)value forKey:(NSString *)key];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *number = (NSNumber *)value;
            [e addValue:(NSString *)number forKey:(NSString *)key];
        } else {
            SEGLog(@"Tapstream Event cannot accept a param of type %@, skipping param %@", [value class], key);
        }
    }

    return e;
}

@end
