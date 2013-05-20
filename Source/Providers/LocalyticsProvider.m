// LocalyticsProvider.m
// Copyright 2013 Segment.io

#import "LocalyticsProvider.h"
#import "LocalyticsSession.h"


@implementation LocalyticsProvider {

}

+ (BOOL) validateEmail:(NSString *)candidate {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 

    return [emailTest evaluateWithObject:candidate];
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
    [[LocalyticsSession shared] tagEvent:event attributes:properties];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    // For enterprise only...
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
