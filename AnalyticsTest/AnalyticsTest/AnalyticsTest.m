//
//  SegmentioTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Analytics.h"
#import "ProviderManager.h"
#import "Segmentio.h"
#import "GHUnit.h"



// get access to private members
@interface Analytics (Test)
@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) ProviderManager *providerManager;
@end

@interface Segmentio (Test)
@property(nonatomic, strong) NSMutableArray *queue;
@end

@interface ProviderManager (Test)
@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) NSMutableArray *providersArray;
@end


@interface AnalyticsTest : GHAsyncTestCase
@property(nonatomic) Analytics *analytics;
@end


@implementation AnalyticsTest

- (void)onAPISuccess
{
    [self notify:kGHUnitWaitStatusSuccess];
}

- (void)onAPIFail
{
    [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testURLConnection)];
}

- (void)setUp
{
    [super setUp];
    self.analytics = [Analytics withSecret:@"testsecret"];
    [Segmentio sharedInstance].flushAfter = 2;
    [Segmentio sharedInstance].delegate = self;
    [[Segmentio sharedInstance] reset];
}

- (void)tearDown
{
    [super tearDown];
    self.analytics = nil;
}

#pragma mark - Core

- (void)testSecret
{
    GHAssertEqualObjects(self.analytics.secret, @"testsecret", @"Analytics secret was not set to testsecret.");
    
    ProviderManager *providerManager = self.analytics.providerManager;
    GHAssertEqualObjects(providerManager.secret, @"testsecret", @"ProviderManager secret was not set to testsecret.");
}

- (void)testSegmentio
{
    // Let an async thread initialize the Segmentio provider.
    GHAssertNotNil([Segmentio sharedInstance], @"Segmentio instance should be available (async) immediately.");
    GHAssertEqualObjects([Segmentio sharedInstance].secret, @"testsecret", @"Segmentio secret was not set to testsecret");
}


#pragma mark - API Methods

- (void)testTrack
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"Mobile", @"category", @"70.0", @"revenue", @"50.0", @"value", @"gooooga", @"label", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @YES, @"Salesforce", @NO, @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.analytics track:eventName properties:properties context:context];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    Segmentio *segmentio = [Segmentio sharedInstance];
    GHAssertTrue(segmentio.queue.count == 1, @"Event was not enqueued.");
    
    NSDictionary *queuedTrack = [segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
    GHAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
    
    GHAssertEqualObjects([queuedTrack objectForKey:@"properties"], properties, @"Properties did not match properties passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"properties"], @"Event didn't have properties, but properties were passed in.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Event did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Event did not have a context.library, but it should.");
    
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"providers"], @"Event did not have a context.providers, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Salesforce"], @YES, @"Event did not have a context.providers.Salesforce, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"HubSpot"], @NO, @"Event did not have a context.providers.HubSpot, but it should.");
    GHAssertNil([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Olark"], @"Event had a context.providers.Olark, but it wasn't passed in.");
    
    // wait for 200 from servers
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:35.0];
}

- (void)testIdentify
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @YES, @"Salesforce", @NO, @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.analytics identify:userId traits:traits context:context];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    Segmentio *segmentio = [Segmentio sharedInstance];
    GHAssertTrue(segmentio.queue.count == 1, @"Identify was not enqueued.");
    
    NSDictionary *queuedTrack = [segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"identify", @"Identify did not have action: \"identify\".");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Identify did not have a timestamp, but it should.");
    GHAssertNotNil([queuedTrack objectForKey:@"sessionId"], @"Identify did not have a sessionId, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"userId"], userId, @"Identify did not have the right userId.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"traits"], traits, @"Identify did not have the right traits.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Identify did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Identify did not have a context.library, but it should.");
    
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"providers"], @"Identify did not have a context.providers, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Salesforce"], @YES, @"Identify did not have a context.providers.Salesforce, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"HubSpot"], @NO, @"Identify did not have a context.providers.HubSpot, but it should.");
    GHAssertNil([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Olark"], @"Identify had a context.providers.Olark, but it wasn't passed in.");
    
    // track an event so that we can see that's working in each analytics interface
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"Mobile", @"category", @"70.0", @"revenue", @"50.0", @"value", @"gooooga", @"label", nil];
    [self.analytics track:eventName properties:properties context:context];
    
    // wait for 200 from servers
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:35.0];
}

- (void)testReset
{
    
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"Mobile", @"category", @"70.0", @"revenue", @"50.0", @"value", @"gooooga", @"label", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @YES, @"Salesforce", @NO, @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    
    [self.analytics track:eventName properties:properties context:context];
    
    [self.analytics reset];
    
    [self.analytics track:eventName properties:properties context:context];
}

@end