// CrittercismProvider.m
// Copyright 2013 Segment.io

#import "CrittercismProvider.h"
#import "Crittercism.h"

#ifdef DEBUG
#define AnalyticsDebugLog(...) NSLog(__VA_ARGS__)
#else
#define AnalyticsDebugLog(...)
#endif


@implementation CrittercismProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Crittercism";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Initialization
    NSString *appId = [self.settings objectForKey:@"appId"];
    [Crittercism enableWithAppID:appId];
    AnalyticsDebugLog(@"CrittercismProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAppId = [self.settings objectForKey:@"appId"] != nil;
    self.valid = hasAppId;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    // User ID
    [Crittercism setUsername:(NSString *)userId];

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        [Crittercism setValue:[traits objectForKey:key] forKey:key];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [Crittercism leaveBreadcrumb:event];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [Crittercism leaveBreadcrumb:screenTitle];
}


@end
