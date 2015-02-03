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
  NSString *appKey = [self.settings objectForKey:@"appKey"];
  [KahunaAnalytics startWithKey:appKey];
  
  [super start];
}


#pragma mark - Settings

- (void)validate
{
  BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
  self.valid = hasAppKey;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_USERNAME andValue:userId];
  NSString *email = [self extractEmail:userId traits:traits];
  if (email) {
    [KahunaAnalytics setUserCredentialsWithKey:KAHUNA_CREDENTIAL_EMAIL andValue:email];
  }
  [KahunaAnalytics setUserAttributes:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  [KahunaAnalytics trackEvent:event withCount:2 andValue:500];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
  // Track the screen view as an event.
  [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
  [KahunaAnalytics setDeviceToken:deviceToken];
}

@end