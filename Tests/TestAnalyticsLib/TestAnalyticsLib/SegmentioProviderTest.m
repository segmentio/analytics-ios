//
//  SegmentioProviderTest.m
//  TestAnalyticsLib
//
//  Created by Peter Reinhardt on 7/22/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Analytics/Segmentio.h"
#import "GHUnitIOS/GHUnit.h"


// get access to private members
@interface Segmentio (Test)
@property(nonatomic, strong) NSMutableArray *queue;
@end


@interface SegmentioTest : GHAsyncTestCase
@property(nonatomic) Segmentio *segmentio;
@end




@implementation SegmentioTest

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
    self.segmentio = [Segmentio withSecret:@"testsecret" flushAt:2 flushAfter:2 delegate:self];
    [Segmentio sharedInstance].flushAt = 2;
    [Segmentio sharedInstance].flushAfter = 2;
    [Segmentio sharedInstance].delegate = self;
    [[Segmentio sharedInstance] reset];
}

- (void)tearDown
{
    [super tearDown];
    self.segmentio = nil;
}


#pragma mark - Utilities

// JSON conversion
// Date ISO formatting
// SessionId generation
- (void)testSessionId
{
    NSString *sessionId1 = [self.segmentio getSessionId];
    GHAssertNotNil(sessionId1, @"SessionID was nil.");
    
    [self.segmentio reset];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    NSString *sessionId2 = [self.segmentio getSessionId];
    GHAssertNotEqualStrings(sessionId1, sessionId2, @"SessionID's were equal after reset.");
}


#pragma mark - Track

// Track just event name
- (void)testTrack
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPhone 6";
    [self.segmentio track:eventName properties:nil context:nil];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Event was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
    GHAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name that was passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
    GHAssertNil([queuedTrack objectForKey:@"properties"], @"Event had properties, but no properties were passed.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Event did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Event did not have a context.library, but it should.");
    
    // send a second event, wait for 200 from servers
    [self.segmentio track:eventName properties:nil context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}


// Track event name, properties
- (void)testTrackProperties
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    [self.segmentio track:eventName properties:properties context:nil];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Event was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
    GHAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
    
    GHAssertEqualObjects([queuedTrack objectForKey:@"properties"], properties, @"Properties did not match properties passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"properties"], @"Event didn't have properties, but properties were passed in.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Event did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Event did not have a context.library, but it should.");
    
    // send a second event, wait for 200 from servers
    [self.segmentio track:eventName properties:properties context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

- (void)testTrackContext
{
    
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Mixpanel", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.segmentio track:eventName properties:properties context:context];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Event was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
    GHAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
    
    GHAssertEqualObjects([queuedTrack objectForKey:@"properties"], properties, @"Properties did not match properties passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"properties"], @"Event didn't have properties, but properties were passed in.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Event did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Event did not have a context.library, but it should.");
    
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"providers"], @"Event did not have a context.providers, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Salesforce"], @"true", @"Event did not have a context.providers.Salesforce, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Mixpanel"], @"false", @"Event did not have a context.providers.Mixpanel, but it should.");
    GHAssertNil([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"KISSmetrics"], @"Event had a context.providers.KISSmetrics, but it wasn't passed in.");
    
    
    // send a second event, wait for 200 from servers
    [self.segmentio track:eventName properties:properties context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}


#pragma mark - Identify

// Identify just userId
- (void)testIdentify
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSString *userId = @"smile@wrinkledhippo.com";
    [self.segmentio identify:userId traits:nil context:nil];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Identify was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"identify", @"Identify did not have action: \"identify\".");
    GHAssertEqualObjects([queuedTrack objectForKey:@"userId"], userId, @"Identify userId did not match userId that was passed in.");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Identify did not have a timestamp, but it should.");
    GHAssertNotNil([queuedTrack objectForKey:@"sessionId"], @"Identify did not have a sessionId, but it should.");
    GHAssertNil([queuedTrack objectForKey:@"traits"], @"Identify had traits, but no traits were passed.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Event did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Event did not have a context.library, but it should.");
    
    // send a second event, wait for 200 from servers
    [self.segmentio identify:userId traits:nil context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

// Identify just traits
- (void)testTraits
{
    // Call prepare to setup the asynchronous action.
    // This helps in cases where the action is synchronous and the
    // action occurs before the wait is actually called.
    [self prepare];
    
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    [self.segmentio identify:nil traits:traits context:nil];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Identify was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"identify", @"Identify did not have action: \"identify\".");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Identify did not have a timestamp, but it should.");
    GHAssertNotNil([queuedTrack objectForKey:@"sessionId"], @"Identify did not have a sessionId, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"traits"], traits, @"Identify did not have the right traits.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Identify did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Identify did not have a context.library, but it should.");
    
    // send a second event, wait for 200 from servers
    [self.segmentio identify:nil traits:traits context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
// Identify userId, traits, context
- (void)testIdentifyContext
{
    
    [self prepare];
    
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Mixpanel", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.segmentio identify:nil traits:traits context:context];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Identify was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"identify", @"Identify did not have action: \"identify\".");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Identify did not have a timestamp, but it should.");
    GHAssertNotNil([queuedTrack objectForKey:@"sessionId"], @"Identify did not have a sessionId, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"traits"], traits, @"Identify did not have the right traits.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Identify did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Identify did not have a context.library, but it should.");
    
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"providers"], @"Identify did not have a context.providers, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Salesforce"], @"true", @"Identify did not have a context.providers.Salesforce, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Mixpanel"], @"false", @"Identify did not have a context.providers.Mixpanel, but it should.");
    GHAssertNil([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"KISSmetrics"], @"Identify had a context.providers.KISSmetrics, but it wasn't passed in.");
    
    
    // send a second event, wait for 200 from servers
    [self.segmentio identify:nil traits:traits context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}

#pragma mark - Alias


// Identify just traits
- (void)testAlias
{
    [self prepare];
    
    NSString *from = [self.segmentio getSessionId];
    NSString *to = @"wallowinghippo@wahoooo.net";
    [self.segmentio alias:from to:to context:nil];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Alias was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"alias", @"Alias did not have action: \"alias\".");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Alias did not have a timestamp, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"from"], from, @"Alias did not have a from, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"to"], to, @"Alias did not have a to, but it should.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Alias did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Alias did not have a context.library, but it should.");
    
    // send a second event, wait for 200 from servers
    [self.segmentio alias:from to:to context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}
// Identify userId, traits, context
- (void)testAliasContext
{
    [self prepare];
    
    NSString *from = [self.segmentio getSessionId];
    NSString *to = @"wallowinghippo@wahoooo.net";
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Mixpanel", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.segmentio alias:from to:to context:context];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:0.1f];
    
    GHAssertTrue(self.segmentio.queue.count == 1, @"Alias was not enqueued.");
    
    NSDictionary *queuedTrack = [self.segmentio.queue objectAtIndex:0];
    GHAssertEqualObjects([queuedTrack objectForKey:@"action"], @"alias", @"Alias did not have action: \"alias\".");
    GHAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Alias did not have a timestamp, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"from"], from, @"Alias did not have a from, but it should.");
    GHAssertEqualObjects([queuedTrack objectForKey:@"to"], to, @"Alias did not have a to, but it should.");
    
    // test for context object and default properties there
    GHAssertNotNil([queuedTrack objectForKey:@"context"], @"Alias did not have a context, but it should.");
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"library"], @"Alias did not have a context.library, but it should.");
    
    GHAssertNotNil([[queuedTrack objectForKey:@"context"] objectForKey:@"providers"], @"Alias did not have a context.providers, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Salesforce"], @"true", @"Alias did not have a context.providers.Salesforce, but it should.");
    GHAssertEqualObjects([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"Mixpanel"], @"false", @"Alias did not have a context.providers.Mixpanel, but it should.");
    GHAssertNil([[[queuedTrack objectForKey:@"context"] objectForKey:@"providers"] objectForKey:@"KISSmetrics"], @"Alias had a context.providers.KISSmetrics, but it wasn't passed in.");
    
    
    // send a second event, wait for 200 from servers
    [self.segmentio alias:from to:to context:nil];
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
}


#pragma mark - Queueing, Batching and Sending

// Check that it's batched
- (void)testFlustAt
{
    [self prepare];
    
    NSString *userId = @"smile@wrinkledhippo.com";
    [self.segmentio identify:userId traits:nil context:nil];
    [NSThread sleepForTimeInterval:0.1f];
    GHAssertTrue(self.segmentio.queue.count == 1, @"Identify was not enqueued.");
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    [self.segmentio track:eventName properties:properties context:nil];
    [NSThread sleepForTimeInterval:3.0f];
    GHAssertTrue(self.segmentio.queue.count != 2, @"Event queue was not flushed in batch.");
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    
}
// Change flustAt to 20, wait for 10 seconds after sending 5... check that it's sent in batch of 5.
- (void)testFlushAfter
{
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    [self.segmentio track:eventName properties:properties context:nil];
    [NSThread sleepForTimeInterval:0.1f];
    GHAssertTrue(self.segmentio.queue.count == 1, @"Event was not enqueued.");
    
    // Wait for more than the timeout
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:15.0];
}

@end
