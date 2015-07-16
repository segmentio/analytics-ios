//
//  SEGAppsFlyerIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-07-16.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGAppsFlyerIntegration.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGAppsFlyerIntegrationTests : XCTestCase

@property SEGAppsFlyerIntegration *integration;
@property AppsFlyerTracker *appsFlyerMock;

@end


@implementation SEGAppsFlyerIntegrationTests

- (void)setUp
{
    [super setUp];

    _appsFlyerMock = mock([AppsFlyerTracker class]);
    _integration = [[SEGAppsFlyerIntegration alloc] init];

    [_integration setAppsFlyer:_appsFlyerMock];
    [_integration updateSettings:@{
        @"appsFlyerDevKey" : @"foo",
        @"appleAppID" : @"bar"
    }];
}

- (void)testIdentify
{
    [_integration identify:@"foo" traits:nil options:nil];

    [verifyCount(_appsFlyerMock, times(1)) setCustomerUserID:@"foo"];
}

- (void)testIdentifyWithoutUserId
{
    [_integration identify:nil traits:nil options:nil];

    [verifyCount(_appsFlyerMock, never()) setCustomerUserID:anything()];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:nil options:nil];

    [verifyCount(_appsFlyerMock, times(1)) trackEvent:@"foo" withValue:anything()];
    [verifyCount(_appsFlyerMock, never()) setCurrencyCode:anything()];
}

- (void)testTrackWithProperties
{
    [_integration track:@"foo"
             properties:@{
                 @"revenue" : @3.142,
                 @"currency" : @"bar"
             }
                options:nil];

    [verifyCount(_appsFlyerMock, times(1)) trackEvent:@"foo" withValue:@"3.142"];
    [verifyCount(_appsFlyerMock, times(1)) setCurrencyCode:@"bar"];
}

- (void)testStart
{
    [verifyCount(_appsFlyerMock, times(1)) setAppleAppID:@"bar"];
    [verifyCount(_appsFlyerMock, times(1)) setAppsFlyerDevKey:@"foo"];
}

@end
