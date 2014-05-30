// LocalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGLocalyticsIntegration.h"
#import <LocalyticsSession.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGLocalyticsIntegration

+ (BOOL) validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    return [emailTest evaluateWithObject:candidate];
}

+ (void)load {
    [SEGAnalytics registerIntegration:self withIdentifier:@"Localytics"];
}

#pragma mark - Initialization

- (id)init {
    if (self = [super init]) {
        self.name = @"Localytics";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    NSString *appKey = [self.settings objectForKey:@"appKey"];
    [[LocalyticsSession sharedLocalyticsSession] startSession:appKey];

    NSNumber *sessionTimeoutInterval = [self.settings objectForKey:@"sessionTimeoutInterval"];
    if (sessionTimeoutInterval != nil && [sessionTimeoutInterval floatValue] > 0) {
        [LocalyticsSession sharedLocalyticsSession].sessionTimeoutInterval = [sessionTimeoutInterval floatValue];
    }
    SEGLog(@"LocalyticsIntegration initialized.");
}


#pragma mark - Settings

- (void)validate
{
    BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
    self.valid = hasAppKey;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    if (userId) {
        [[LocalyticsSession sharedLocalyticsSession] setCustomerId:userId];
    }

    // Email
    NSString *email = [traits objectForKey:@"email"];
    if (!email && [SEGLocalyticsIntegration validateEmail:userId]) {
        email = userId;
    }
    if (email) {
        [[LocalyticsSession sharedLocalyticsSession] setCustomerEmail:email];
    }

    // Name
    NSString *name = [traits objectForKey:@"name"];
    // TODO support first name, last name?
    if (name) {
        [[LocalyticsSession sharedLocalyticsSession] setCustomerName:name];
    }

    // Other traits. Iterate over all the traits and set them.
    for (NSString *key in traits) {
        NSString* traitValue = [NSString stringWithFormat:@"%@", [traits objectForKey:key]];
        [[LocalyticsSession sharedLocalyticsSession] setValueForIdentifier:key value:traitValue];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // TODO add support for dimensions
    // TODO add support for value

    // Backgrounded? Restart the session to add this event.
    BOOL isBackgrounded = [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive;
    if (isBackgrounded) {
        [[LocalyticsSession sharedLocalyticsSession] resume];
    }

    [[LocalyticsSession sharedLocalyticsSession] tagEvent:event attributes:properties];

    // Backgrounded? Close the session again after the event.
    if (isBackgrounded) {
        [[LocalyticsSession sharedLocalyticsSession] close];
    }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    // For enterprise only...
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:screenTitle];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [[LocalyticsSession sharedLocalyticsSession] setPushToken:deviceToken];
}


#pragma mark - Callbacks for app state changes

- (void)applicationDidEnterBackground
{
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationWillEnterForeground
{
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void)applicationWillTerminate
{
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}
- (void)applicationWillResignActive
{
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}
- (void)applicationDidBecomeActive
{
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}


@end
