//
//  SEGLocalyticsIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-26.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <Taplytics/Taplytics.h>
#import <XCTest/XCTest.h>
#import "SEGTaplyticsIntegration.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGTaplyticsIntegrationTests : XCTestCase

@property SEGTaplyticsIntegration *integration;
@property Class taplyticsClassMock;

@end


@implementation SEGTaplyticsIntegrationTests

- (void)setUp
{
    [super setUp];


    _taplyticsClassMock = mockClass([Taplytics class]);

    _integration = [[SEGTaplyticsIntegration alloc] init];
    [_integration setTaplyticsClass:_taplyticsClassMock];
}

- (void)testValidate
{
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];

    XCTAssertTrue(_integration.valid);
}

- (void)testReset
{
    [_integration reset];

    [verifyCount(_taplyticsClassMock, times(1)) resetUser:anything()];
}

- (void)testStart
{
    [_integration updateSettings:@{
        @"apiKey" : @"foo",
        @"delayLoad" : @1,
        @"shakeMenu" : @1,
        @"pushSandbox" : @0
    }];

    [verifyCount(_taplyticsClassMock, times(1)) startTaplyticsAPIKey:@"foo"
                                                             options:@{
                                                                 @"delayLoad" : @1,
                                                                 @"shakeMenu" : @1,
                                                                 @"pushSandbox" : @0
                                                             }];
}

- (void)testGroupWithGroupId
{
    [_integration group:@"foo" traits:nil options:nil];

    [verifyCount(_taplyticsClassMock, times(1)) setUserAttributes:@{ @"groupId" : @"foo" }];
}

- (void)testGroupWithTraits
{
    [_integration group:nil traits:@{ @"foo" : @"bar" } options:nil];

    [verifyCount(_taplyticsClassMock, times(1))
        setUserAttributes:@{
            @"groupTraits" :
                @{
                   @"foo" : @"bar"
                }
        }];
}

- (void)testGroup
{
    [_integration group:@"foo" traits:@{ @"bar" : @"baz" } options:nil];

    [verifyCount(_taplyticsClassMock, times(1))
        setUserAttributes:@{
            @"groupId" : @"foo",
            @"groupTraits" :
                @{
                   @"bar" : @"baz"
                }
        }];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:nil];

    [verifyCount(_taplyticsClassMock, times(1)) logEvent:@"foo" value:nil metaData:@{ @"bar" : @"baz" }];
}

- (void)testTrackWithRevenue
{
    [_integration track:@"foo" properties:@{ @"revenue" : @10 } options:nil];

    [verifyCount(_taplyticsClassMock, times(1)) logRevenue:@"foo" revenue:@10 metaData:@{ @"revenue" : @10 }];
}

- (void)testIdentify
{
    [_integration identify:@"foo" traits:nil options:nil];

    [verifyCount(_taplyticsClassMock, times(1)) setUserAttributes:@{ @"user_id" : @"foo" }];
}

- (void)testIdentifyWithTraits
{
    [_integration identify:@"foo"
                    traits:@{
                        @"bar" : @"baz",
                        @"lastName" : @"qaz",
                        @"firstName" : @"qux",
                        @"gender" : @"foobar",
                        @"age" : @"barbaz",
                        @"name" : @"bazqaz",
                        @"email" : @"qazqux",
                        @"avatar" : @"foobarbazqaz"
                    }
                   options:nil];

    [verifyCount(_taplyticsClassMock, times(1)) setUserAttributes:@{
        @"user_id" : @"foo",
        @"bar" : @"baz",
        @"lastName" : @"qaz",
        @"firstName" : @"qux",
        @"gender" : @"foobar",
        @"age" : @"barbaz",
        @"name" : @"bazqaz",
        @"email" : @"qazqux",
        @"avatarURL" : @"foobarbazqaz"
    }];
}

@end
