//
//  AnalyticsUtilsTests.m
//  Analytics
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AnalyticsUtils.h"
#import "AnalyticsProvider.h"

SPEC_BEGIN(AnalyticsUtilsTests)

describe(@"Analytics Utils", ^{
    it(@"should correctly map provider alias keys", ^{
        NSDictionary *dictionary = @{
            @"firstName": @"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555"
        };
        NSDictionary *map = @{
            @"firstName": @"$first_name",
            @"lastName": @"$last_name",
            @"phone": @"$phone"
        };
        NSDictionary *mapped = [AnalyticsProvider map:dictionary withMap:map];
        
        [[mapped[@"$first_name"] should] equal:@"Peter"];
        [[mapped[@"$last_name"] should] equal:@"Reinhardt"];
        [[mapped[@"mobile"] should] equal:@"555 555 5555"];
        [mapped[@"$phone"] shouldBeNil];
        [mapped[@"phone"] shouldBeNil];
    });
    
    it(@"should extract revenue from properties", ^{
        // Simple case
        NSDictionary *dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @34.56
        };
        NSNumber *revenue = [AnalyticsProvider extractRevenue:dictionary];
        [[revenue should] equal:@34.56];
        
        // String case
        dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @"34.56"
        };
        revenue = [AnalyticsProvider extractRevenue:dictionary];
        [[revenue should] equal:@34.56];
        
        // Non-number case
        dictionary = @{
            @"firstName":@"Peter",
            @"lastName": @"Reinhardt",
            @"mobile": @"555 555 5555",
            @"revenue": @"3asdf4.56"
        };
        revenue = [AnalyticsProvider extractRevenue:dictionary];
        [revenue shouldBeNil];
    });
});

SPEC_END