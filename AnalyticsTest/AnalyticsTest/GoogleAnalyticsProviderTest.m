//
//  GoogleAnalyticsProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "GoogleAnalyticsProvider.h"
#import "GHUnit.h"


@interface GoogleAnalyticsProviderTest : GHAsyncTestCase
@property(nonatomic) GoogleAnalyticsProvider *provider;
@end




@implementation GoogleAnalyticsProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [GoogleAnalyticsProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"UA-27033709-9", @"mobileTrackingId", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testGoogleAnalyticsTrack
{
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"34.20", @"revenue", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
    
}

- (void)testGoogleAnalyticsIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"GoogleAnalytics", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testGoogleAnalyticsScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}


@end