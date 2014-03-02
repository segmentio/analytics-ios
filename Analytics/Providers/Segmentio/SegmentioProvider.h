// SegmentioProvider.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "AnalyticsProvider.h"

extern NSString *const SegmentioDidSendRequestNotification;
extern NSString *const SegmentioRequestDidSucceedNotification;
extern NSString *const SegmentioRequestDidFailNotification;

@interface SegmentioProvider : AnalyticsProvider <AnalyticsProvider>

@property(nonatomic, strong) NSString *writeKey;
@property(nonatomic, strong) NSString *anonymousId;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, assign) NSUInteger flushAt;

- (NSString *)getAnonymousId;
- (void)flush;

- (id)initWithWriteKey:(NSString *)writeKey flushAt:(NSUInteger)flushAt;

@end
