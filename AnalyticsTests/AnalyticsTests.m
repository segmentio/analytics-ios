//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Created by Tony Xiao on 8/23/13.
//  Copyright (c) 2013 Segment.io. All rights reserved.
//

#import <Kiwi/Kiwi.h>

SPEC_BEGIN(MathSpec)

describe(@"Math", ^{
    it(@"is pretty cool", ^{
        NSUInteger a = 16;
        NSUInteger b = 26;
        [[theValue(a + b) should] equal:theValue(42)];
    });
});

SPEC_END