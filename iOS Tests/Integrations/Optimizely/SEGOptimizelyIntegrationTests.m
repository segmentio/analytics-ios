//
//  SEGOptimizelyIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-29.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGOptimizelyIntegration.h"
#import <Optimizely/Optimizely.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGOptimizelyIntegrationTests : XCTestCase

@property SEGOptimizelyIntegration *integration;
@property Class optimizelyClassMock;

@end


@implementation SEGOptimizelyIntegrationTests

- (void)setUp
{
    [super setUp];


    _optimizelyClassMock = mockClass([Optimizely class]);

    _integration = [[SEGOptimizelyIntegration alloc] init];
    [_integration setOptimizelyClass:_optimizelyClassMock];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:nil options:nil];

    [verifyCount(_optimizelyClassMock, times(1)) trackEvent:@"foo"];
}

- (void)testStart
{
    [_integration setNeedsToActivateMixpanel:YES];
    [_integration updateSettings:@{}];

    XCTAssertTrue(_integration.valid);
    [verifyCount(_optimizelyClassMock, times(1)) activateMixpanelIntegration];
}

@end
