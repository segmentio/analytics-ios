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
        expect(analytics.configuration.writeKey).to.equal(@"dpu3lo79nb");
        expect(analytics.configuration.shouldUseLocationServices).to.equal(@NO);
        expect(analytics.configuration.enableAdvertisingTracking).to.equal(@YES);
    });
});

SpecEnd
