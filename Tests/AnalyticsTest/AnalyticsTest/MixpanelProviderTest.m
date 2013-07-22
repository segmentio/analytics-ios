//
//  MixpanelProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Analytics/MixpanelProvider.h"
#import "Analytics/Mixpanel.h"
#import "GHUnitIOS/GHUnit.h"


@interface MixpanelProviderTest : GHAsyncTestCase
@property(nonatomic) MixpanelProvider *provider;
@end




@implementation MixpanelProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [MixpanelProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"89f86c4aa2ce5b74cb47eb5ec95ad1f9", @"token", @"true", @"people", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testMixpanelTrack
{
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"34.20", @"revenue", nil];
    NSMutableDictionary *providers = [NSMutableDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
    
    [[Mixpanel sharedInstance] flush];
}

- (void)testMixpanelIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", @"555 555 5555", @"phone", @"Henry", @"firstName", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Mixpanel", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
    
    [[Mixpanel sharedInstance] flush];
}


@end