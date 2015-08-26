//
//  SEGQuantastIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-07-21.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import "SEGQuantcastIntegration.h"
#import <XCTest/XCTest.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>

@interface SEGQuantastIntegrationTests : XCTestCase

@property SEGQuantcastIntegration *integration;
@property QuantcastMeasurement *quantcastMock;

@end


@implementation SEGQuantastIntegrationTests

- (void)setUp
{
    [super setUp];

    self.quantcastMock = mock([QuantcastMeasurement class]);
    self.integration = [[SEGQuantcastIntegration alloc] init];

    [self.integration setQuantcast:self.quantcastMock];
    [self.integration updateSettings:@{ @"apiKey" : @"foo",
                                        @"userIdentifier" : @"bar",
                                        @"labels" : @[] }];
}

- (void)testTrack
{
    [self.integration track:@"foo" properties:nil options:nil];

    [verifyCount(self.quantcastMock, times(1)) logEvent:@"foo" withLabels:@[]];
}

- (void)testScreen
{
    [self.integration screen:@"foo" properties:nil options:nil];

    [verifyCount(self.quantcastMock, times(1)) logEvent:@"Viewed foo Screen" withLabels:@[]];
}

- (void)testIdentify
{
    [self.integration identify:@"foo" traits:nil options:nil];

    [verifyCount(self.quantcastMock, times(1)) recordUserIdentifier:@"foo" withLabels:@[]];
}

@end
