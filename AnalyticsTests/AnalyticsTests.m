//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Copyright (c) 2014 Segment.io. All rights reserved.
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
        analytics = [[Analytics alloc] initWithWriteKey:@"k5l6rrye0hsv566zwuk7"];
        analytics.cachedSettings = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:
                                                   [[NSBundle bundleForClass:[self class]]
                                                    URLForResource:@"settings" withExtension:@"json"]] options:NSJSONReadingMutableContainers error:NULL];
        segmentio = analytics.providers[@"Segment.io"];
        segmentio.flushAt = 2;
    });
    
    it(@"has a secret, cached settings and 10 providers, including Segment.io", ^{
        [[analytics.cachedSettings shouldNot] beEmpty];
        [[analytics.writeKey should] equal:@"k5l6rrye0hsv566zwuk7"];
        [[segmentio.writeKey should] equal:@"k5l6rrye0hsv566zwuk7"];
        [[[analytics should] have:10] providers];
        [segmentio shouldNotBeNil];
    });
    
    it(@"Should identify", ^{
        NSString *userId = @"smile@wrinkledhippo.com";
        NSDictionary *traits = @{@"Filter": @"Tilt-shift", @"HasFriends": @YES, @"FriendCount" : @233 };
        NSDictionary *options = @{@"Salesforce": @YES, @"HubSpot": @NO};
        [analytics identify:userId traits:traits options:options];
        
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedAction = (segmentio.queue)[0];
        [[queuedAction[@"action"] should] equal:@"identify"];
        [queuedAction[@"timestamp"] shouldNotBeNil];
        [queuedAction[@"anonymousId"] shouldNotBeNil];
        [[queuedAction[@"userId"] should] equal:userId];
        [[queuedAction[@"traits"] should] equal:traits];

        // test for integrations options
        [queuedAction[@"integrations"] shouldNotBeNil];
        [queuedAction[@"integrations"][@"Olark"] shouldBeNil];
        [[queuedAction[@"integrations"][@"Salesforce"] should] equal:@YES];
        [[queuedAction[@"integrations"][@"HubSpot"] should] equal:@NO];

        [segmentio flush];

        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
    });
    
    it(@"Should gracefully handle nil userId", ^{
         NSDictionary *traits = @{@"Filter": @"Tilt-shift", @"HasFriends": @YES, @"FriendCount" : @233 };
        [analytics identify:nil traits:traits options:nil];
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        NSDictionary *queuedIdentify = (segmentio.queue)[0];
        [[queuedIdentify[@"action"] should] equal:@"identify"];
        [queuedIdentify[@"timestamp"] shouldNotBeNil];
        [queuedIdentify[@"anonymousId"] shouldNotBeNil];
        [segmentio flush];
        
        [[nc shouldEventually] receiveNotification:SegmentioDidSendRequestNotification];
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
        NSDictionary *options = @{@"Salesforce": @YES, @"HubSpot": @NO};
        [analytics track:eventName properties:properties options:options];
        
        // The analytics thread does things slightly async, just need to
        // create a tiny amount of space for it to get it into the queue.
        [[expectFutureValue(@(segmentio.queue.count)) shouldEventually] equal:@1];
        
        NSDictionary *queuedAction = segmentio.queue[0];
        [[queuedAction[@"action"] should] equal:@"track"];
        [[queuedAction[@"event"] should] equal:eventName];
        [queuedAction[@"timestamp"] shouldNotBeNil];
        [[queuedAction[@"properties"] should] equal:properties];
        
        // test for context object and default properties there
        [queuedAction[@"integrations"] shouldNotBeNil];
        [queuedAction[@"integrations"][@"Olark"] shouldBeNil];
        [[queuedAction[@"integrations"][@"Salesforce"] should] equal:@YES];
        [[queuedAction[@"integrations"][@"HubSpot"] should] equal:@NO];
        
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
        NSDictionary *options = @{@"Mixpanel": @NO};
        [analytics track:eventName properties:properties options:options];
    });
    
});

SPEC_END