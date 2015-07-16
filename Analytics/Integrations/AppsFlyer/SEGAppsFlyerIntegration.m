//
//  SEGAppsFlyerIntegration.m
//  Analytics
//
//  Created by Travis Jeffery on 8/27/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGAppsFlyerIntegration.h"
#import "SEGAnalytics.h"
#import "SEGAnalyticsUtils.h"


@implementation SEGAppsFlyerIntegration

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:[self identifier]];
}

- (instancetype)init
{
    if (self = [super init]) {
        self.name = [self.class identifier];
        self.valid = NO;
        self.initialized = NO;
        self.appsFlyer = [AppsFlyerTracker sharedTracker];
    }
    return self;
}

- (void)validate
{
    self.valid = ([self devKey] != nil && [self appId] != nil);
}

- (void)start
{
    [self.appsFlyer setAppleAppID:[self appId]];
    [self.appsFlyer setAppsFlyerDevKey:[self devKey]];

    SEGLog(@"AppsFlyer: setup with appleAppId: %@, appsFlyerDevKey: %@", [self appId], [self devKey]);
    [super start];
}

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    if (userId) {
        [self.appsFlyer setCustomerUserID:userId];

        SEGLog(@"AppsFlyer: set customer id: %@", userId);
    }
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    NSNumber *revenue = [self.class extractRevenue:properties];
    NSString *currency = properties[@"currency"];
    if (currency) {
        [self.appsFlyer setCurrencyCode:currency];
    }
    [self.appsFlyer trackEvent:event
                     withValue:[revenue stringValue]];
    SEGLog(@"AppsFlyer: trackingEvent: %@, withValue: %@", event, revenue);
}

- (void)applicationDidBecomeActive
{
    [self.appsFlyer trackAppLaunch];
    SEGLog(@"AppsFlyer: tracked app launch");
}

#pragma mark - Private

- (NSString *)devKey
{
    return self.settings[@"appsFlyerDevKey"];
}

- (NSString *)appId
{
    return self.settings[@"appleAppID"];
}

+ (NSString *)identifier
{
    return @"AppsFlyer";
}

@end
