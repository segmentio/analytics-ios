//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "SegmentioProvider.h"

SPEC_BEGIN(AnalyticsTests)

describe(@"Analytics", ^{
    __block SegmentioProvider *segmentio = nil;
    __block Analytics *analytics = nil;
    beforeAll(^{
        [Analytics initializeWithSecret:@"testsecret"];
        analytics = [Analytics sharedAnalytics];
        for (id<AnalyticsProvider> provider in [[Analytics sharedAnalytics] providers])
            if ([provider isKindOfClass:[SegmentioProvider class]])
                segmentio = provider;
        segmentio.flushAt = 2;
    });
    
    it(@"should have a secret", ^{
        [[analytics.secret should] equal:@"testsecret"];
        [[segmentio.secret should] equal:@"testsecret"];
    });
    
    it(@"should have 10 providers", ^{
        [[@(analytics.providers.count) should] equal:@10];
    });
});

SPEC_END