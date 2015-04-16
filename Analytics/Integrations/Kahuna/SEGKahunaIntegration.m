// KahunaIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGKahunaIntegration.h"
#import "KahunaAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGKahunaIntegration

#pragma mark - Initialization

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:@"Kahuna"];
}

- (id)init {
  if (self = [super init]) {
    self.name = @"Kahuna";
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  [KahunaAnalytics launchWithKey:[self.settings objectForKey:@"apiKey"]];
  [super start];
}


#pragma mark - Settings

- (void)validate {
  self.valid = [self.settings objectForKey:@"apiKey"] != nil;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_USERNAME andValue:userId];
  NSString *email = [self.class extractEmail:userId traits:traits];
  if (email) {
    [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_EMAIL andValue:email];
  }
  [KahunaAnalytics setUserAttributes:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  NSNumber *revenue = [self.class extractRevenue:properties];
  if (revenue == nil){
    [KahunaAnalytics trackEvent:event];
  } else {
    // Although not documented, Kahuna wants revenue in cents
    NSNumber *quantity = [properties objectForKey:@"quantity"] ?: @1;
    [KahunaAnalytics trackEvent:event withCount:[quantity longValue] andValue:[revenue longValue] * 100];
  }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
  // Track the screen view as an event.
  [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
  [KahunaAnalytics setDeviceToken:deviceToken];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  UIApplication *application = [UIApplication sharedApplication];
  [KahunaAnalytics handleNotification:[[notification userInfo] valueForKey:
                                       UIApplicationLaunchOptionsRemoteNotificationKey] withApplicationState:[application applicationState]];
}

- (void)reset {
  [KahunaAnalytics logout];
}

@end