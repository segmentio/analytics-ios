//
//  SEGTaplytics.m
//  Analytics
//
//  Created by Travis Jeffery on 6/4/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGTaplyticsIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"

#import <Taplytics.h>

@implementation SEGTaplyticsIntegration

+ (void)load {
  [SEGAnalytics registerIntegration:self withIdentifier:[self identifier]];
}

- (id)init {
  if (self = [super init]) {
    self.name = [self.class identifier];
    self.valid = NO;
    self.initialized = NO;
  }
  return self;
}

- (void)start {
  [Taplytics startTaplyticsAPIKey:[self apiKey]];
  
  SEGLog(@"TapstreamIntegration initialized with api key %@", [self apiKey]);
}

- (void)validate {
  self.valid = ([self apiKey] != nil);
}

#pragma mark - Private

- (NSString *)apiKey {
  return self.settings[@"apiKey"];
}


+ (NSString *)identifier {
  return @"Taplytics";
}

@end
