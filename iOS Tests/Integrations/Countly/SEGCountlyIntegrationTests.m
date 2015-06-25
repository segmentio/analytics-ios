//
//  SEGCountlyIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-24.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGCountlyIntegration.h"


#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGCountlyIntegrationTests : XCTestCase

@property SEGCountlyIntegration *integration;
@property id countlyMock;

@end


@implementation SEGCountlyIntegrationTests

- (void)setUp
{
    [super setUp];

    _countlyMock = mock([Countly class]);

    _integration = [[SEGCountlyIntegration alloc] init];
    [_integration setCountly:_countlyMock];
    [_integration updateSettings:@{
        @"serverUrl" : @"foo",
        @"appKey" : @"bar"
    }];
}

- (void)testValid
{
    XCTAssertTrue(_integration.valid);
}

- (void)testInvalid
{
    [_integration updateSettings:@{}];
    XCTAssertFalse(_integration.valid);
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_countlyMock, times(1)) recordEvent:@"foo" segmentation:@{ @"bar" : @"baz" } count:1];
    [[verifyCount(_countlyMock, never()) withMatcher:anything()] recordEvent:anything() segmentation:anything() count:0 sum:0];
}

- (void)testTrackWithRevenue
{
    [_integration track:@"foo" properties:@{ @"revenue" : @10 } options:@{}];

    [verifyCount(_countlyMock, times(1)) recordEvent:@"foo" segmentation:@{ @"revenue" : @10 } count:1 sum:10];
    [[verifyCount(_countlyMock, never()) withMatcher:anything()] recordEvent:anything() segmentation:anything() count:0];
}

- (void)testTrackWithNestedProperties
{
    [_integration track:@"foo"
             properties:@{
                 @"bar" : @{@"baz" : @"qux"},
                 @"foobar" : @"barbaz"
             } options:@{}];

    [verifyCount(_countlyMock, times(1)) recordEvent:@"foo" segmentation:@{ @"foobar" : @"barbaz" } count:1];
    [[verifyCount(_countlyMock, never()) withMatcher:anything()] recordEvent:anything() segmentation:anything() count:0 sum:0];
}

- (void)testScreen
{
    [_integration screen:@"foo" properties:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_countlyMock, times(1)) recordEvent:@"Viewed foo Screen" segmentation:@{ @"bar" : @"baz" } count:1];
}


@end
