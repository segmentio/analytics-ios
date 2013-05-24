// MixpanelProvider.m
// Copyright 2013 Segment.io

#import "MixpanelProvider.h"

#import "Mixpanel.h"


@implementation MixpanelProvider {

}

#pragma mark - Initialization

+ (instancetype)withNothing
{
    return [[self alloc] initWithNothing];
}

- (id)initWithNothing
{
    if (self = [self init]) {
        self.name = @"Mixpanel";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *token = [self.settings objectForKey:@"token"];
    [Mixpanel sharedInstanceWithToken:token];
    NSLog(@"MixpanelProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasToken = [self.settings objectForKey:@"token"] != nil;
    self.valid = hasToken;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    [[Mixpanel sharedInstance] identify:userId];
    [[Mixpanel sharedInstance] registerSuperProperties:traits];

    if ([self.settings objectForKey:@"people"]) {
        [[Mixpanel sharedInstance].people set:traits];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Track the raw event.
    [[Mixpanel sharedInstance] track:event properties:properties];

    // If revenue is included and People is enabled, trackCharge to Mixpanel.
    NSNumber *revenue = [Provider extractRevenue:properties];
    if (revenue && [self.settings objectForKey:@"people"]) {
        [[Mixpanel sharedInstance].people trackCharge:revenue];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // Track the screen view as an event.
    [self track:screenTitle properties:properties context:context];
}

@end
