// AnalyticsUtilsTests.m
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <XCTest/XCTest.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalyticsIntegration.h"
#import <Expecta/Expecta.h>

@interface SEGUtilsTests : XCTestCase

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation SEGUtilsTests

- (void)setUp {
    [super setUp];
    
    self.queue = dispatch_queue_create_specific("io.segment.test.queue", DISPATCH_QUEUE_SERIAL);
}

- (void)tearDown {
    [super tearDown];
}

- (void)testRunsSyncWhenDispatchingFromQueue {
        dispatch_sync(self.queue, ^{
            __block BOOL blockRan = NO;
            
            dispatch_specific_sync(self.queue, ^{ blockRan = YES; });
            XCTAssertTrue(blockRan);
            
            blockRan = NO;
            dispatch_specific_async(self.queue, ^{ blockRan = YES; });
            XCTAssertTrue(blockRan);
        });
}

- (void)testCanRunAsyncWhenDispatchingElsewhereThanQueue {
    __block BOOL blockRan = NO;
    dispatch_specific_async(self.queue, ^{ blockRan = YES; });
    XCTAssertFalse(blockRan);
    EXP_expect(blockRan).will.beTruthy();
}

- (void)testCanSyncWhenDispatchingElsewhereThanQueue {
    __block BOOL blockRan = NO;
    dispatch_specific_sync(self.queue, ^{ blockRan = YES; });
    XCTAssertTrue(blockRan);
}

- (void)testMappingKeys {
        NSDictionary *dictionary = @{
            @"firstName": @"travis",
            @"lastName": @"jeffery",
            @"mobile": @"555 555 5555"
        };
        NSDictionary *map = @{
            @"firstName": @"$first_name",
            @"lastName": @"$last_name",
            @"phone": @"$phone"
        };
        NSDictionary *mapped = [SEGAnalyticsIntegration map:dictionary withMap:map];

    XCTAssertEqualObjects(@"travis", mapped[@"$first_name"]);
    XCTAssertEqualObjects(@"jeffery", mapped[@"$last_name"]);
    XCTAssertEqualObjects(@"555 555 5555", mapped[@"mobile"]);
    XCTAssertNil(mapped[@"$phone"]);
    XCTAssertNil(mapped[@"phone"]);
}

- (void)testExtractingRevenueNumber {
        NSDictionary *dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @34.56
        };
    XCTAssertEqualObjects(@34.56, [SEGAnalyticsIntegration extractRevenue:dictionary]);
}

- (void)testExtractingRevenueString {
        NSDictionary *dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @"34.56"
        };
    XCTAssertEqualObjects(@34.56, [SEGAnalyticsIntegration extractRevenue:dictionary]);
}

- (void)testGracefulFailToExtractRevenue {
        NSDictionary *dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @"3asdf4.56"
        };
    XCTAssertNil([SEGAnalyticsIntegration extractRevenue:dictionary]);

}

@end
