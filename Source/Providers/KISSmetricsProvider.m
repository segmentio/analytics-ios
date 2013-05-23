// KISSmetricsProvider.m
// Copyright 2013 Segment.io

#import "KISSmetricsProvider.h"
#import "KISSMetricsAPI.h"


@implementation KISSmetricsProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
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
    NSLog(@"KISSmetricsProvider initialized.");
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
    [[KISSMetricsAPI sharedAPI] identify:userId];
    [[KISSMetricsAPI sharedAPI] setProperties:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [[KISSMetricsAPI sharedAPI] recordEvent:event withProperties:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // No explicit support for screens, so we'll track an event instead.
    [self track:screenTitle properties:properties context:context];
}

@end
