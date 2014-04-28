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
#import "Reachability.h"

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
    
    [Reachability reachabilityWithHostname:@"www.google.com"];
    
    beforeEach(^{
        analytics = [[Analytics alloc] initWithSecret:@"k5l6rrye0hsv566zwuk7"];
        analytics.cachedSettings = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:
                                                   [[NSBundle bundleForClass:[self class]]
                                                    URLForResource:@"settings" withExtension:@"json"]] options:NSJSONReadingMutableContainers error:NULL];
        segmentio = analytics.providers[@"Segment.io"];
        segmentio.flushAt = 2;
    });
    
    it(@"has a secret, cached settings and 10 providers, including Segment.io", ^{
        [[analytics.cachedSettings shouldNot] beEmpty];
        [[analytics.secret should] equal:@"k5l6rrye0hsv566zwuk7"];
        [[segmentio.secret should] equal:@"k5l6rrye0hsv566zwuk7"];
        [[[analytics should] have:11] providers];
        [segmentio shouldNotBeNil];
    });
    
    it(@"Should identify", ^{
        NSString *userId = @"smile@wrinkledhippo.com";
        NSDictionary *traits = @{@"Filter": @"Tilt-shift", @"HasFriends": @YES, @"FriendCount" : @233 };
        NSDictionary *options = @{@"providers": @{@"Salesforce": @YES, @"HubSpot": @NO}};
        [analytics identify:userId traits:traits options:options];
        
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
    
    it(@"Should handle nil userId with traits", ^{
        [analytics identify:nil traits:@{} options:nil];
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        NSDictionary *queuedIdentify = (segmentio.queue)[0];
        [[queuedIdentify[@"action"] should] equal:@"identify"];
        [queuedIdentify[@"timestamp"] shouldNotBeNil];
        [queuedIdentify[@"sessionId"] shouldNotBeNil];
        [segmentio flush];
        
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"should do nothing when identifying without traits", ^{
        [analytics identify:nil];
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@0];
        [segmentio flush];
    });
    
    it(@"Should track", ^{
        [[segmentio.queue should] beEmpty];
        NSString *eventName = @"Purchased an iMac";
        NSDictionary *properties = @{
            @"Filter": @"Tilt-shift",
            @"category": @"Mobile",
            @"revenue": @"70.0",
            @"value": @"50.0",
            @"label": @"gooooga"
        };
        NSDictionary *options = @{@"providers": @{@"Salesforce": @YES, @"HubSpot": @NO}};
        [analytics track:eventName properties:properties options:options];
        
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
    
    it(@"Should track according to providers options", ^{
        [[segmentio.queue should] beEmpty];
        NSString *eventName = @"Purchased an iMac but not Mixpanel";
        NSDictionary *properties = @{
                                     @"Filter": @"Tilt-shift",
                                     @"category": @"Mobile",
                                     @"revenue": @"70.0",
                                     @"value": @"50.0",
                                     @"label": @"gooooga"
                                     };
        NSDictionary *options = @{@"providers": @{@"Mixpanel": @NO}};
        [analytics track:eventName properties:properties options:options];
    });
    
});

SPEC_END