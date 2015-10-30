// MixpanelIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

// Import the public header files
#import "SEGMixpanelIntegration.h"
// Import the Mixpanel SDK
#import <Mixpanel/Mixpanel.h>
// Import the SEGAnalytics class
#import "SEGAnalytics.h"
// Import some utility methods
#import "SEGAnalyticsUtils.h"

// Implementation for our integration in SEGMixpanel.h
// See SEGAnalyticsIntegration.h to see which methods should be overriden for what purpose.
@implementation SEGMixpanelIntegration

#pragma mark - Initialization

// The load method is automatically invoked when the class is added to the Objective-C Runtime.
// @see https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class/index.html#//apple_ref/occ/clm/NSObject/load
+ (void)load
{
    // We use this to register an integration with the right key/identifier, which should be the same as in the Segment metadata.
    [SEGAnalytics registerIntegration:self withIdentifier:@"Mixpanel"];
}

// The initialize method is called once when the integrations are loaded (but not initialized).
- (id)init
{
    if (self = [super init]) {
        // Same as the Mixpanel identifier/key in the Segment metadata.
        self.name = @"Mixpanel";
        // Invalid and uninitialized by default.
        self.valid = NO;
        self.initialized = NO;
        // Use the real Mixpanel class for normal operation.
        self.mixpanelClass = [Mixpanel class];
    }
    return self;
}

// Validate any settings provided to the integration, such as required keys.
- (void)validate
{
    // For example, Mixpanel requires at least the `token` to be set.
    BOOL hasToken = [self.settings objectForKey:@"token"] != nil;
    // Set valid to YES or NO depending on the whether all the settings are avilable or not.
    self.valid = hasToken;
}

// The start method is called to initialize an integration, after it has been validated.
- (void)start
{
    // Grab any required and optional settings.
    NSString *token = [self.settings objectForKey:@"token"];

    // Initialize the Mixpanel SDK.
    [self.mixpanelClass sharedInstanceWithToken:token];
    SEGLog(@"[Mixpanel sharedInstanceWithToken:%@]", token);

    // Call the super implementation, which will notify observers that Mixpanel has been initialized.
    [super start];
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // Ensure that the userID is set and valid (i.e. a non-empty string).
    if (userId != nil && [userId length] != 0) {
        [[self.mixpanelClass sharedInstance] identify:userId];
        SEGLog(@"[[Mixpanel sharedInstance] identify:%@]", userId);
    }

    // Map the traits to special mixpanel properties.
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                                          @"$first_name", @"firstName",
                                          @"$last_name", @"lastName",
                                          @"$created", @"createdAt",
                                          @"$last_seen", @"lastSeen",
                                          @"$email", @"email",
                                          @"$name", @"name",
                                          @"$username", @"username",
                                          @"$phone", @"phone", nil];

    if ([self setAllTraitsByDefault]) {
        NSDictionary *mappedTraits = [SEGAnalyticsIntegration map:traits withMap:map];

        // Register the mapped traits.
        [[self.mixpanelClass sharedInstance] registerSuperProperties:mappedTraits];
        SEGLog(@"[[Mixpanel sharedInstance] registerSuperProperties:%@]", mappedTraits);

        // Mixpanel also has a people API that works seperately, so we set the traits for it as well.
        if ([self peopleEnabled]) {
            // You'll notice that we could also have done: [self.mixpanelClass.sharedInstance.people set:mappedTraits];
            // Using methods instead of properties directly lets us mock them in tests, which is why we use the syntax below.
            [[[self.mixpanelClass sharedInstance] people] set:mappedTraits];
            SEGLog(@"[[[Mixpanel sharedInstance] people] set:%@]", mappedTraits);
        }

        return;
    }

    NSDictionary *mixpanelOptions = [self mixpanelOptions:options];
    if (!mixpanelOptions) {
        return;
    }

    NSArray *superProperties = [mixpanelOptions objectForKey:@"superProperties"];
    NSMutableDictionary *superPropertyTraits = [NSMutableDictionary dictionaryWithCapacity:superProperties.count];
    for (NSString *superProperty in superProperties) {
        superPropertyTraits[superProperty] = traits[superProperty];
    }
    NSDictionary *mappedSuperProperties = [SEGAnalyticsIntegration map:superPropertyTraits withMap:map];
    [[self.mixpanelClass sharedInstance] registerSuperProperties:mappedSuperProperties];
    SEGLog(@"[[Mixpanel sharedInstance] registerSuperProperties:%@]", mappedSuperProperties);

    if ([self peopleEnabled]) {
        NSArray *peopleProperties = [mixpanelOptions objectForKey:@"peopleProperties"];
        NSMutableDictionary *peoplePropertyTraits = [NSMutableDictionary dictionaryWithCapacity:peopleProperties.count];
        for (NSString *peopleProperty in peopleProperties) {
            peoplePropertyTraits[peopleProperty] = traits[peopleProperty];
        }
        NSDictionary *mappedPeopleProperties = [SEGAnalyticsIntegration map:peoplePropertyTraits withMap:map];
        [[[self.mixpanelClass sharedInstance] people] set:mappedPeopleProperties];
        SEGLog(@"[[[Mixpanel sharedInstance] people] set:%@]", mappedSuperProperties);
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // Track the raw event.
    [[self.mixpanelClass sharedInstance] track:event properties:properties];

    // Don't go any further if Mixpanel people is disabled.
    if (![self peopleEnabled]) {
        return;
    }

    // Extract the revenue from the properties passed in to us.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    // Check if there was a revenue.
    if (revenue) {
        [[[self.mixpanelClass sharedInstance] people] trackCharge:revenue];
        SEGLog(@"[[[Mixpanel sharedInstance] people] trackCharge:%@]", revenue);
    }

    // Mixpanel has the ability keep a running 'count' events. So we check if this is an event
    // that should be incremented (by checking the settings).
    if ([self eventShouldIncrement:event]) {
        [[[self.mixpanelClass sharedInstance] people] increment:event by:@1];
        SEGLog(@"[[[Mixpanel sharedInstance] people] increment:%@ by:1]", event);

        NSString *lastEvent = [NSString stringWithFormat:@"Last %@", event];
        NSDate *lastDate = [NSDate date];
        [[[self.mixpanelClass sharedInstance] people] set:lastEvent to:lastDate];
        SEGLog(@"[[[Mixpanel sharedInstance] people] set:%@ to:%@]", lastEvent, lastDate);
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    if ([(NSNumber *)[self.settings objectForKey:@"trackAllPages"] boolValue]) {
        [self realScreen:screenTitle properties:properties options:options];
    } else if ([(NSNumber *)[self.settings objectForKey:@"trackNamedPages"] boolValue] && screenTitle) {
        [self realScreen:screenTitle properties:properties options:options];
    } else if ([(NSNumber *)[self.settings objectForKey:@"trackCategorizedPages"] boolValue] && properties[@"category"]) {
        [self realScreen:screenTitle properties:properties options:options];
    }
}

- (void)realScreen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (void)alias:(NSString *)newId options:(NSDictionary *)options
{
    // Instead of using our own anonymousId, we use Mixpanel's own generated Id.
    NSString *distinctId = [[self.mixpanelClass sharedInstance] distinctId];
    [[self.mixpanelClass sharedInstance] createAlias:newId forDistinctID:distinctId];
    SEGLog(@"[[Mixpanel sharedInstance] createAlias:%@ forDistinctID:%@]", newId, distinctId);
}

// Invoked when the device is registered with a push token.
// Mixpanel uses this to send push messages to the device, so forward it to Mixpanel.
- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options
{
    [[[self.mixpanelClass sharedInstance] people] addPushDeviceToken:deviceToken];
    SEGLog(@"[[[[Mixpanel sharedInstance] people] addPushDeviceToken:%@]", deviceToken);
}

// An internal utility method that checks the settings to see if this event should be incremented in Mixpanel.
- (BOOL)eventShouldIncrement:(NSString *)event
{
    NSArray *increments = [self.settings objectForKey:@"increments"];
    for (NSString *increment in increments) {
        if ([event caseInsensitiveCompare:increment] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

// Return true the project has the People feature enabled.
- (BOOL)peopleEnabled
{
    return [(NSNumber *)[self.settings objectForKey:@"people"] boolValue];
}

// Return true if all traits should be set by default.
- (BOOL)setAllTraitsByDefault
{
    return [(NSNumber *)[self.settings objectForKey:@"setAllTraitsByDefault"] boolValue];
}

// Return true if all traits should be set by default.
- (NSDictionary *)mixpanelOptions:(NSDictionary *)options
{
    NSDictionary *integrations = [options objectForKey:@"integrations"];
    if (integrations) {
        return [integrations objectForKey:@"Mixpanel"];
    }
    return nil;
}

- (void)reset
{
    [self flush];

    [[self.mixpanelClass sharedInstance] reset];
    SEGLog(@"[[Mixpanel sharedInstance] reset]");
}

- (void)flush
{
    [[self.mixpanelClass sharedInstance] flush];
    SEGLog(@"[[Mixpanel sharedInstance] flush]");
}

// Mixpanel doesn't implement the group method so we don't implement it!

@end
