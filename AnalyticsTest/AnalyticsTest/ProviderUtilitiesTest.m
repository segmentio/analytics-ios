//
//  CountlyProviderTest.m
//
//  Created by Peter Reinhardt on 4/10/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "Provider.h"
#import "GHUnit.h"


@interface ProviderUtilitiesTest : GHAsyncTestCase
@end




@implementation ProviderUtilitiesTest

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

#pragma mark - API Calls

- (void)testProviderAliasKeys
{
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Peter", @"firstName", @"Reinhardt", @"lastName", @"555 555 5555", @"mobile", nil];
    NSDictionary *map = [NSDictionary dictionaryWithObjectsAndKeys: @"$first_name", @"firstName", @"$last_name", @"lastName", @"$phone", @"phone", nil];
    NSDictionary *mapped = [Provider aliasKeys:dictionary withMap:map];
    
    GHAssertEqualStrings([mapped objectForKey:@"$first_name"], @"Peter", @"firstName was not properly aliased to $first_name.");
    GHAssertEqualStrings([mapped objectForKey:@"$last_name"], @"Reinhardt", @"lastName was not properly aliased to $last_name.");
    GHAssertEqualStrings([mapped objectForKey:@"mobile"], @"555 555 5555", @"mobile was improperly aliased or lost.");
    
    GHAssertNil([mapped objectForKey:@"$phone"], @"$phone was improperly aliased to a non-null value.");
    GHAssertNil([mapped objectForKey:@"phone"], @"phone was improperly aliased to a non-null value.");
    
    NSLog(@"Mapped dictionary: %@", mapped);
}

- (void)testProviderExtractRevenue
{
    // Simple case
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Peter", @"firstName", @"Reinhardt", @"lastName", @"555 555 5555", @"mobile", [NSNumber numberWithDouble:34.56], @"revenue", nil];
    NSNumber *revenue = [Provider extractRevenue:dictionary];
    NSLog(@"Revenue output %@", revenue);
    GHAssertEquals([revenue doubleValue], 34.56, @"Revenue was not equal to the input value.");
    
    // String case
    dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Peter", @"firstName", @"Reinhardt", @"lastName", @"555 555 5555", @"mobile", @"34.56", @"revenue", nil];
    revenue = [Provider extractRevenue:dictionary];
    GHAssertEquals([revenue doubleValue], 34.56, @"Revenue was not equal to the input value.");
    
    // Non-number case
    dictionary = [NSDictionary dictionaryWithObjectsAndKeys: @"Peter", @"firstName", @"Reinhardt", @"lastName", @"555 555 5555", @"mobile", @"3asdf4.56", @"revenue", nil];
    revenue = [Provider extractRevenue:dictionary];
    GHAssertNil(revenue, @"Revenue was not nil.");
}


@end