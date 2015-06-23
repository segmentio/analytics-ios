//
//  SEGAmplitudeIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-23.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGAmplitudeIntegration.h"
#import <Amplitude-iOS/Amplitude.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGAmplitudeIntegrationTests : XCTestCase

@property SEGAmplitudeIntegration *integration;

@property Amplitude *amplitudeMock;

@end


@implementation SEGAmplitudeIntegrationTests

- (void)setUp
{
    [super setUp];

    _amplitudeMock = mock([Amplitude class]);
    _integration = [[SEGAmplitudeIntegration alloc] init];

    [_integration setAmplitude:_amplitudeMock];
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];
}

- (void)testIdentify
{
    [_integration identify:@"foo" traits:@{ @"bar" : @"baz" } options:nil];

    [verifyCount(_amplitudeMock, times(1)) setUserId:@"foo"];
    [verifyCount(_amplitudeMock, times(1)) setUserProperties:@{ @"bar" : @"baz" }];
}

- (void)testScreenDisabled
{
    [_integration updateSettings:@{ @"apiKey" : @"foo",
                                    @"trackAllPages" : @0 }];

    [_integration screen:@"foo" properties:nil options:nil];

    [verifyCount(_amplitudeMock, never()) setUserProperties:anything()];
    [verifyCount(_amplitudeMock, never()) logEvent:anything() withEventProperties:anything()];
}

- (void)testScreen
{
    [_integration updateSettings:@{ @"apiKey" : @"foo",
                                    @"trackAllPages" : @1 }];

    [_integration screen:@"foo" properties:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_amplitudeMock, times(1)) logEvent:@"Viewed foo Screen" withEventProperties:@{ @"bar" : @"baz" }];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_amplitudeMock, times(1)) logEvent:@"foo" withEventProperties:@{ @"bar" : @"baz" }];
}

- (void)testTrackWithRevenue
{
    [_integration track:@"foo"
             properties:@{
                 @"productId" : @"bar",
                 @"quantity" : @10,
                 @"receipt" : @"baz",
                 @"revenue" : @5
             } options:@{}];

    [verifyCount(_amplitudeMock, times(1)) logEvent:@"foo"
                                withEventProperties:@{
                                    @"productId" : @"bar",
                                    @"quantity" : @10,
                                    @"receipt" : @"baz",
                                    @"revenue" : @5
                                }];

    [verifyCount(_amplitudeMock, times(1)) logRevenue:@"bar" quantity:10 price:@5 receipt:@"baz"];
}

- (void)testFlush
{
    [_integration flush];

    [verifyCount(_amplitudeMock, times(1)) uploadEvents];
}

@end
