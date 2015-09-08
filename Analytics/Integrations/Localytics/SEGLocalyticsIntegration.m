// LocalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGLocalyticsIntegration.h"
#import <Localytics/Localytics.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"


@implementation SEGLocalyticsIntegration

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Localytics"];
}

#pragma mark - Initialization

- (id)init
{
    if (self = [super init]) {
        self.name = @"Localytics";
        self.valid = NO;
        self.initialized = NO;
        self.localyticsClass = [Localytics class];
    }
    return self;
}

- (void)start
{
    NSString *appKey = [self.settings objectForKey:@"appKey"];

    [self.localyticsClass integrate:appKey];

    NSNumber *sessionTimeoutInterval =
        [self.settings objectForKey:@"sessionTimeoutInterval"];
    if (sessionTimeoutInterval != nil &&
        [sessionTimeoutInterval floatValue] > 0) {
        [self.localyticsClass setSessionTimeoutInterval:[sessionTimeoutInterval floatValue]];
    }

    SEGLog(@"LocalyticsIntegration initialized.");
    [super start];
}

- (void)setCustomDimensions:(NSDictionary *)dictionary
{
    NSDictionary *customDimensions = self.settings[@"dimensions"];

    for (NSString *key in dictionary) {
        if ([customDimensions objectForKey:key] != nil) {
            NSString *dimension = [customDimensions objectForKey:key];
            [self.localyticsClass setValue:[dictionary objectForKey:key]
                        forCustomDimension:[dimension integerValue]];
        }
    }
}

#pragma mark - Settings

- (void)validate
{
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasAppKey;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId
          traits:(NSDictionary *)traits
         options:(NSDictionary *)options
{
    if (userId) {
        [self.localyticsClass setCustomerId:userId];
    }

    NSString *email = [traits objectForKey:@"email"];
    if (email) {
        [self.localyticsClass setValue:email forIdentifier:@"email"];
    }

    NSString *name = [traits objectForKey:@"name"];
    // TODO support first name, last name?
    if (name) {
        [self.localyticsClass setValue:name forIdentifier:@"customer_name"];
    }

    [self setCustomDimensions:traits];

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        NSString *traitValue =
            [NSString stringWithFormat:@"%@", [traits objectForKey:key]];
        [self.localyticsClass setValue:traitValue
                   forProfileAttribute:key
                             withScope:LLProfileScopeApplication];
    }
}

- (void)track:(NSString *)event
   properties:(NSDictionary *)properties
      options:(NSDictionary *)options
{
    // TODO add support for value

    // Backgrounded? Restart the session to add this event.
    BOOL isBackgrounded = [[UIApplication sharedApplication] applicationState] !=
        UIApplicationStateActive;
    if (isBackgrounded) {
        [self.localyticsClass openSession];
    }

    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue) {
        [self.localyticsClass tagEvent:event
                            attributes:properties
                 customerValueIncrease:@([revenue intValue] * 100)];
    } else {
        [self.localyticsClass tagEvent:event attributes:properties];
    }

    [self setCustomDimensions:properties];

    // Backgrounded? Close the session again after the event.
    if (isBackgrounded) {
        [self.localyticsClass closeSession];
    }
}

- (void)screen:(NSString *)screenTitle
    properties:(NSDictionary *)properties
       options:(NSDictionary *)options
{
    [self.localyticsClass tagScreen:screenTitle];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                              options:(NSDictionary *)options
{
    [self.localyticsClass setPushToken:deviceToken];
}

- (void)flush
{
    [self.localyticsClass upload];
}

#pragma mark - Callbacks for app state changes

- (void)applicationDidEnterBackground
{
    [self.localyticsClass dismissCurrentInAppMessage];
    [self.localyticsClass closeSession];
    [self.localyticsClass upload];
}

- (void)applicationWillEnterForeground
{
    [self.localyticsClass openSession];
    [self.localyticsClass upload];
}

- (void)applicationWillTerminate
{
    [self.localyticsClass closeSession];
    [self.localyticsClass upload];
}
- (void)applicationWillResignActive
{
    [self.localyticsClass dismissCurrentInAppMessage];
    [self.localyticsClass closeSession];
    [self.localyticsClass upload];
}
- (void)applicationDidBecomeActive
{
    [self.localyticsClass openSession];
    [self.localyticsClass upload];
}

@end
