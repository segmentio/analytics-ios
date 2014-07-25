// AnalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGAnalyticsIntegration.h"
#import <TRVSDictionaryWithCaseInsensitivity.h>

@implementation SEGAnalyticsIntegration

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
  return [self init];
}

- (void)start {}
- (void)stop {}

- (void)validate {
  self.valid = NO;
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@ Analytics Integration:%@>", self.name, self.settings];
}

#pragma mark - Analytics Integration Default Implementation

- (BOOL)ready {
  return (self.valid && self.initialized);
}

- (void)updateSettings:(NSDictionary *)settings {
  // Store the settings and validate them.
  self.settings = settings;
  [self validate];
  
  // If we're ready, initialize the library.
  if (self.valid) {
    [self start];
    self.initialized = YES;
  } else if (self.initialized) {
    // Initialized but no longer valid settings (i.e. this integration got turned off).
    [self stop];
  }
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {}
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {}
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {}
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {}
- (void)reset {}

- (void)applicationDidEnterBackground {}
- (void)applicationWillEnterForeground {}
- (void)applicationWillTerminate {}
- (void)applicationWillResignActive {}
- (void)applicationDidBecomeActive {}
- (void)applicationDidFinishLaunching {}

#pragma mark Class Methods

+ (NSDictionary *)map:(NSDictionary *)dictionary withMap:(NSDictionary *)map {
  NSMutableDictionary *mapped = [NSMutableDictionary dictionaryWithDictionary:dictionary];
  TRVSDictionaryWithCaseInsensitivity *dict = [[TRVSDictionaryWithCaseInsensitivity alloc] initWithDictionary:dictionary];
  for (id key in map) {
    [dict objectAndKeyForKey:key block:^(id obj, id aKey) {
      mapped[map[key]] = dict[key];
      [mapped removeObjectForKey:aKey];
    }];
  }
  
  return mapped;
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary {
  return [self extractRevenue:dictionary withKey:@"revenue"];
}

+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey {
  id revenueProperty = nil;
  
  for (NSString *key in dictionary.allKeys) {
    if ([key caseInsensitiveCompare:revenueKey] == NSOrderedSame) {
      revenueProperty = dictionary[key];
      break;
    }
  }
  
  if (revenueProperty) {
    if ([revenueProperty isKindOfClass:[NSString class]]) {
      // Format the revenue.
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
      return [formatter numberFromString:revenueProperty];
    } else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
      return revenueProperty;
    }
  }
  return nil;
}

@end
