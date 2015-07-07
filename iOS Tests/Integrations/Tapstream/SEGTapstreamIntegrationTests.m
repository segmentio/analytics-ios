//
//  SEGTapstreamIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-07-07.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGTapstreamIntegration.h"
#import <TSTapstream.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGTapstreamIntegrationTests : XCTestCase

@property SEGTapstreamIntegration *integration;
@property Class tapstreamClassMock;
@property TSTapstream *tapstreamMock;

@end


@implementation SEGTapstreamIntegrationTests

- (void)setUp
{
    [super setUp];

    self.tapstreamClassMock = mockClass([TSTapstream class]);
    self.tapstreamMock = mock([TSTapstream class]);
    [given([self.tapstreamClassMock instance]) willReturn:self.tapstreamMock];

    self.integration = [[SEGTapstreamIntegration alloc] init];
    [self.integration setTapstreamClass:self.tapstreamClassMock];
}

- (void)testValidate
{
    [self.integration updateSettings:@{ @"accountName" : @"foo",
                                        @"sdkSecret" : @"bar" }];

    XCTAssertTrue(self.integration.valid);
}

- (void)testInvalidate
{
    [self.integration updateSettings:@{}];

    XCTAssertFalse(self.integration.valid);
}

- (void)testTrack
{
    [self.integration track:@"foo" properties:nil options:nil];

    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(self.tapstreamMock, times(1)) fireEvent:[argument capture]];
    assertThat([[argument value] name], is(@"foo"));
}


- (void)testScreen
{
    [self.integration screen:@"foo" properties:nil options:nil];

    MKTArgumentCaptor *argument = [[MKTArgumentCaptor alloc] init];
    [verifyCount(self.tapstreamMock, times(1)) fireEvent:[argument capture]];
    assertThat([[argument value] name], is(@"viewed foo screen"));
}

- (void)testMakeEventWithoutProperties
{
    TSEvent *event = [self.integration makeEvent:@"foo" properties:nil options:nil];
    assertThat([event name], is(@"foo"));
}

- (void)testMakeOneTimeOnlyEvent
{
    TSEvent *event = [self.integration makeEvent:@"foo" properties:nil options:@{
        @"oneTimeOnly" : @1
    }];
    XCTAssertTrue(event.isOneTimeOnly);

    event = [self.integration makeEvent:@"foo" properties:nil options:@{
        @"oneTimeOnly" : @0
    }];
    XCTAssertFalse(event.isOneTimeOnly);
}

- (void)testMakeEventWithProperties
{
    TSEvent *event = [self.integration makeEvent:@"foo" properties:@{ @"a_string" : @"foo",
                                                                      @"a_number" : @10 }
                                         options:nil];

    assertThat(event.customFields, hasEntry(@"a_string", @"foo"));
    assertThat(event.customFields, hasEntry(@"a_number", @10));
}

@end
