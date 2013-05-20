// LocalyticsProvider.m
// Copyright 2013 Segment.io

#import "LocalyticsProvider.h"
#import "LocalyticsSession.h"


@implementation LocalyticsProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Localytics";
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *appKey = [self.settings objectForKey:@"appKey"];
    [[LocalyticsSession shared] startSession:appKey];
    NSLog(@"LocalyticsProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasAppKey;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [[LocalyticsSession shared] tagEvent:event attributes:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:screenTitle];
}


#pragma mark - Callbacks for app state changes

- (void)applicationDidEnterBackground
{
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillEnterForeground
{
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}

- (void)applicationWillTerminate
{
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}
- (void)applicationWillResignActive
{
    [[LocalyticsSession shared] close];
    [[LocalyticsSession shared] upload];
}
- (void)applicationDidBecomeActive
{
    [[LocalyticsSession shared] resume];
    [[LocalyticsSession shared] upload];
}


@end
