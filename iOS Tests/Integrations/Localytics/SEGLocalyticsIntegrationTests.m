//
//  SEGLocalyticsIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-26.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <Localytics/Localytics.h>
#import <XCTest/XCTest.h>
#import "SEGLocalyticsIntegration.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGLocalyticsIntegrationTests : XCTestCase

@property SEGLocalyticsIntegration *integration;
@property Class localyticsClassMock;

@end


@implementation SEGLocalyticsIntegrationTests

- (void)setUp
{
    [super setUp];

    _localyticsClassMock = mockClass([Localytics class]);

    _integration = [[SEGLocalyticsIntegration alloc] init];
    [_integration setLocalyticsClass:_localyticsClassMock];
}

- (void)testValidate
{
    [_integration updateSettings:@{ @"appKey" : @"foo" }];

    XCTAssertTrue(_integration.valid);
}

- (void)testFlush
{
    [_integration flush];

    [verifyCount(_localyticsClassMock, times(1)) upload];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"revenue" : @100 } options:nil];

    [verifyCount(_localyticsClassMock, times(1)) tagEvent:@"foo"
                                               attributes:@{
                                                   @"revenue" : @100
                                               }
                                    customerValueIncrease:@10000];
}

- (void)testScreen
{
    [_integration screen:@"foo" properties:nil options:nil];

    [verifyCount(_localyticsClassMock, times(1)) tagScreen:@"foo"];
}

- (void)testIdentifyWithUserId
{
    [_integration identify:@"foo" traits:nil options:nil];

    [verifyCount(_localyticsClassMock, times(1)) setCustomerId:@"foo"];
}

- (void)testIdentifyWithoutUserId
{
    [_integration identify:nil traits:nil options:nil];

    [verifyCount(_localyticsClassMock, never()) setCustomerId:anything()];
}

- (void)testIdentifyWithEmail
{
    [_integration identify:nil
                    traits:@{
                        @"email" : @"friends@segment.com"
                    }
                   options:nil];

    [verifyCount(_localyticsClassMock, times(1)) setValue:@"friends@segment.com"
                                            forIdentifier:@"email"];
}

- (void)testIdentifyWithoutEmail
{
    [_integration identify:nil traits:nil options:nil];

    [verifyCount(_localyticsClassMock, never()) setValue:anything()
                                           forIdentifier:anything()];
}

- (void)testIdentifyWithName
{
    [_integration identify:nil traits:@{ @"name" : @"foo" } options:nil];

    [verifyCount(_localyticsClassMock, times(1)) setValue:@"foo"
                                            forIdentifier:@"customer_name"];
}

- (void)testIdentifyWithoutName
{
    [_integration identify:nil traits:nil options:nil];

    [verifyCount(_localyticsClassMock, never()) setValue:anything()
                                           forIdentifier:anything()];
}

- (void)testIdentifyWithTraits
{
    [_integration identify:nil
                    traits:@{
                        @"foo" : @"bar",
                        @"baz" : @"qux"
                    }
                   options:nil];

    [verifyCount(_localyticsClassMock, times(1))
                   setValue:@"bar"
        forProfileAttribute:@"foo"
                  withScope:LLProfileScopeApplication];
    [verifyCount(_localyticsClassMock, times(1))
                   setValue:@"qux"
        forProfileAttribute:@"baz"
                  withScope:LLProfileScopeApplication];
}

@end
