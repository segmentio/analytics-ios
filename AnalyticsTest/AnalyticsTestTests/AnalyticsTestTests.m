//
//  AnalyticsTestTests.m
//  AnalyticsTestTests
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AnalyticsTestTests.h"
#import "Analytics.h"



// get access to private members
@interface Analytics (Test)
@property(nonatomic, strong) NSMutableArray *queue;
@end


@interface AnalyticsTestTests ()
@property(nonatomic) Analytics *analytics;
@end




@implementation AnalyticsTestTests

- (void)setUp
{
    [super setUp];
    self.analytics = [Analytics sharedAnalyticsWithSecret:@"testsecret" flushAt:2 flushAfter:10];
    [self.analytics reset];
}

- (void)tearDown
{
    [super tearDown];
    self.analytics = nil;
}


#pragma mark - Utilities

// JSON conversion
// Date ISO formatting
// SessionId generation


#pragma mark - Track

// Track just event name
- (void)testTrack
{
    NSString *eventName = @"Purchased an iPhone 6";
    [self.analytics track:eventName];
    
    // The analytics thread does things slightly async, just need to
    // create a tiny amount of space for it to get it into the queue.
    [NSThread sleepForTimeInterval:1.0f];
    
    STAssertTrue(self.analytics.queue.count == 1, @"Event was not enqueued.");
    
    NSDictionary *queuedTrack = [self.analytics.queue objectAtIndex:0];
    STAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
    STAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name that was passed in.");
    STAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
    STAssertNil([queuedTrack objectForKey:@"properties"], @"Event had properties, but no properties were passed.");
    
    
    // TODO
    // test for context object and default properties there
}


 // Track event name, properties
 - (void)testTrackProperties
 {
     NSString *eventName = @"Purchased an iPad 5";
     NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
     [self.analytics track:eventName properties:properties];
     
     // The analytics thread does things slightly async, just need to
     // create a tiny amount of space for it to get it into the queue.
     [NSThread sleepForTimeInterval:1.0f];
     
     STAssertTrue(self.analytics.queue.count == 1, @"Event was not enqueued.");
     
     NSDictionary *queuedTrack = [self.analytics.queue objectAtIndex:0];
     STAssertEqualObjects([queuedTrack objectForKey:@"action"], @"track", @"Event did not have action: \"track\".");
     STAssertEqualObjects([queuedTrack objectForKey:@"event"], eventName, @"Event name did not match event name passed in.");
     STAssertNotNil([queuedTrack objectForKey:@"timestamp"], @"Event did not have a timestamp, but it should.");
     
     STAssertEqualObjects([queuedTrack objectForKey:@"properties"], properties, @"Properties did not match properties passed in.");
     STAssertNotNil([queuedTrack objectForKey:@"properties"], @"Event didn't have properties, but properties were passed in.");
     
     
     // TODO
     // test for context object and default properties there
 }


#pragma mark - Identify

// Identify just userId
// Identify just traits
// Identify userId, traits
// Identify userId, traits, context


#pragma mark - Batching

// Change flushAt to 2 and 7... check that it's batched.
// Change flustAt to 20, wait for 10 seconds after sending 5... check that it's sent in batch of 5.

@end
