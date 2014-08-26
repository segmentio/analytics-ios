//
//  SEGTestFlightIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 2014-08-18.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGTestFlightIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import <TestFlightSDK/TestFlight.h>

@implementation SEGTestFlightIntegration

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
  self.valid = ([self appToken] != nil);
}

- (void)start {
  [TestFlight takeOff:[self appToken]];
  
  SEGLog(@"TestFlightIntegration initialized with appToken: %@", [self appToken]);
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options {
  if (userId != nil) {
    [TestFlight addCustomEnvironmentInformation:userId forKey:@"user_id"];
  }

  [traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [TestFlight addCustomEnvironmentInformation:obj forKey:key];
  }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  TFLog(@"%@", event);
  [TestFlight passCheckpoint:event];
}

- (NSString *)appToken {
  return self.settings[@"appToken"];
}

+ (NSString *)identifier {
  return @"TestFlight";
}

@end
