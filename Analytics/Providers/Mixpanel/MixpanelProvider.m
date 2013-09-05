// MixpanelProvider.m
// Copyright 2013 Segment.io

#import "MixpanelProvider.h"
#import "Mixpanel.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation MixpanelProvider

#pragma mark - Initialization

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Mixpanel"];
}

- (id)init {
    if (self = [super init]) {
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
    SOLog(@"MixpanelProvider initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasToken = [self.settings objectForKey:@"token"] != nil;
    self.valid = hasToken;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context {
    [[Mixpanel sharedInstance] identify:userId];

    // Map the traits to special mixpanel keywords.
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
        @"$first_name", @"firstName",
        @"$last_name",  @"lastName",
        @"$created",    @"created",
        @"$last_seen",  @"lastSeen",
        @"$email",      @"email",
        @"$name",       @"name",
        @"$username",   @"username",
        @"$phone",      @"phone",  nil];
    NSDictionary *mappedTraits = [AnalyticsProvider map:traits withMap:map];
    [[Mixpanel sharedInstance] registerSuperProperties:mappedTraits];

    if ([self.settings objectForKey:@"people"]) {
        [[Mixpanel sharedInstance].people set:mappedTraits];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context {
    // Track the raw event.
    [[Mixpanel sharedInstance] track:event properties:properties];

    // If revenue is included and People is enabled, trackCharge to Mixpanel.
    NSNumber *revenue = [AnalyticsProvider extractRevenue:properties];
    if (revenue && [self.settings objectForKey:@"people"]) {
        [[Mixpanel sharedInstance].people trackCharge:revenue];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context {
    // Track the screen view as an event.
    [self track:screenTitle properties:properties context:context];
}

- (void)registerPushDeviceToken:(NSData *)deviceToken {
    [[[Mixpanel sharedInstance] people] addPushDeviceToken:deviceToken];
}

@end
