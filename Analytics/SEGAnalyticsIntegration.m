// AnalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import "SEGAnalyticsIntegration.h"
#import <TRVSDictionaryWithCaseInsensitivity.h>
#import "SEGAnalyticsUtils.h"
#import "SEGEcommerce.h"

NSString *SEGAnalyticsIntegrationDidStart = @"io.segment.analytics.integration.did.start";

@implementation SEGAnalyticsIntegration

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration {
  return [self init];
}

- (void)start {
  [[NSNotificationCenter defaultCenter] postNotificationName:SEGAnalyticsIntegrationDidStart object:self userInfo:nil];  
  SEGLog(@"%@ started", NSStringFromClass(self.class));
}

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

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  if ([self conformsToProtocol:@protocol(SEGEcommerce)]) {
    [self trackEcommerceEvent:event properties:properties];
  }
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options {}
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options {}
- (void)reset {}

- (void)applicationDidEnterBackground {}
- (void)applicationWillEnterForeground {}
- (void)applicationWillTerminate {}
- (void)applicationWillResignActive {}
- (void)applicationDidBecomeActive {}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {}

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

+ (NSString *)extractEmail:(NSString *)userId traits:(NSDictionary *)traits {
  NSString *email = [traits objectForKey:@"email"];
  if (email) {
    return email;
  }
  if ([self stringIsValidEmail:userId]){
    return userId;
  }
  return nil;
}

+ (BOOL)stringIsValidEmail:(NSString *)checkString
{
  BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
  NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
  NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:checkString];
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

#pragma mark - Private

- (void)trackEcommerceEvent:(NSString *)event properties:(NSDictionary *)properties {
  [[self ecommercePatternSelectorMap] enumerateKeysAndObjectsUsingBlock:^(NSString *pattern, NSString *selectorName, BOOL *stop) {
    SEL selector = NSSelectorFromString(selectorName);
    if ([self event:event matchesPattern:pattern] && [self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
      [self performSelector:selector withObject:properties];
#pragma clang diagnostic pop
      return;
    }
  }];
}

- (NSTextCheckingResult *)event:(NSString *)event matchesPattern:(NSString *)pattern {
  return [[NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:NULL] firstMatchInString:event options:0 range:NSMakeRange(0, event.length)];
}

- (NSDictionary *)ecommercePatternSelectorMap {
  return @{
    @"viewed[ _]?product": @"viewedProduct:",
    @"completed[ _]?order": @"completedOrder:",
    @"added[ _]?product": @"addedProduct:",
    @"removed[ _]?product": @"removedProduct"
  };
}


@end
