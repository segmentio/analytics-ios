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

@interface Analytics (Private)
@property (nonatomic, strong) NSDictionary *cachedSettings;
@end

SPEC_BEGIN(AnalyticsTests)

describe(@"Analytics", ^{
    SetShowDebugLogs(YES);
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    __block SegmentioProvider *segmentio = nil;
    __block Analytics *analytics = nil;
    beforeEach(^{
        analytics = [[Analytics alloc] initWithSecret:@"testsecret"];
        analytics.cachedSettings = $jsonLoadsData([NSData dataWithContentsOfURL:
                                                   [[NSBundle bundleForClass:[self class]]
                                                    URLForResource:@"settings" withExtension:@"json"]]);
        segmentio = analytics.providers[@"Segment.io"];
        segmentio.flushAt = 2;
    });
    
    it(@"has a secret, cached settings and 10 providers, including Segment.io", ^{
        [[analytics.cachedSettings shouldNot] beEmpty];
        [[analytics.secret should] equal:@"testsecret"];
        [[segmentio.secret should] equal:@"testsecret"];
        [[[analytics should] have:10] providers];
        [segmentio shouldNotBeNil];
    });
    
    it(@"Refreshes settings from server when reset", ^{
        [[analytics.cachedSettings shouldNot] beEmpty];
        [[analytics valueForKey:@"settingsRequest"] shouldBeNil];
        
        [analytics reset];
        [analytics identify:@"smile@wrinkledhippo.com"];
        
        // Verify reset causes cached settings to be cleared
        [[analytics.cachedSettings should] beEmpty];
        [[segmentio.queue should] beEmpty];
        
        // Verify a request is being sent to retrieve cached settings from server
        [[analytics valueForKey:@"settingsRequest"] shouldNotBeNil];
        
        // TODO: The following line fails, however the request gets sent and response
        // does get received and cachedSettings is therefore eventually not empty.
        // However for some reason async testing seems to be broken when we are
        // waiting on some kind of network response. shouldNotEventually seems to block
        // the network activity somehow. We should either figure out a workaround for this
        // or make a decision to mock the network response (or do both, a better idea)
//        [[expectFutureValue(analytics.cachedSettings) shouldNotEventually] beEmpty];
//        [[segmentio.queue should] have:1];
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
    
    it(@"Should gracefully handle nil userId", ^{
        [analytics identify:nil traits:nil context:nil];
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        NSDictionary *queuedIdentify = (segmentio.queue)[0];
        [[queuedIdentify[@"action"] should] equal:@"identify"];
        [queuedIdentify[@"timestamp"] shouldNotBeNil];
        [queuedIdentify[@"sessionId"] shouldNotBeNil];
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