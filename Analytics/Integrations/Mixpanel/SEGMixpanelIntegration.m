// MixpanelIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGMixpanelIntegration.h"
#import <Mixpanel.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGMixpanelIntegration

#pragma mark - Initialization

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:@"Mixpanel"];
}

- (id)init {
  if (self = [super init]) {
    self.name = @"Mixpanel";
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  NSString *token = [self.settings objectForKey:@"token"];
  [Mixpanel sharedInstanceWithToken:token];
  
  [super start];
}


#pragma mark - Settings

- (void)validate
{
  BOOL hasToken = [self.settings objectForKey:@"token"] != nil;
  self.valid = hasToken;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  if (userId != nil && [userId length] != 0)
    [[Mixpanel sharedInstance] identify:userId];
  
  // Map the traits to special mixpanel keywords.
  NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"$first_name", @"firstName",
                       @"$last_name",  @"lastName",
                       @"$created",    @"createdAt",
                       @"$last_seen",  @"lastSeen",
                       @"$email",      @"email",
                       @"$name",       @"name",
                       @"$username",   @"username",
                       @"$phone",      @"phone",  nil];
  
  NSDictionary *mappedTraits = [SEGAnalyticsIntegration map:traits withMap:map];
  
  [[Mixpanel sharedInstance] registerSuperProperties:mappedTraits];
  
  if ([(NSNumber *)[self.settings objectForKey:@"people"] boolValue]) {
    [[Mixpanel sharedInstance].people set:mappedTraits];
  }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  // Only track the event if it isn't blocked
  if (![self eventIsBlocked:event]) {
    // Track the raw event.
    [[Mixpanel sharedInstance] track:event properties:properties];
    
    // If revenue is included and People is enabled, trackCharge to Mixpanel.
    NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
    if (revenue && [(NSNumber *)[self.settings objectForKey:@"people"] boolValue]) {
      [[Mixpanel sharedInstance].people trackCharge:revenue];
    }
  }
  
  // If people is enabled we may want to increment this event in people
  if ([self eventShouldIncrement:event]) {
    [[Mixpanel sharedInstance].people increment:event by:@1];
    NSString *lastEvent = [NSString stringWithFormat:@"Last %@", event];
    [[Mixpanel sharedInstance].people set:lastEvent to:[NSDate date]];
  }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {
  // Track the screen view as an event.
  [self track:SEGEventNameForScreenTitle(screenTitle) properties:properties options:options];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options {
  [[[Mixpanel sharedInstance] people] addPushDeviceToken:deviceToken];
}

- (BOOL)eventShouldIncrement:(NSString *)event {
  NSArray *increments = [self.settings objectForKey:@"increments"];
  for (NSString *increment in increments) {
    if ([event caseInsensitiveCompare:increment] == NSOrderedSame) {
      return YES;
    }
  }
  return NO;
}

- (BOOL)eventIsBlocked:(NSString *)event {
  NSArray *blocked = [self.settings objectForKey:@"blockedEvents"];
  for (NSString *block in blocked) {
    if ([event caseInsensitiveCompare:block] == NSOrderedSame) {
      return YES;
    }
  }
  return NO;
}

- (void)reset {
  [[Mixpanel sharedInstance] flush];
  [[Mixpanel sharedInstance] reset];
}

@end
