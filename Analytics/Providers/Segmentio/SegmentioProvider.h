// SegmentioProvider.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>
#import "AnalyticsProvider.h"

extern NSString *const SegmentioDidSendRequestNotification;
extern NSString *const SegmentioRequestDidSucceedNotification;
extern NSString *const SegmentioRequestDidFailNotification;

@interface SegmentioProvider : AnalyticsProvider <AnalyticsProvider>

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *sessionId;
@property(nonatomic, assign) NSUInteger flushAt;
@property(nonatomic, assign) NSUInteger flushAfter;



// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options;
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options;

// Utilities
// ---------

- (NSString *)getSessionId;
- (void)flush;
- (void)reset;

// Initialization
// --------------

- (id)initWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter;

@end
