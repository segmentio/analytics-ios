//
//  LocalyticsProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "LocalyticsProvider.h"
#import "GHUnit.h"


@interface LocalyticsProviderTest : GHAsyncTestCase
@property(nonatomic) Provider *provider;
@end




@implementation LocalyticsProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [LocalyticsProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"3ccfac0c5c366f11105f26b-c8ab109c-b6e1-11e2-88e8-005cf8cbabd8", @"appKey", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testLocalyticsTrack
{
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
}

- (void)testLocalyticsIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Mixpanel", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testLocalyticsScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}

- (void)testLocalyticsAppEnterBackground
{
    [self.provider applicationDidEnterBackground];
}

- (void)testLocalyticsAppEnterForeground
{
    [self.provider applicationWillEnterForeground];
}

- (void)testLocalyticsAppTerminate
{
    [self.provider applicationWillTerminate];
}

- (void)testLocalyticsAppResignActive
{
    [self.provider applicationWillResignActive];
}

- (void)testLocalyticsAppBecomeActive
{
    [self.provider applicationDidBecomeActive];
}


@end