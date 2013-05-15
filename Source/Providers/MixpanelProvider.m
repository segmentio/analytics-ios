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
        self.enabled = YES;
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Re-validate
    [self validate];

    // Check that all states are go
    if (self.enabled && self.valid && !self.initialized) {
        NSString *token = [self.settings objectForKey:@"token"];
        [Mixpanel sharedInstanceWithToken:token];
        self.initialized = YES;
        NSLog(@"MixpanelProvider initialized.");
    }
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasPeople = [self.settings objectForKey:@"people"] != nil;
    BOOL hasToken  = [self.settings objectForKey:@"token"] != nil;
    self.valid = hasPeople && hasToken;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel identify:userId];
    [mixpanel registerSuperProperties:traits];

    if ([self.settings objectForKey:@"people"]) {
        [mixpanel.people set:traits];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    
    // Track the raw event.
    [mixpanel track:event properties:properties];

    // If People is enabled, track any "charges" to that API as well.
    if ([self.settings objectForKey:@"people"]) {
        
        // Extract the "revenue" event property and trackCharge if there is revenue.
        NSString *revenueProperty = [properties objectForKey:@"revenue"];
        if (revenueProperty) {
            
            // Format the revenue.
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *revenue = [formatter numberFromString:revenueProperty];
            
            // Track the charge.
            [mixpanel.people trackCharge:revenue];
        }
    }
}

- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context
{
    // NOTE: Mixpanel automatically handles alias on iOS
}


@end
