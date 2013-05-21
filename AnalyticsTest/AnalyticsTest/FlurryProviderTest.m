//
//  FlurryProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "FlurryProvider.h"
#import "GHUnit.h"


@interface FlurryProviderTest : GHAsyncTestCase
@property(nonatomic) FlurryProvider *provider;
@end




@implementation FlurryProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [FlurryProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"VN8HXZ28MWPB7JPBYNZD", @"apiKey", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testFlurryTrack
{
    [self prepare];
    
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
    
}

- (void)testFlurryIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Flurry", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testFlurryScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}


@end