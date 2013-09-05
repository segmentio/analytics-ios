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
    SetShowDebugLogs(YES);
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    __block SegmentioProvider *segmentio = nil;
    beforeAll(^{
        segmentio = [[SegmentioProvider alloc] initWithSecret:@"testsecret" flushAt:2 flushAfter:2];
    });
    beforeEach(^{
        [segmentio reset];
    });
    
    it(@"Should have a sessionID", ^{
        [segmentio.sessionId shouldNotBeNil];
    });
    
    it(@"Should track", ^{
        NSString *eventName = @"Purchased an iPhone 6";
        [segmentio track:eventName properties:nil context:nil];

        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];

        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"track"];
        [[queuedTrack[@"event"] should] equal:eventName];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [queuedTrack[@"properties"] shouldBeNil];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio track:eventName properties:nil context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should track with properties", ^{
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{@"Filter": @"Tilt-shift"};
        [segmentio track:eventName properties:properties context:nil];

        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"track"];
        [[queuedTrack[@"event"] should] equal:eventName];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        
        [[queuedTrack[@"properties"] should] equal:properties];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio track:eventName properties:properties context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should track with context", ^{
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{@"Filter": @"Tilt-shift"};
        NSDictionary *context = @{@"providers": @{@"Salesforce": @"true", @"Mixpanel": @"false"}};
        [segmentio track:eventName properties:properties context:context];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        
        [[queuedTrack[@"action"] should] equal:@"track"];
        [[queuedTrack[@"event"] should] equal:eventName];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        
        [[queuedTrack[@"properties"] should] equal:properties];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        [queuedTrack[@"context"][@"providers"] shouldNotBeNil];
        [[queuedTrack[@"context"][@"providers"][@"Salesforce"] should] equal:@"true"];
        [[queuedTrack[@"context"][@"providers"][@"Mixpanel"] should] equal:@"false"];
        [queuedTrack[@"context"][@"providers"][@"KISSmetrics"] shouldBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio track:eventName properties:properties context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should identify", ^{
        NSString *userId = @"smile@wrinkledhippo.com";
        [segmentio identify:userId traits:nil context:nil];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"identify"];
        [[queuedTrack[@"userId"] should] equal:userId];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [queuedTrack[@"sessionId"] shouldNotBeNil];
        [queuedTrack[@"traits"] shouldBeNil];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        [segmentio identify:userId traits:nil context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should identify with traits", ^{
        NSDictionary *traits = @{@"Filter": @"Tilt-shift"};
        [segmentio identify:nil traits:traits context:nil];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"identify"];
        [queuedTrack[@"userId"] shouldBeNil];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [queuedTrack[@"sessionId"] shouldNotBeNil];
        [[queuedTrack[@"traits"] should] equal:traits];

        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        [segmentio identify:nil traits:traits context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should identify with context", ^{
        NSDictionary *traits = @{@"Filter": @"Tilt-shift"};
        NSDictionary *context = @{@"providers": @{@"Salesforce": @"true", @"Mixpanel": @"false"}};
        [segmentio identify:nil traits:traits context:context];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        [[queuedTrack[@"action"] should] equal:@"identify"];
        [queuedTrack[@"userId"] shouldBeNil];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [queuedTrack[@"sessionId"] shouldNotBeNil];
        [[queuedTrack[@"traits"] should] equal:traits];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        [queuedTrack[@"context"][@"providers"] shouldNotBeNil];
        [[queuedTrack[@"context"][@"providers"][@"Salesforce"] should] equal:@"true"];
        [[queuedTrack[@"context"][@"providers"][@"Mixpanel"] should] equal:@"false"];
        [queuedTrack[@"context"][@"providers"][@"KISSmetrics"] shouldBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio identify:nil traits:traits context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should alias", ^{
        NSString *from = [segmentio getSessionId];
        NSString *to = @"wallowinghippo@wahoooo.net";
        [segmentio alias:from to:to context:nil];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        
        [[queuedTrack[@"action"] should] equal:@"alias"];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [[queuedTrack[@"from"] should] equal:from];
        [[queuedTrack[@"to"] should] equal:to];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio alias:from to:to context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should alias with context", ^{
        NSString *from = [segmentio getSessionId];
        NSString *to = @"wallowinghippo@wahoooo.net";
        NSDictionary *context = @{@"providers": @{@"Salesforce": @"true", @"Mixpanel": @"false"}};
        [segmentio alias:from to:to context:context];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        
        NSDictionary *queuedTrack = segmentio.queue[0];
        
        [[queuedTrack[@"action"] should] equal:@"alias"];
        [queuedTrack[@"timestamp"] shouldNotBeNil];
        [[queuedTrack[@"from"] should] equal:from];
        [[queuedTrack[@"to"] should] equal:to];
        
        // test for context object and default properties there
        [queuedTrack[@"context"] shouldNotBeNil];
        [queuedTrack[@"context"][@"library"] shouldNotBeNil];
        
        [queuedTrack[@"context"][@"providers"] shouldNotBeNil];
        [[queuedTrack[@"context"][@"providers"][@"Salesforce"] should] equal:@"true"];
        [[queuedTrack[@"context"][@"providers"][@"Mixpanel"] should] equal:@"false"];
        [queuedTrack[@"context"][@"providers"][@"KISSmetrics"] shouldBeNil];
        
        // send a second event, wait for 200 from servers
        [segmentio alias:from to:to context:nil];
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should queue when not full", ^{
        [[segmentio.queue should] beEmpty];
        [segmentio.userId shouldBeNil];
        NSString *userId = @"smile@wrinkledhippo.com";
        [segmentio identify:userId traits:nil context:nil];
        [[segmentio.userId shouldEventually] beNonNil];
        [[segmentio.queue shouldEventually] have:1];
        [[nc shouldNotEventually] receiveNotification:SegmentioDidSendRequestNotification];
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
    
    it(@"Should reset", ^{
        NSString *eventName = @"Purchased an iPad 5";
        NSDictionary *properties = @{@"Filter": @"Tilt-shift", @"category": @"Mobile", @"revenue": @"70.0", @"value": @"50.0", @"label": @"gooooga"};
        NSDictionary *context = @{@"providers": @{@"Salesforce": @YES, @"HubSpot": @NO}};
        
        [segmentio track:eventName properties:properties context:context];
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        [segmentio reset];
        [[segmentio.queue should] beEmpty];
        [[nc shouldNotEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
});

SPEC_END