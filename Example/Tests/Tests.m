//
//  AnalyticsTests.m
//  AnalyticsTests
//
//  Created by Prateek Srivastava on 11/02/2015.
//  Copyright (c) 2015 Prateek Srivastava. All rights reserved.
//

// https://github.com/Specta/Specta
#import <Analytics/SEGAnalytics.h>
#import <Specta/Specta.h>
#import <Foundation/Foundation.h>

SpecBegin(Analytics);

describe(@"analytics", ^{
    __block SEGAnalytics *analytics = nil;

    beforeEach(^{
        SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"dpu3lo79nb"];
        [SEGAnalytics setupWithConfiguration:configuration];
        analytics = [SEGAnalytics sharedAnalytics];
    });

    it(@"initialized correctly", ^{
        expect(analytics.configuration.flushAt).to.equal(20);
        expect(analytics.configuration.writeKey).to.equal(@"lBsvwzpkVaLE5TwyLU9nwlRMRKja9Wqw");
        expect(analytics.configuration.shouldUseLocationServices).to.equal(@NO);
        expect(analytics.configuration.enableAdvertisingTracking).to.equal(@YES);
    });
});

SpecEnd
