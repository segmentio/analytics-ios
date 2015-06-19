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

- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:@{}];

    OCMVerify([_flurryMock logEvent:@"foo" withParameters:@{ @"bar" : @"baz" }]);
}

@end
