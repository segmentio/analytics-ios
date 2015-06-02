// LocalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGLocalyticsIntegration.h"
#import <Localytics/Localytics.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"

@implementation SEGLocalyticsIntegration

+ (BOOL)validateEmail:(NSString *)candidate {
  NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSPredicate *emailTest =
      [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

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

- (void)start {
  NSString *appKey = [self.settings objectForKey:@"appKey"];

  [Localytics integrate:appKey];

  NSNumber *sessionTimeoutInterval =
      [self.settings objectForKey:@"sessionTimeoutInterval"];
  if (sessionTimeoutInterval != nil &&
      [sessionTimeoutInterval floatValue] > 0) {
    [Localytics setSessionTimeoutInterval:[sessionTimeoutInterval floatValue]];
  }

  SEGLog(@"LocalyticsIntegration initialized.");
  [super start];
}

- (void)setCustomDimensions:(NSDictionary *)dictionary {
  NSDictionary *customDimensions = self.settings[@"dimensions"];

  for (NSString *key in dictionary) {
    if ([customDimensions objectForKey:key] != nil) {
      NSString *dimension = [customDimensions objectForKey:key];
      [Localytics setValue:[dictionary objectForKey:key]
          forCustomDimension:[dimension integerValue]];
    }
  }
}

#pragma mark - Settings

- (void)validate {
  BOOL hasAppKey = [self.settings objectForKey:@"appKey"] != nil;
  self.valid = hasAppKey;
}

#pragma mark - Analytics API

- (void)identify:(NSString *)userId
          traits:(NSDictionary *)traits
         options:(NSDictionary *)options {
  if (userId) {
    [Localytics setCustomerId:userId];
  }

  // Email
  NSString *email = [traits objectForKey:@"email"];
  if (!email && [SEGLocalyticsIntegration validateEmail:userId]) {
    email = userId;
  }
  if (email) {
    [Localytics setValue:email forIdentifier:@"email"];
  }

  // Name
  NSString *name = [traits objectForKey:@"name"];
  // TODO support first name, last name?
  if (name) {
    [Localytics setValue:name forIdentifier:@"customer_name"];
  }

  [self setCustomDimensions:traits];

  // Other traits. Iterate over all the traits and set them.
  for (NSString *key in traits) {
    NSString *traitValue =
        [NSString stringWithFormat:@"%@", [traits objectForKey:key]];
    [Localytics setValue:traitValue
        forProfileAttribute:key
                  withScope:LLProfileScopeApplication];
  }
}

- (void)track:(NSString *)event
    properties:(NSDictionary *)properties
       options:(NSDictionary *)options {
  // TODO add support for value

  // Backgrounded? Restart the session to add this event.
  BOOL isBackgrounded = [[UIApplication sharedApplication] applicationState] !=
                        UIApplicationStateActive;
  if (isBackgrounded) {
    [Localytics openSession];
  }

  NSNumber *revenue = [SEGAnalyticsIntegration extractRevenue:properties];
  if (revenue) {
    [Localytics tagEvent:event
                   attributes:properties
        customerValueIncrease:revenue];
  } else {
    [Localytics tagEvent:event attributes:properties];
  }

  [self setCustomDimensions:properties];

  // Backgrounded? Close the session again after the event.
  if (isBackgrounded) {
    [Localytics closeSession];
  }
}

- (void)screen:(NSString *)screenTitle
    properties:(NSDictionary *)properties
       options:(NSDictionary *)options {
  // For enterprise only...
  [Localytics tagScreen:screenTitle];
}

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
                                              options:(NSDictionary *)options {
  [Localytics setPushToken:deviceToken];
}

- (void)flush {
  [Localytics upload];
}

#pragma mark - Callbacks for app state changes

- (void)applicationDidEnterBackground {
  [Localytics dismissCurrentInAppMessage];
  [Localytics closeSession];
  [Localytics upload];
}

- (void)applicationWillEnterForeground {
  [Localytics openSession];
  [Localytics upload];
}

- (void)applicationWillTerminate {
  [Localytics closeSession];
  [Localytics upload];
}
- (void)applicationWillResignActive {
  [Localytics dismissCurrentInAppMessage];
  [Localytics closeSession];
  [Localytics upload];
}
- (void)applicationDidBecomeActive {
  [Localytics openSession];
  [Localytics upload];
}

@end
