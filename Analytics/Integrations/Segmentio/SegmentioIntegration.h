// SegmentioIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "AnalyticsIntegration.h"

extern NSString *const SegmentioDidSendRequestNotification;
extern NSString *const SegmentioRequestDidSucceedNotification;
extern NSString *const SegmentioRequestDidFailNotification;

@interface SegmentioIntegration : AnalyticsIntegration

@property(nonatomic, copy) NSString *writeKey;
@property(nonatomic, copy) NSString *anonymousId;
@property(nonatomic, copy) NSString *userId;
@property(nonatomic, assign) NSUInteger flushAt;
@property (nonatomic, strong) NSURL *apiURL;

- (void)flush;

- (id)initWithWriteKey:(NSString *)writeKey flushAt:(NSUInteger)flushAt;

@end
