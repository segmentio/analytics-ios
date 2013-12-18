// CountlyProvider.m
// Copyright 2013 Segment.io

#import "CountlyProvider.h"
#import "Countly.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation CountlyProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Countly"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Countly";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *appKey = [self.settings objectForKey:@"appKey"];
    NSString *serverUrl = [self.settings objectForKey:@"serverUrl"];
    [[Countly sharedInstance] start:appKey withHost:serverUrl];
    SOLog(@"CountlyProvider initialized with appKey %@ and serverUrl %@", appKey, serverUrl);
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasServerUrl = [self.settings objectForKey:@"serverUrl"] != nil;
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasServerUrl && hasAppKey;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // Countly has no support for identity information.
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Countly doesn't accept nested properties, so remove them (with warning).
    NSDictionary *notNestedProperties = [self ensureNotNested:properties];
    
    // Record the event! Track any revenue.
    NSNumber *revenue = [AnalyticsProvider extractRevenue:properties];
    if (revenue) {
        SOLog(@"Calling Countly with event:%@, segmentation:%@, sum:%@", event, notNestedProperties, revenue);
        [[Countly sharedInstance] recordEvent:event segmentation:notNestedProperties count:1 sum:revenue.longValue];
    } else {
        SOLog(@"Calling Countly with event:%@, segmentation:%@", event, notNestedProperties);
        [[Countly sharedInstance] recordEvent:event segmentation:notNestedProperties count:1];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Screens just get tracked as events here.
    [self track:screenTitle properties:properties options:options];
}

- (NSDictionary *)ensureNotNested:(NSDictionary *)dictionary
{
    // Copy the dictionary so that we only modify the properties going to Countly
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dictionary];
    
    // Iterate over the properties and remove nested dictionaries and arrays
    for (id key in dictionary) {
        id value = [dict objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            NSLog(@"WARNING: Removing nested [analytics track] property %@ for Countly (not supported by Countly).", key);
            [dict removeObjectForKey:key];
        }
        else if ([value isKindOfClass:[NSNumber class]]) {
            NSLog(@"WARNING: Removing number segmentation [analytics track] property %@ for Countly (not supported by Countly).", key);
            [dict removeObjectForKey:key];
        }
    }
    return dict;
}

@end
