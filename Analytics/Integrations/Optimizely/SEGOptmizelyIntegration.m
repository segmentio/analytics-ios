//
//  SEGOptmizelyIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 7/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGOptmizelyIntegration.h"
#import <Optimizely/Optimizely.h>

@implementation SEGOptmizelyIntegration

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
  [Optimizely startOptimizelyWithAPIToken:self.apiToken launchOptions:nil];
  SEGLog(@"OptimizelyIntegration initialized.");
}

- (void)validate {
  self.valid = (self.apiToken != nil);
}

#pragma mark - Private

- (NSString *)apiToken {
  return self.settings[@"apiToken"];
}

+ (NSString *)identifier {
  return @"Optimizely";
}

@end
