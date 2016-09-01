#import <Analytics/SEGAnalytics.h>
#import <Foundation/Foundation.h>

SpecBegin(Analytics);

describe(@"analytics", ^{
    __block SEGAnalytics *analytics = nil;

    beforeEach(^{
        SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE"];
        [SEGAnalytics setupWithConfiguration:configuration];
        analytics = [SEGAnalytics sharedAnalytics];
    });

    it(@"initialized correctly", ^{
        expect(analytics.configuration.flushAt).to.equal(20);
        expect(analytics.configuration.writeKey).to.equal(@"QUI5ydwIGeFFTa1IvCBUhxL9PyW5B0jE");
        expect(analytics.configuration.shouldUseLocationServices).to.equal(@NO);
        expect(analytics.configuration.enableAdvertisingTracking).to.equal(@YES);
    });
});

SpecEnd
