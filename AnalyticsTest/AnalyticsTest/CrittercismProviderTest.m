//
//  CrittercismProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "CrittercismProvider.h"
#import "Crittercism.h"
#import "GHUnit.h"


@interface CrittercismProviderTest : GHAsyncTestCase
@property(nonatomic) CrittercismProvider *provider;
@end




@implementation CrittercismProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [CrittercismProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"519ac636c463c21006000005", @"appId", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testCrittercismError
{
    [Crittercism logHandledException:[NSException exceptionWithName:@"ExceptionNameGAH" reason:@"Something bad happened snap" userInfo:nil]];
}

- (void)testCrittercismIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Crittercism", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testCrittercismTrack
{
    NSString *eventName = @"Purchased an iPad 5";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider track:eventName properties:properties context:context];
}

- (void)testCrittercismScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}


@end