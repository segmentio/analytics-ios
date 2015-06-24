//
//  SEGBugsnagIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-24.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGBugsnagIntegration.h"
#import <Bugsnag/Bugsnag.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGBugsnagIntegrationTests : XCTestCase

@property SEGBugsnagIntegration *integration;
@property Class bugsnagClassMock;
@property id bugsnagConfigurationMock;

@end


@implementation SEGBugsnagIntegrationTests

- (void)setUp
{
    [super setUp];

    _bugsnagClassMock = mockClass([Bugsnag class]);
    _bugsnagConfigurationMock = mock([BugsnagConfiguration class]);
    [given([_bugsnagClassMock configuration]) willReturn:_bugsnagConfigurationMock];

    _integration = [[SEGBugsnagIntegration alloc] init];
    [_integration setBugsnagClass:_bugsnagClassMock];
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];
}

- (void)testIdentify
{
    [_integration identify:@"foo"
                    traits:@{ @"email" : @"bar",
                              @"name" : @"baz" }
                   options:@{}];

    [verifyCount(_bugsnagConfigurationMock, times(1)) setUser:@"foo" withName:@"baz" andEmail:@"bar"];
    [verifyCount(_bugsnagClassMock, times(1)) addAttribute:@"email" withValue:@"bar" toTabWithName:@"user"];
    [verifyCount(_bugsnagClassMock, times(1)) addAttribute:@"name" withValue:@"baz" toTabWithName:@"user"];
}

- (void)testScreen
{
    [_integration screen:@"foo" properties:nil options:nil];

    [verifyCount(_bugsnagConfigurationMock, times(1)) setContext:@"foo"];
}

- (void)testValid
{
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];

    XCTAssertTrue(_integration.valid);
}

- (void)testInvalid
{
    [_integration updateSettings:@{}];

    XCTAssertFalse(_integration.valid);
}

- (void)testStart
{
    // Initialized in setup
    [verifyCount(_bugsnagClassMock, times(1)) startBugsnagWithApiKey:@"foo"];
}


@end
