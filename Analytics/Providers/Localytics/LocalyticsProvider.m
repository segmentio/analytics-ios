// LocalyticsProvider.m
// Copyright 2013 Segment.io

#import "LocalyticsProvider.h"
#import "LocalyticsSession.h"
#import "AnalyticsUtils.h"
#import "Analytics.h"

@implementation LocalyticsProvider

+ (BOOL) validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 

    return [emailTest evaluateWithObject:candidate];
}

+ (void)load {
    [Analytics registerProvider:self withIdentifier:@"Localytics"];
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
    SOLog(@"LocalyticsProvider initialized.");
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
    if (userId) {
        [[LocalyticsSession sharedLocalyticsSession] setCustomerId:userId];
    }
    
    // Email
    NSString *email = [traits objectForKey:@"email"];
    if (!email && [LocalyticsProvider validateEmail:userId]) {
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
        [[LocalyticsSession sharedLocalyticsSession] setValueForIdentifier:key value:[traits objectForKey:key]];
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // TODO add support for dimensions
    // TODO add support for value
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:event attributes:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // For enterprise only...
    [[LocalyticsSession sharedLocalyticsSession] tagScreen:screenTitle];
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
