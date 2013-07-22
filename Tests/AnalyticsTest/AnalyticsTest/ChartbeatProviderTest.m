//
//  ChartbeatProviderTest.m
//
//  Created by Peter Reinhardt on 5/22/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Analytics/ChartbeatProvider.h"
#import "GHUnitIOS/GHUnit.h"


@interface ChartbeatProviderTest : GHAsyncTestCase
@property(nonatomic) ChartbeatProvider *provider;
@end




@implementation ChartbeatProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [ChartbeatProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"48185", @"uid", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testChartbeatWorks
{
    [self prepare];
    
    [self.provider screen:@"Test View" properties:nil context:nil];
    
    // Just chill out to let the chartbeat stuff appear
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    [NSThread sleepForTimeInterval:1.0f];
    
    GHAssertNotNil([NSNumber numberWithInteger:1], @"1 was nil, abort");
}


@end