//
//  SEGCrittercismIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-25.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGCrittercismIntegration.h"
#import <Crittercism.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGCrittercismIntegrationTests : XCTestCase


@property SEGCrittercismIntegration *integration;

@property Class crittercismClassMock;
@property Class crittercismConfigClassMock;
@property CrittercismConfig *crittercismMock;

@end


@implementation SEGCrittercismIntegrationTests

- (void)setUp
{
    [super setUp];

    _crittercismClassMock = mockClass([Crittercism class]);
    _crittercismConfigClassMock = mockClass([CrittercismConfig class]);
    _crittercismMock = mock([CrittercismConfig class]);

    [given([_crittercismConfigClassMock defaultConfig]) willReturn:_crittercismMock];

    _integration = [[SEGCrittercismIntegration alloc] init];
    [_integration setCrittercismClass:_crittercismClassMock];
    [_integration setCrittercismConfigClass:_crittercismConfigClassMock];

    [_integration updateSettings:@{ @"appId" : @"foo" }];
}

- (void)testStart
{
    [verifyCount(_crittercismClassMock, times(1)) enableWithAppID:@"foo" andConfig:anything()];
    XCTAssertTrue(_integration.valid);
}


- (void)testInvalidSettings
{
    [_integration updateSettings:@{ @"foo" : @"bar" }];

    XCTAssertFalse(_integration.valid);
}

- (void)testIdentify
{
    [_integration identify:@"foo"
                    traits:@{ @"bar" : @"baz",
                              @"qux" : @"foobar" }
                   options:nil];

    [verifyCount(_crittercismClassMock, times(1)) setUsername:@"foo"];
    [verifyCount(_crittercismClassMock, times(1)) setValue:@"baz" forKey:@"bar"];
    [verifyCount(_crittercismClassMock, times(1)) setValue:@"foobar" forKey:@"qux"];
}


- (void)testIdentifyWithoutAnything
{
    [_integration identify:nil traits:nil options:nil];

    [verifyCount(_crittercismClassMock, never()) setUsername:anything()];
    [verifyCount(_crittercismClassMock, never()) setValue:anything() forKey:anything()];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:nil options:nil];

    [verifyCount(_crittercismClassMock, times(1)) leaveBreadcrumb:@"foo"];
}

- (void)testScreen
{
    [_integration screen:@"foo" properties:nil options:nil];

    [verifyCount(_crittercismClassMock, times(1)) leaveBreadcrumb:@"Viewed foo Screen"];
}

@end
