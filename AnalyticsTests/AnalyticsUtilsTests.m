//
//  AnalyticsUtilsTests.m
//  Analytics
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import "AnalyticsUtils.h"
#import "AnalyticsProvider.h"

#define ShouldBeOnSpecificQueue(queue) [[@(dispatch_is_on_specific_queue(queue)) should] beYes]
#define ShouldNotBeOnSpecificQueue(queue) [[@(dispatch_is_on_specific_queue(queue)) should] beNo]
#define MarkerBlock ^{ blockRan = YES; }

SPEC_BEGIN(AnalyticsUtilsTests)

describe(@"Specific dispatch_queue", ^{
    __block dispatch_queue_t queue = nil;
    beforeEach(^{
        queue = so_dispatch_queue_create_specific("io.segment.test.queue", DISPATCH_QUEUE_SERIAL);
    });
    
    it(@"Should have specific value set to self and detect if already running on queue", ^{
        /*[[@(dispatch_get_specific((__bridge const void *)queue) != NULL) should] beNo];
        [[@(dispatch_is_on_specific_queue(queue)) should] beNo];
        dispatch_sync(queue, ^{
            [[@(dispatch_get_specific((__bridge const void *)queue) != NULL) should] beYes];
            [[@(dispatch_is_on_specific_queue(queue)) should] beYes];
        });*/
    });
    
    it(@"Should have properly functioning arrays", ^{
        NSMutableArray *foo1 = [NSMutableArray array];
        foo1[0] = @"a";
        foo1[1] = @"b";
        foo1[2] = @"c";
        [[foo1[0] should] equal:@"a"];
        [[foo1[1] should] equal:@"b"];
        [[foo1[2] should] equal:@"c"];
        foo1[0] = @"z";
        [[foo1[0] should] equal:@"z"];
        [[foo1[1] should] equal:@"b"];
        [[foo1[2] should] equal:@"c"];
        
        NSMutableArray *foo2 = [NSMutableArray array];
        [foo2 addObject:@"a"];
        [foo2 addObject:@"b"];
        [foo2 addObject:@"c"];
        [[foo2[0] should] equal:@"a"];
        [[foo2[1] should] equal:@"b"];
        [[foo2[2] should] equal:@"c"];
        [[[NSNumber numberWithUnsignedInteger:[foo2 count]] should] equal:@3];
        foo2[0] = @"z";
        [[foo2[0] should] equal:@"z"];
        [[foo2[1] should] equal:@"b"];
        [[foo2[2] should] equal:@"c"];
        [[[NSNumber numberWithUnsignedInteger:[foo2 count]] should] equal:@3];
    });
    
    it(@"Should never result in deadlock", ^{
        __block BOOL deadlock = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            ShouldNotBeOnSpecificQueue(queue);
            so_dispatch_specific_sync(queue, ^{
                ShouldBeOnSpecificQueue(queue);
                so_dispatch_specific_async(queue, ^{
                    ShouldBeOnSpecificQueue(queue);
                    so_dispatch_specific_sync(queue, ^{
                        ShouldBeOnSpecificQueue(queue);
                        deadlock = NO;
                    });
                });
            });
        });
        [[expectFutureValue(@(deadlock)) shouldEventually] beNo];
    });
    
    it(@"Should always run block synchronously if already on queue", ^{
        dispatch_sync(queue, ^{
            ShouldBeOnSpecificQueue(queue);
            // Sanity check assumptions with dispatch_async
            __block BOOL blockRan = NO;
            dispatch_async(queue, MarkerBlock);
            [[@(blockRan) should] beNo];
            
            blockRan = NO;
            so_dispatch_specific_sync(queue, MarkerBlock);
            [[@(blockRan) should] beYes];
            
            blockRan = NO;
            so_dispatch_specific_async(queue, MarkerBlock);
            [[@(blockRan) should] beYes];
        });
    });
    
    it(@"Should dispatch_async if not on queue and async desired", ^{
        [[@(so_dispatch_is_on_specific_queue(queue)) should] beNo];
        __block BOOL blockRan = NO;
        so_dispatch_specific_async(queue, MarkerBlock);
        [[@(blockRan) should] beNo];
        [[expectFutureValue(@(blockRan)) shouldEventually] beYes];
    });
    
    it(@"Should dispatch_sync if not on queue and sync desired", ^{
        [[@(so_dispatch_is_on_specific_queue(queue)) should] beNo];
        __block BOOL blockRan = NO;
        so_dispatch_specific_sync(queue, MarkerBlock);
        [[@(blockRan) should] beYes];
    });
});

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