// TapstreamIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"
#import <Tapstream/TSTapstream.h>


@interface SEGTapstreamIntegration : SEGAnalyticsIntegration

@property Class tapstreamClass;

- (TSEvent *)makeEvent:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options;

@end
