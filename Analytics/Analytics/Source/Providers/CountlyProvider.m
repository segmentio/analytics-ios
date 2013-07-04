// CountlyProvider.m
// Copyright 2013 Segment.io

#import "CountlyProvider.h"
#import "Countly.h"

#ifdef ANALYTICS_DEBUG
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif


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
    AnalyticsDebugLog(@"CountlyProvider initialized.");
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
    [[Countly sharedInstance] recordEvent:event segmentation:properties count:1];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Screens just get tracked as events here.
    [self track:screenTitle properties:properties context:context];
}

@end
