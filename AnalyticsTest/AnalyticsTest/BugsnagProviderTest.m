//
//  BugsnagProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "BugsnagProvider.h"
#import "Bugsnag.h"
#import "GHUnit.h"


@interface BugsnagProviderTest : GHAsyncTestCase
@property(nonatomic) BugsnagProvider *provider;
@end




@implementation BugsnagProviderTest

- (void)setUp
{
    [super setUp];
    self.provider = [BugsnagProvider withNothing];
    [self.provider updateSettings:[NSDictionary dictionaryWithObjectsAndKeys:@"7563fdfc1f418e956f5e5472148759f0", @"apiKey", nil]];
}

- (void)tearDown
{
    [super tearDown];
    self.provider = nil;
}

#pragma mark - API Calls

- (void)testBugsnagError
{
    [Bugsnag notify:[NSException exceptionWithName:@"ExceptionNameGAH" reason:@"Something bad happened snap" userInfo:nil]];
    
}

- (void)testBugsnagIdentify
{
    NSString *userId = @"smile@wrinkledhippo.com";
    NSDictionary *traits = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"Bugsnag", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider identify:userId traits:traits context:context];
}

- (void)testBugsnagScreen
{
    NSString *screenTitle = @"Store Front";
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys: @"Tilt-shift", @"Filter", nil];
    NSDictionary *providers = [NSDictionary dictionaryWithObjectsAndKeys: @"true", @"Salesforce", @"false", @"HubSpot", nil];
    NSDictionary *context = [NSDictionary dictionaryWithObjectsAndKeys: providers, @"providers", nil];
    [self.provider screen:screenTitle properties:properties context:context];
}


@end