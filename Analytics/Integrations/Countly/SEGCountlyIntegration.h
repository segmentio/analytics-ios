// CountlyIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"
#import <Countly.h>


@interface SEGCountlyIntegration : SEGAnalyticsIntegration

@property Countly *countly;

@end
