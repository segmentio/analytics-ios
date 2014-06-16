//
//  SEGApptimizeIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 6/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGApptimizeIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"

#import <Apptimize/Apptimize.h>

@implementation SEGApptimizeIntegration

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
  [Apptimize startApptimizeWithApplicationKey:[self appKey]];
  
  SEGLog(@"%@Integration initialized with app key %@", [self.class identifier], [self appKey]);
}

- (void)validate {
  self.valid = ([self appKey] != nil);
}

#pragma mark - Private

- (NSString *)appKey {
  return self.settings[@"appKey"];
}


+ (NSString *)identifier {
  return @"Apptimize";
}

@end
