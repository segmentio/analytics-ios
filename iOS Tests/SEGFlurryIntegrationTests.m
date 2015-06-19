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
