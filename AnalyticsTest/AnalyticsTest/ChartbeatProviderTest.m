//
//  ChartbeatProviderTest.m
//
//  Created by Peter Reinhardt on 5/22/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "ChartbeatProvider.h"
#import "GHUnit.h"


@interface ChartbeatProviderTest : GHAsyncTestCase
@property(nonatomic) ChartbeatProvider *provider;
@end




@implementation ChartbeatProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [ChartbeatProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"48185", @"accountId", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testChartbeat
{
    // Just chill out to let the chartbeat stuff appear
    [NSThread sleepForTimeInterval:10.0f];
    [NSThread sleepForTimeInterval:10.0f];
    [NSThread sleepForTimeInterval:10.0f];
}


@end