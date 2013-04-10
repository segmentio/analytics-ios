// AnalyticsTests.m
// Copyright 2013 Segment.io

#import "AnalyticsTests.h"
#import "Analytics.h"


@implementation AnalyticsTests

- (void)setUp
{
    [super setUp];
    self.analytics = [Analytics sharedAnalyticsWithSecret:@"testsecret" flushAt:1 flushAfter:10];
}

- (void)tearDown
{
    [super tearDown];
    self.analytics = nil;
}


#pragma mark - Utilities

// JSON conversion
// Date ISO formatting
// SessionId generation


#pragma mark - Track

// Track just event name
// Track event name, properties
// Track event name, properties, context


#pragma mark - Identify

// Identify just userId
// Identify just traits
// Identify userId, traits
// Identify userId, traits, context


#pragma mark - Batching

// Change flushAt to 2 and 7... check that it's batched.
// Change flustAt to 20, wait for 10 seconds after sending 5... check that it's sent in batch of 5.

@end