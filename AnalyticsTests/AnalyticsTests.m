//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "SegmentioProvider.h"

@interface SegmentioProvider (Private)
@property (nonatomic, readonly) NSMutableArray *queue;
@end

SPEC_BEGIN(AnalyticsTests)

describe(@"Analytics", ^{
    __block SegmentioProvider *segmentio = nil;
    __block Analytics *analytics = nil;
    beforeAll(^{
        [Analytics initializeWithSecret:@"testsecret"];
        [[Analytics sharedAnalytics] debug:YES];
        analytics = [Analytics sharedAnalytics];
        for (id<AnalyticsProvider> provider in [[Analytics sharedAnalytics] providers])
            if ([provider isKindOfClass:[SegmentioProvider class]])
                segmentio = provider;
        segmentio.flushAt = 2;
    });
    
    it(@"Should have a secret and 10 providers", ^{
        [[analytics.secret should] equal:@"testsecret"];
        [[segmentio.secret should] equal:@"testsecret"];
                [[@(analytics.providers.count) should] equal:@10];
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
        
        // track an event so that we can see that's working in each analytics interface
//        NSString *eventName = @"Purchased an iPad 5";
//        NSDictionary *properties = @{@"Filter": @"Tilt-shift", @"category": @"Mobile", @"revenue": @"70.0", @"value": @"50.0", @"label": @"gooooga"};
//        [analytics track:eventName properties:properties context:context];
        
        // wait for 200 from servers
        // TODO: Make segment.io provider send notification for success and failure
//        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:35.0];
    });
    
    it(@"Should track", ^{
        return;
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
//        [self waitForStatus:kGHUnitWaitStatusSuccess timeout:35.0];
    });
    
    it(@"Should reset", ^{
        return;
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{@"Filter": @"Tilt-shift", @"category": @"Mobile", @"revenue": @"70.0", @"value": @"50.0", @"label": @"gooooga"};
        NSDictionary *providers = @{@"Salesforce": @YES, @"HubSpot": @NO};
        NSDictionary *context = @{@"providers": providers};
        
        [analytics track:eventName properties:properties context:context];
        [analytics reset];
        [analytics track:eventName properties:properties context:context];
        // TODO: Actually impement the tests here!
    });
});

SPEC_END