//
//  SEGMixpanelIntegrationTests.m
//  Analytics
//
//  Created by Prateek Srivastava on 2015-06-30.
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGMixpanelIntegration.h"
#import <Mixpanel.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGMixpanelIntegrationTests : XCTestCase

@property SEGMixpanelIntegration *integration;
@property Class mixpanelClassMock;
@property Mixpanel *mixpanelMock;
@property MixpanelPeople *mixpanelPeopleMock;

@end


@implementation SEGMixpanelIntegrationTests

- (void)setUp
{
    [super setUp];

    _mixpanelClassMock = mockClass([Mixpanel class]);
    _mixpanelMock = mock([Mixpanel class]);
    _mixpanelPeopleMock = mock([MixpanelPeople class]);

    [given([_mixpanelClassMock sharedInstance]) willReturn:_mixpanelMock];
    [given([_mixpanelMock people]) willReturn:_mixpanelPeopleMock];
    _integration = [[SEGMixpanelIntegration alloc] init];
    [_integration setMixpanelClass:_mixpanelClassMock];
}

- (void)testStart
{
    [_integration updateSettings:@{ @"token" : @"foo" }];

    XCTAssertTrue(_integration.valid);
    [verifyCount(_mixpanelClassMock, times(1)) sharedInstanceWithToken:@"foo"];
}

- (void)testAlias
{
    [given([_mixpanelMock distinctId]) willReturn:@"foo"];

    [_integration alias:@"bar" options:nil];

    [verifyCount(_mixpanelMock, times(1)) createAlias:@"bar" forDistinctID:@"foo"];
}


- (void)testReset
{
    [_integration reset];

    // todo: fix test -> [verifyCount(_mixpanelMock, times(1)) flush];
    [verifyCount(_mixpanelMock, times(1)) reset];
}

- (void)testFlush
{
    [_integration flush];

    [verifyCount(_mixpanelMock, times(1)) flush];
}

- (void)testIdentify
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"setAllTraitsByDefault" : @1
    }];

    [_integration identify:@"foo" traits:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(1)) registerSuperProperties:@{ @"bar" : @"baz" }];
    [verifyCount(_mixpanelPeopleMock, times(0)) set:@{ @"bar" : @"baz" }];
}

- (void)testIdentifyWithPeople
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"people" : @1,
        @"setAllTraitsByDefault" : @1
    }];

    [_integration identify:@"foo" traits:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(1)) registerSuperProperties:@{ @"bar" : @"baz" }];
    [verifyCount(_mixpanelPeopleMock, times(1)) set:@{ @"bar" : @"baz" }];
}

- (void)testIdentifyWithPeopleAndWithoutSettingTraits
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"people" : @1,
        @"setAllTraitsByDefault" : @0
    }];
    [_integration identify:@"foo" traits:@{ @"bar" : @"baz" } options:@{}];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(0)) registerSuperProperties:anything()];
    [verifyCount(_mixpanelPeopleMock, times(0)) set:anything()];
}

- (void)testIdentifyWithMappedTraits
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"setAllTraitsByDefault" : @1
    }];

    [_integration identify:@"foo"
                    traits:@{
                        @"firstName" : @"bar",
                        @"lastName" : @"baz",
                        @"createdAt" : @"qaz",
                        @"lastSeen" : @"foobar",
                        @"email" : @"barbaz",
                        @"name" : @"bazqaz",
                        @"username" : @"foobarbaz",
                        @"phone" : @"barbazqaz"
                    }
                   options:@{}];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(1)) registerSuperProperties:@{
        @"$first_name" : @"bar",
        @"$last_name" : @"baz",
        @"$created" : @"qaz",
        @"$last_seen" : @"foobar",
        @"$email" : @"barbaz",
        @"$name" : @"bazqaz",
        @"$username" : @"foobarbaz",
        @"$phone" : @"barbazqaz"
    }];
}

- (void)testIdentifyWithMappedPropertiesAndSuperProperties
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"people" : @1,
        @"setAllTraitsByDefault" : @0
    }];

    [_integration identify:@"foo"
                    traits:@{
                        @"firstName" : @"bar",
                        @"lastName" : @"baz",
                        @"createdAt" : @"qaz",
                        @"lastSeen" : @"foobar",
                        @"email" : @"barbaz",
                        @"name" : @"bazqaz",
                        @"username" : @"foobarbaz",
                        @"phone" : @"barbazqaz"
                    }
                   options:@{
                       @"integrations" : @{
                           @"Mixpanel" : @{
                               @"superProperties" : @[ @"firstName" ],
                               @"peopleProperties" : @[ @"lastName" ],
                           }
                       }
                   }];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(1)) registerSuperProperties:@{
        @"$first_name" : @"bar"
    }];
    [verifyCount(_mixpanelPeopleMock, times(1)) set:@{
        @"$last_name" : @"baz"
    }];
}

- (void)testIdentifyWithoutSetAllTraitsAndNoMappedTraits
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"people" : @1,
        @"setAllTraitsByDefault" : @0
    }];

    [_integration identify:@"foo"
                    traits:@{
                        @"firstName" : @"bar",
                        @"lastName" : @"baz",
                        @"createdAt" : @"qaz",
                        @"lastSeen" : @"foobar",
                        @"email" : @"barbaz",
                        @"name" : @"bazqaz",
                        @"username" : @"foobarbaz",
                        @"phone" : @"barbazqaz"
                    }
                   options:@{
                       @"integrations" : @{
                           @"Mixpanel" : @{}
                       }
                   }];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(1)) registerSuperProperties:anything()];
    [verifyCount(_mixpanelPeopleMock, times(1)) set:anything()];
}


- (void)testIdentifyWithoutSetAllTraitsAndNoMixpanelOptions
{
    [_integration setSettings:@{
        @"token" : @"foo",
        @"people" : @1,
        @"setAllTraitsByDefault" : @0
    }];

    [_integration identify:@"foo"
                    traits:@{
                        @"firstName" : @"bar",
                        @"lastName" : @"baz",
                        @"createdAt" : @"qaz",
                        @"lastSeen" : @"foobar",
                        @"email" : @"barbaz",
                        @"name" : @"bazqaz",
                        @"username" : @"foobarbaz",
                        @"phone" : @"barbazqaz"
                    }
                   options:@{
                       @"integrations" : @{}
                   }];

    [verifyCount(_mixpanelMock, times(1)) identify:@"foo"];
    [verifyCount(_mixpanelMock, times(0)) registerSuperProperties:anything()];
    [verifyCount(_mixpanelPeopleMock, times(0)) set:anything()];
}


- (void)testTrack
{
    [_integration track:@"foo" properties:@{ @"bar" : @"baz" } options:nil];

    [verifyCount(_mixpanelMock, times(1)) track:@"foo" properties:@{ @"bar" : @"baz" }];
}

- (void)testTrackWithRevenue
{
    [_integration setSettings:@{ @"people" : @1 }];

    [_integration track:@"foo" properties:@{ @"revenue" : @10 } options:nil];

    [verifyCount(_mixpanelPeopleMock, times(1)) trackCharge:@10];
}

- (void)testTrackWithIncrement
{
    [_integration setSettings:@{ @"people" : @1,
                                 @"increments" : @[ @"foo" ] }];

    [_integration track:@"foo" properties:@{} options:nil];

    [verifyCount(_mixpanelPeopleMock, times(1)) increment:@"foo" by:@1];
    [verifyCount(_mixpanelPeopleMock, times(1)) set:@"Last foo" to:anything()];
}


@end
