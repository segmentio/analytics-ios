//
//  SEGKahunaIntegrationTests.m
//  Analytics
//
//  Copyright (c) 2015 Segment.io. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SEGKahunaDefines.h"
#import "SEGKahunaIntegration.h"
#import <Kahuna/Kahuna.h>

#define HC_SHORTHAND
#import <OCHamcrest/OCHamcrest.h>

#define MOCKITO_SHORTHAND
#import <OCMockito/OCMockito.h>


@interface SEGKahunaIntegrationTests : XCTestCase

@property SEGKahunaIntegration *integration;
@property Class kahunaClassMock;
@property Class nserrorClassMock;
@property NSError *nserrorMock;
@property Kahuna *kahunaMock;
@property KahunaUserCredentials *kahunaCredentialsMock;

@end


@implementation SEGKahunaIntegrationTests

- (void)setUp
{
    [super setUp];

    _kahunaMock = mock([Kahuna class]);
    _kahunaClassMock = mockClass([Kahuna class]);
    _nserrorMock = mock([NSError class]);
    _nserrorClassMock = mockClass([NSError class]);
    _kahunaCredentialsMock = mock([KahunaUserCredentials class]);

    [given([_kahunaClassMock sharedInstance]) willReturn:_kahunaMock];
    [given([_kahunaClassMock createUserCredentials]) willReturn:_kahunaCredentialsMock];
    [given([_nserrorClassMock errorWithDomain:anything() code:anything() userInfo:anything()]) willReturn:_nserrorMock];
    
    _integration = [[SEGKahunaIntegration alloc] init];
     [_integration setKahunaClass:_kahunaClassMock];
}

- (void)testStart
{
    [_integration updateSettings:@{ @"apiKey" : @"foo" }];

    XCTAssertTrue(_integration.valid);
    [verifyCount(_kahunaClassMock, times(1)) launchWithKey:@"foo"];
}

- (void)testReset
{
    [_integration reset];
    
    [verifyCount(_kahunaClassMock, times(1)) logout];
}

- (void)testIdentify
{
    [_integration identify:@"foo" traits:@{ @"bar" : @"baz" } options:@{}];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{ @"bar" : @"baz" }];
}

- (void)testIdentifyWithNoTraits
{
    [_integration identify:@"foo" traits:@{} options:@{}];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, never()) setUserAttributes:anything()];
}

- (void)testIdentifyWithNoCredentialsAndNoTraits
{
    [_integration identify:nil traits:@{} options:@{}];
    
    // Verify that Add Credential was called once on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, never()) addCredential:anything() withValue:anything()];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, never()) setUserAttributes:anything()];
}

- (void)testIdentifyWithMultipleCredentialsAndTraits
{
    [_integration identify:@"foo" traits:@{ @"bar" : @"baz", KAHUNA_CREDENTIAL_EMAIL : @"segkah@gmail.com", @"moon" : @"drake" } options:@{}];
    
    // Verify that Add Credential was called twice on the KahunaCredentialsMock object.
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_USER_ID withValue:@"foo"];
    [verifyCount(_kahunaCredentialsMock, times(1)) addCredential:KAHUNA_CREDENTIAL_EMAIL withValue:@"segkah@gmail.com"];
    
    [[verifyCount(_kahunaClassMock, times(1)) withMatcher:anything() forArgument:1] loginWithCredentials:_kahunaCredentialsMock error:nil];
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{ @"bar" : @"baz", @"moon" : @"drake" }];
}

- (void)testTrack
{
    [_integration track:@"foo" properties:@{} options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
}

- (void)testTrackWithRevenueButNoQuantity
{
    [_integration track:@"foo" properties:@{ @"revenue" : @10 } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
    [verifyCount(_kahunaClassMock, never()) trackEvent:@"foo" withCount:anything() andValue:anything()];
}

- (void)testTrackWithQuantityButNoRevenue
{
    [_integration track:@"foo" properties:@{ @"quantity" : @10 } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo"];
    [verifyCount(_kahunaClassMock, never()) trackEvent:@"foo" withCount:anything() andValue:anything()];
}

- (void)testTrackWithQuantityAndRevenue
{
    [_integration track:@"foo" properties:@{ @"revenue" : @10, @"quantity" : @4 } options:nil];
    
    [verifyCount(_kahunaClassMock, never()) trackEvent:anything()];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo" withCount:4 andValue:1000];
}

- (void)testTrackWithQuantityRevenueAndProperties
{
    [_integration track:@"foo"
             properties:@{@"productId" : @"bar",
                          @"quantity" : @10,
                          @"receipt" : @"baz",
                          @"revenue" : @5
                          } options:@{}];
    
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"foo" withCount:10 andValue:500];
}

- (void)testTrackWithPropertyViewedCategory
{
    [_integration track:KAHUNA_VIEWED_PRODUCT_CATEGORY properties:@{ KAHUNA_CATEGORY : @"shirts" } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_VIEWED_CATEGORY : @"shirts", KAHUNA_CATEGORIES_VIEWED : @"shirts" }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_VIEWED_PRODUCT_CATEGORY];
}

- (void)testTrackWithPropertyViewedProduct
{
    [_integration track:KAHUNA_VIEWED_PRODUCT properties:@{ KAHUNA_NAME : @"gopher shirts" } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PRODUCT_VIEWED_NAME : @"gopher shirts",
                                                                 KAHUNA_CATEGORIES_VIEWED : KAHUNA_NONE,
                                                                 KAHUNA_LAST_VIEWED_CATEGORY : KAHUNA_NONE }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_VIEWED_PRODUCT];
    
}

- (void)testTrackWithPropertyAddedProduct
{
    [_integration track:KAHUNA_ADDED_PRODUCT properties:@{ KAHUNA_NAME : @"gopher shirts" } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PRODUCT_ADDED_TO_CART_NAME : @"gopher shirts",
                                                                 KAHUNA_LAST_PRODUCT_ADDED_TO_CART_CATEGORY : KAHUNA_NONE }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_ADDED_PRODUCT];
}

- (void)testTrackWithPropertyCompletedOrder
{
    [_integration track:KAHUNA_COMPLETED_ORDER properties:@{ KAHUNA_DISCOUNT : @15.0 } options:nil];
    
    [verifyCount(_kahunaClassMock, times(1)) setUserAttributes:@{KAHUNA_LAST_PURCHASE_DISCOUNT : @15.0 }];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:KAHUNA_COMPLETED_ORDER];
}

- (void)testScreen
{
    [_integration setSettings:@{ @"trackAllPages" : @1 }];
    
    [_integration screen:@"foo" properties:@{} options:@{}];
    [verifyCount(_kahunaClassMock, times(1)) trackEvent:@"Viewed foo Screen"];
}

- (void)testScreenWithNoTrackAllPagesSettings
{
    [_integration screen:@"foo" properties:@{} options:@{}];
    [verifyCount(_kahunaClassMock, never()) trackEvent:anything()];
}

@end
