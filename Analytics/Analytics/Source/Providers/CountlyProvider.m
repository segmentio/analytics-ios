// CountlyProvider.m
// Copyright 2013 Segment.io

#import "CountlyProvider.h"
#import "Countly.h"
#import "AnalyticsLogger.h"

@implementation CountlyProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
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
    [AnalyticsLogger log:@"CountlyProvider initialized."];
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasServerUrl = [self.settings objectForKey:@"serverUrl"] != nil;
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasServerUrl && hasAppKey;
}


#pragma mark - Analytics API


- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // Countly has no support for identity information.
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Countly doesn't accept nested properties, so remove them (with warning).
    NSDictionary *notNestedProperties = [self ensureNotNested:properties];
    
    // Record the event!
    [[Countly sharedInstance] recordEvent:event segmentation:notNestedProperties count:1];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Screens just get tracked as events here.
    [self track:screenTitle properties:properties context:context];
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
    }
    return dict;
}

@end
