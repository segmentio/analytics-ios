#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SEGFlurryIntegration.h"
#import <Flurry.h>


@interface SEGFlurryIntegrationTests : XCTestCase

@property SEGFlurryIntegration *integration;
@property id flurryMock;

@end


@implementation SEGFlurryIntegrationTests

- (void)setUp
{
    [super setUp];

    _flurryMock = OCMClassMock([Flurry class]);

    _integration = [[SEGFlurryIntegration alloc] init];
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];
}


- (void)testValidate
{
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];
    XCTAssertTrue(_integration.valid);

    [_integration updateSettings:@{}];
    XCTAssertFalse(_integration.valid);
}

- (void)testIdentify
{
    [[_flurryMock reject] setGender:[OCMArg any]];
    [[_flurryMock reject] setAge:0];
    [[_flurryMock reject] setLatitude:0 longitude:0 horizontalAccuracy:0 verticalAccuracy:0];

    [_integration identify:@"foo" traits:@{} options:nil];

    OCMVerify([_flurryMock setUserID:@"foo"]);
}

- (void)testIdentifyWithSpecialParams
{
    [_integration identify:@"foo"
                    traits:@{
                        @"gender" : @"bar",
                        @"age" : @"20",
                        @"location" : @{
                            @"latitude" : @21.2,
                            @"longitude" : @38.9832,
                            @"horizontalAccuracy" : @9,
                            @"verticalAccuracy" : @0.08
                        }
                    }
                   options:nil];

    OCMVerify([_flurryMock setUserID:@"foo"]);
    OCMVerify([_flurryMock setGender:@"b"]);
    OCMVerify([_flurryMock setAge:20]);
    [[[_flurryMock expect] ignoringNonObjectArgs] setLatitude:0 longitude:0 horizontalAccuracy:0 verticalAccuracy:0];
}


- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:nil];

    OCMVerify([_flurryMock logEvent:@"foo" withParameters:@{ @"bar" : @"baz" }]);
}

- (void)testScreen
{
    [[_flurryMock reject] logEvent:[OCMArg any] withParameters:[OCMArg any]];

    [_integration screen:@"foo" properties:@{} options:nil];

    OCMVerify([_flurryMock logPageView]);
}


- (void)testScreenWithScreenTracksEvents
{
    [_integration updateSettings:@{ @"apiKey" : @"foo",
                                    @"screenTracksEvents" : @YES }];

    [_integration screen:@"foo" properties:@{ @"bar" : @"baz" } options:nil];

    OCMVerify([_flurryMock logEvent:@"Viewed foo Screen" withParameters:@{ @"bar" : @"baz" }]);
    OCMVerify([_flurryMock logPageView]);
}

@end
