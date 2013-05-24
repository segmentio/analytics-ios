//
//  AmplitudeProviderTest.m
//
//  Created by Peter Reinhardt on 5/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AmplitudeProvider.h"
#import "GHUnit.h"


@interface AmplitudeProviderTest : GHAsyncTestCase
@property(nonatomic) AmplitudeProvider *provider;
@end




@implementation AmplitudeProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [AmplitudeProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"3a68a9df008c179726b768fa167f1a02", @"apiKey", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testAmplitudeTrack
{
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"34.20", @"revenue", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
}

- (void)testAmplitudeIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Amplitude", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testAmplitudeScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}


@end