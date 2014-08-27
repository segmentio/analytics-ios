//
//  SEGAppsFlyerIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 8/27/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGAppsFlyerIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import <AppsFlyerTracker.h>

@implementation SEGAppsFlyerIntegration

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:[self identifier]];
}

- (instancetype)init {
  if (self = [super init]) {
    self.name = [self.class identifier];
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)validate {
  self.valid = ([self devKey] != nil && [self appId] != nil);
}

- (void)start {
  [[AppsFlyerTracker sharedTracker] setAppleAppID:[self appId]];
  [[AppsFlyerTracker sharedTracker] setAppsFlyerDevKey:[self devKey]];
  
  SEGLog(@"AppsFlyer initialized with appleAppId: %@, appsFlyerDevKey:", [self appId], [self devKey]);
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  if (userId) {
    [[AppsFlyerTracker sharedTracker] setCustomerUserID:userId];
  }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  NSNumber *revenue = [self.class extractRevenue:properties];
  [[AppsFlyerTracker sharedTracker] trackEvent:event withValue:[revenue stringValue]];
}

- (void)applicationDidBecomeActive {
  [[AppsFlyerTracker sharedTracker] trackAppLaunch];
}

#pragma mark - Private

- (NSString *)devKey {
  return self.settings[@"appsFlyerDevKey"];
}

- (NSString *)appId {
  return self.settings[@"appleAppID"];
}

+ (NSString *)identifier {
  return @"AppsFlyer";
}

@end
