// FlurryIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "AnalyticsIntegration.h"


@interface FlurryIntegration : AnalyticsIntegration

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, copy) NSDictionary *settings;

@end
