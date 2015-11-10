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
        SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"MlTmISmburwl2nN9o3NFpGfElujcfb0q"];
        [SEGAnalytics setupWithConfiguration:configuration];
        analytics = [SEGAnalytics sharedAnalytics];
    });

    it(@"initialized correctly", ^{
        expect(analytics.configuration.flushAt).to.equal(20);
        expect(analytics.configuration.writeKey).to.equal(@"MlTmISmburwl2nN9o3NFpGfElujcfb0q");
        expect(analytics.configuration.shouldUseLocationServices).to.equal(@NO);
        expect(analytics.configuration.enableAdvertisingTracking).to.equal(@YES);
    });
});

SpecEnd
