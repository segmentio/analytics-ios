// AmplitudeIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGAmplitudeIntegration.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGAmplitudeIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Amplitude"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Amplitude";
        self.valid = NO;
        self.initialized = NO;
        self.amplitude = [Amplitude instance];
    }
    return self;
}

- (void)start
{
    NSString *apiKey = [self.settings objectForKey:@"apiKey"];
    if ([(NSNumber *)[self.settings objectForKey:@"trackSessionEvents"] boolValue]) {
        [Amplitude instance].trackingSessionEvents = true;
    }
    [[Amplitude instance] initializeApiKey:apiKey];
    SEGLog(@"AmplitudeIntegration initialized.");
    [super start];
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
    [_amplitude setUserId:userId];
    [_amplitude setUserProperties:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [_amplitude logEvent:event withEventProperties:properties];

    // Track any revenue.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        id productId = [properties objectForKey:@"productId"];
        if (!productId || ![productId isKindOfClass:[NSString class]]) {
            productId = nil;
        }
        id quantity = [properties objectForKey:@"quantity"];
        if (!quantity || ![quantity isKindOfClass:[NSNumber class]]) {
            quantity = [NSNumber numberWithInt:1];
        }
        id receipt = [properties objectForKey:@"receipt"];
        if (!receipt || ![receipt isKindOfClass:[NSString class]]) {
            receipt = nil;
        }
        NSLog(@"Number : %@", revenue);
        [_amplitude logRevenue:productId
                      quantity:[quantity integerValue]
                         price:revenue
                       receipt:receipt];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if ([(NSNumber *)[self.settings objectForKey:@"trackAllPages"] boolValue]) {
        // Track the screen view as an event.
        [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
    }
}

- (void)flush
{
    [_amplitude uploadEvents];
}

@end
