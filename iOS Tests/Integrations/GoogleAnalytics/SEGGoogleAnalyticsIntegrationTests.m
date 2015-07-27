//
//  SEGGoogleAnalyticsIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-07-24.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SEGGoogleAnalyticsIntegration.h"


#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGGoogleAnalyticsIntegrationTests : XCTestCase

@property SEGGoogleAnalyticsIntegration *integration;
@property GAI *gaiMock;
@property id<GAITracker> trackerMock;

@end


@implementation SEGGoogleAnalyticsIntegrationTests

- (void)setUp
{
    [super setUp];

    _trackerMock = mockProtocol(@protocol(GAITracker));
    _gaiMock = mock([GAI class]);
    [given([_gaiMock trackerWithTrackingId:anything()]) willReturn:_trackerMock];

    _integration = [[SEGGoogleAnalyticsIntegration alloc] init];
    [_integration setGai:_gaiMock];
    [_integration setTracker:_trackerMock];
}

- (void)testFlush
{
    [_integration flush];

    [verifyCount(_gaiMock, times(1)) dispatch];
}

- (void)testResetTraits
{
    [_integration setTraits:@{
        @"foo" : @"bar",
        @"qaz" : @"qux"
    }];
    [_integration resetTraits];

    [verifyCount(_trackerMock, times(1)) set:@"foo" value:nil];
    [verifyCount(_trackerMock, times(1)) set:@"qaz" value:nil];
}

- (void)testReset
{
    [_integration setTraits:@{
        @"foo" : @"bar",
        @"qaz" : @"qux"
    }];
    [_integration reset];

    [verifyCount(_trackerMock, times(1)) set:@"&uid" value:nil];
    [verifyCount(_trackerMock, times(1)) set:@"foo" value:nil];
    [verifyCount(_trackerMock, times(1)) set:@"qaz" value:nil];
}

- (void)testScreen
{
    [_integration screen:@"foo" properties:nil options:nil];

    [verifyCount(_trackerMock, times(1)) set:kGAIScreenName value:@"foo"];
    [verifyCount(_trackerMock, times(1)) send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)testIdentify
{
    [_integration setSettings:@{ @"sendUserId" : @YES }];
    [_integration setTraits:@{
        @"foo" : @"bar",
        @"qaz" : @"qux"
    }];

    [_integration identify:@"foo" traits:@{ @"foobar" : @"qazqux" } options:nil];

    [verifyCount(_trackerMock, times(1)) set:@"foo" value:nil];
    [verifyCount(_trackerMock, times(1)) set:@"qaz" value:nil];
    [verifyCount(_trackerMock, times(1)) set:@"&uid" value:@"foo"];
    [verifyCount(_trackerMock, times(1)) set:@"foobar" value:@"qazqux"];
}

- (void)testTrack
{
    [_integration track:@"foo"
             properties:@{ @"label" : @"bar",
                           @"revenue" : @10 }
                options:nil];

    [verifyCount(_trackerMock, times(1)) send:
                                             [[GAIDictionaryBuilder createEventWithCategory:@"All"
                                                                                     action:@"foo"
                                                                                      label:@"bar"
                                                                                      value:@10] build]];
}

@end
