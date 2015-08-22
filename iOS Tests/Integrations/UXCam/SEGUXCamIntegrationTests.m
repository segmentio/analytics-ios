//
//  SEGOptimizelyIntegrationTests.m
//  Analytics
//
//  Created by Ricahrd Groves on 2015-07-06.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGUXCamIntegration.h"
#import <UXCam/UXCam.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGUXCamIntegrationTests : XCTestCase

@property SEGUXCamIntegration *integration;
@property Class uxcamClassMock;

@end


@implementation SEGUXCamIntegrationTests

- (void)setUp
{
    [super setUp];

    _uxcamClassMock = mockClass([UXCam class]);

    _integration = [[SEGUXCamIntegration alloc] init];
    [_integration setUxcamClass:_uxcamClassMock];
}

- (void)testValidate
{
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];

    XCTAssertTrue(_integration.valid);
}

@end
