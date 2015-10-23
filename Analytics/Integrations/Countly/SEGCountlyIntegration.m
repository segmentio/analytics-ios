// CountlyIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGCountlyIntegration.h"
#import <Countly/Countly.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGCountlyIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Countly"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Countly";
        self.valid = NO;
        self.initialized = NO;
        self.countly = [Countly sharedInstance];
    }
    return self;
}

- (void)start
{
    NSString *appKey = [self.settings objectForKey:@"appKey"];
    NSString *serverUrl = [self.settings objectForKey:@"serverUrl"];

    // Countly's SDK will silently fail to send data if it's not initialized on the main thread.
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.countly start:appKey withHost:serverUrl];
      SEGLog(@"CountlyIntegration initialized with appKey %@ and serverUrl %@", appKey, serverUrl);
    });
    [super start]; // todo: maybe not?
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasServerUrl = [self.settings objectForKey:@"serverUrl"] != nil;
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasServerUrl && hasAppKey;
}


#pragma mark - Analytics API

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Countly's SDK will silently fail to send data if it's not sent on the main thread.
    // Countly doesn't accept nested properties, so remove them (with warning).
    NSDictionary *notNestedProperties = [self ensureNotNested:properties];

    // Record the event! Track any revenue.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        SEGLog(@"Calling Countly with event:%@, segmentation:%@, sum:%@", event, notNestedProperties, revenue);
        [self.countly recordEvent:event segmentation:notNestedProperties count:1 sum:revenue.longValue];
    } else {
        SEGLog(@"Calling Countly with event:%@, segmentation:%@", event, notNestedProperties);
        [self.countly recordEvent:event segmentation:notNestedProperties count:1];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Screens just get tracked as events here.
    [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (NSDictionary *)ensureNotNested:(NSDictionary *)dictionary
{
    // Copy the dictionary so that we only modify the properties going to Countly
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];

    // Iterate over the properties and remove nested dictionaries and arrays
    for (id key in dictionary) {
        id value = [dict objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            SEGLog(@"WARNING: Removing nested [analytics track] property %@ for Countly (not supported by Countly).", key);
            [dict removeObjectForKey:key];
        }
    }
    return dict;
}

@end
