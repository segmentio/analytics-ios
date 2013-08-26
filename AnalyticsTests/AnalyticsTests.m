//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "SegmentioProvider.h"
#import "AnalyticsUtils.h"
#import "KWNotificationMatcher.h"

@interface SegmentioProvider (Private)
@property (nonatomic, readonly) NSMutableArray *queue;
@end

SPEC_BEGIN(AnalyticsTests)

describe(@"Analytics", ^{
    SetShowDebugLogs(YES);
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    __block SegmentioProvider *segmentio = nil;
    __block Analytics *analytics = nil;
    beforeEach(^{
        analytics = [[Analytics alloc] initWithSecret:@"testsecret"];
        segmentio = analytics.providers[@"Segment.io"];
        segmentio.flushAt = 2;
    });
    
    it(@"has a secret and 10 providers, including Segment.io", ^{
        [[analytics.secret should] equal:@"testsecret"];
        [[segmentio.secret should] equal:@"testsecret"];
        [[[analytics should] have:10] providers];
        [segmentio shouldNotBeNil];
    });
    
    it(@"Should identify", ^{
        NSString *userId = @"smile@wrinkledhippo.com";
        NSDictionary *traits = @{@"Filter": @"Tilt-shift"};
        NSDictionary *context = @{@"providers": @{@"Salesforce": @YES, @"HubSpot": @NO}};
        [analytics identify:userId traits:traits context:context];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedIdentify = (segmentio.queue)[0];
        [[queuedIdentify[@"action"] should] equal:@"identify"];
        [queuedIdentify[@"timestamp"] shouldNotBeNil];
        [queuedIdentify[@"sessionId"] shouldNotBeNil];
        [[queuedIdentify[@"userId"] should] equal:userId];
        [[queuedIdentify[@"traits"] should] equal:traits];

        // test for context object and default properties there
        [queuedIdentify[@"context"] shouldNotBeNil];
        [queuedIdentify[@"context"][@"library"] shouldNotBeNil];
        [queuedIdentify[@"context"][@"providers"] shouldNotBeNil];
        [queuedIdentify[@"context"][@"providers"][@"Olark"] shouldBeNil];
        [[queuedIdentify[@"context"][@"providers"][@"Salesforce"] should] equal:@YES];
        [[queuedIdentify[@"context"][@"providers"][@"HubSpot"] should] equal:@NO];

        [segmentio flush];

        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should track", ^{
        [[segmentio.queue should] beEmpty];
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{
            @"Filter": @"Tilt-shift",
            @"category": @"Mobile",
            @"revenue": @"70.0",
            @"value": @"50.0",
            @"label": @"gooooga"
        };
        NSDictionary *context = @{@"providers": @{@"Salesforce": @YES, @"HubSpot": @NO}};
        [analytics track:eventName properties:properties context:context];
        
        // The analytics thread does things slightly async, just need to
        // create a tiny amount of space for it to get it into the queue.
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"track"];
        [[queuedTrack[@"event"] should] equal:eventName];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [[queuedTrack[@"properties"] should] equal:properties];
        
        // test for context object and default properties there
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        [queuedTrack[@"context"][@"providers"] shouldNotBeNil];
        [queuedTrack[@"context"][@"providers"][@"Olark"] shouldBeNil];
        [[queuedTrack[@"context"][@"providers"][@"Salesforce"] should] equal:@YES];
        [[queuedTrack[@"context"][@"providers"][@"HubSpot"] should] equal:@NO];
        
        // wait for 200 from servers
        [segmentio flush];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
});

SPEC_END