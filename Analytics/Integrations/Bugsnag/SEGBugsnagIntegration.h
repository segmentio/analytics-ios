// BugsnagIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"
#import <Bugsnag/Bugsnag.h>


@interface SEGBugsnagIntegration : SEGAnalyticsIntegration

@property Class bugsnagClass;

@end
