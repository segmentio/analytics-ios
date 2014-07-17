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
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
#ifdef DEBUG
  [Optimizely enableEditor];
#endif
  
  [Optimizely startOptimizelyWithAPIToken:self.apiToken launchOptions:nil];
  SEGLog(@"OptimizelyIntegration initialized.");
}

- (void)validate {
  self.valid = (self.apiToken != nil);
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options {
  [Optimizely trackEvent:event];
}

#pragma mark - Private

- (NSString *)apiToken {
  return self.settings[@"apiToken"];
}

+ (NSString *)identifier {
  return @"Optimizely";
}

@end
