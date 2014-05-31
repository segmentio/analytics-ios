// SegmentioIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"

extern NSString *const SEGSegmentioDidSendRequestNotification;
extern NSString *const SEGSegmentioRequestDidSucceedNotification;
extern NSString *const SEGSegmentioRequestDidFailNotification;

@interface SEGSegmentioIntegration : SEGAnalyticsIntegration

@property (nonatomic, copy) NSString *anonymousId;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) NSURL *apiURL;

- (void)flush;

@end
