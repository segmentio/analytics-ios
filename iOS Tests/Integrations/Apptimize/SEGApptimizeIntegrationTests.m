//
//  SEGApptimizeIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-07-22.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGApptimizeIntegration.h"

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>
#import <XCTest/XCTest.h>

@interface SEGApptimizeIntegrationTests : XCTestCase

@property SEGApptimizeIntegration *integration;
@property Class apptimizeClassMock;

@end


@implementation SEGApptimizeIntegrationTests

- (void)setUp
{
    [super setUp];

    _apptimizeClassMock = mockClass([Apptimize class]);

    _integration = [[SEGApptimizeIntegration alloc] init];
    [_integration setApptimizeClass:_apptimizeClassMock];
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];
}

- (void)testIdentify
{
    [_integration identify:@"foo" traits:@{ @"bar" : @"qaz" } options:nil];

    [verifyCount(_apptimizeClassMock, times(1)) setUserAttributeString:@"foo" forKey:@"user_id"];
    [verifyCount(_apptimizeClassMock, times(1)) SEG_setUserAttributesFromDictionary:@{ @"bar" : @"qaz" }];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"qaz" } options:nil];

    [verifyCount(_apptimizeClassMock, times(1)) SEG_track:@"foo" attributes:@{ @"bar" : @"qaz" }];
}

- (void)testReset
{
    [_integration reset];

    [verifyCount(_apptimizeClassMock, times(1)) SEG_resetUserData];
}

@end
