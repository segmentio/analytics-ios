//
//  SEGOptmizelyIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 7/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGOptimizelyIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"
#import <Optimizely-iOS-SDK/Optimizely.h>

@implementation SEGOptimizelyIntegration

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:self.identifier];
}

- (id)init {
  if (self = [super init]) {
    self.name = self.class.identifier;
    self.valid = YES;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  SEGLog(@"%@Integration initialized.", self.class.identifier);
}

- (void)validate {
  self.valid = YES;
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  [Optimizely trackEvent:event];
}

#pragma mark - Private

+ (NSString *)identifier {
  return @"Optimizely";
}

@end
