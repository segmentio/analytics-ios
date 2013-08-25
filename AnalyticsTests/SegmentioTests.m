//
//  SegmentioTests.m
//  Analytics
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <CLToolkit/Testing.h>
#import "AnalyticsUtils.h"
#import "SegmentioProvider.h"

@interface SegmentioProvider (Private)
@property (nonatomic, readonly) NSMutableArray *queue;
@end

SPEC_BEGIN(SegmentioTests)

describe(@"Segment.io", ^{
    __block SegmentioProvider *segmentio = nil;
    __block NSNotificationCenter *nc;
    beforeAll(^{
        SetShowDebugLogs(YES);
        segmentio = [[SegmentioProvider alloc] initWithSecret:@"testsecret" flushAt:2 flushAfter:2];
        nc = [NSNotificationCenter defaultCenter];
    });
    beforeEach(^{
        [segmentio reset];
    });
    
    it(@"Should have a sessionID", ^{
        [segmentio.sessionId shouldNotBeNil];
    });
    
    it(@"Should queue when not full", ^{
        [[segmentio.queue should] beEmpty];
        [segmentio.userId shouldBeNil];
        NSString *userId = @"smile@wrinkledhippo.com";
        [segmentio identify:userId traits:nil context:nil];
        [[segmentio.userId shouldEventually] beNonNil];
        [[segmentio.queue shouldEventually] have:1];
    });
    
    it(@"Should flush when full", ^{
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{@"Filter": @"Tilt-shift"};
        [segmentio track:eventName properties:properties context:nil];
        [segmentio track:eventName properties:properties context:nil];
        [[segmentio.queue should] beEmpty];
        [[segmentio.queue shouldEventually] have:2];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
});

SPEC_END