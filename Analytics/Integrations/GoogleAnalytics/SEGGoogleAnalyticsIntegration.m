// GoogleAnalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.


#import <GoogleAnalytics/GAIDictionaryBuilder.h>
#import <GoogleAnalytics/GAIFields.h>
#import <GoogleAnalytics/GAI.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import "SEGGoogleAnalyticsIntegration.h"


@interface SEGGoogleAnalyticsIntegration ()

@property (nonatomic, copy) NSDictionary *traits;
@property (nonatomic, assign) id<GAITracker> tracker;

@end


@implementation SEGGoogleAnalyticsIntegration

#pragma mark - Initialization

+ (void)load
{
    [SEGAnalytics registerIntegration:self withIdentifier:@"Google Analytics"];
}

- (id)init
{
    if (self = [super init]) {
        self.name = @"Google Analytics";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start
{
    // Google Analytics needs to be initialized on the main thread, but
    // dispatch-ing to the main queue when already on the main thread
    // causes the initialization to happen async. After first startup
    // we need the initialization to be synchronous.
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
        return;
    }
    // Require setup with the trackingId.
    NSString *trackingId = [self.settings objectForKey:@"mobileTrackingId"];
    self.tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingId];
    [[GAI sharedInstance] setDefaultTracker:self.tracker];

    // Optionally turn on uncaught exception tracking.
    NSString *reportUncaughtExceptions = [self.settings objectForKey:@"reportUncaughtExceptions"];
    if ([reportUncaughtExceptions boolValue]) {
        [GAI sharedInstance].trackUncaughtExceptions = YES;
    }

    // Optionally turn on GA remarketing features
    NSString *demographicReports = [self.settings objectForKey:@"doubleClick"];
    if ([demographicReports boolValue]) {
        [self.tracker setAllowIDFACollection:YES];
    }

    // TODO: add support for sample rate

    // All done!
    SEGLog(@"GoogleAnalyticsIntegration initialized.");
    [super start];
}


#pragma mark - Settings

- (void)validate
{
    // All that's required is the trackingId.
    BOOL hasTrackingId = [self.settings objectForKey:@"mobileTrackingId"] != nil;
    self.valid = hasTrackingId;
}


#pragma mark - Analytics API

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options
{
    // remove existing traits
    [self resetTraits];

    if ([self shouldSendUserId]) {
        [self.tracker set:@"&uid" value:userId];
    }

    self.traits = traits;

    [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [self.tracker set:key value:obj];
    }];

    [self setCustomDimensionsAndMetricsOnDefaultTracker:traits];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [super track:event properties:properties options:options];

    // Try to extract a "category" property.
    NSString *category = @"All"; // default
    NSString *categoryProperty = [properties objectForKey:@"category"];
    if (categoryProperty) {
        category = categoryProperty;
    }

    // Try to extract a "label" property.
    NSString *label = [properties objectForKey:@"label"];

    // Try to extract a "revenue" or "value" property.
    NSNumber *value = [SEGAnalyticsIntegration extractRevenue:properties];
    NSNumber *valueFallback = [SEGAnalyticsIntegration extractRevenue:properties withKey:@"value"];
    if (!value && valueFallback) {
        // fall back to the "value" property
        value = valueFallback;
    }

    SEGLog(@"Sending to Google Analytics: category %@, action %@, label %@, value %@", category, event, label, value);

    GAIDictionaryBuilder *hit =
        [GAIDictionaryBuilder createEventWithCategory:category
                                               action:event
                                                label:label
                                                value:value];

    // Track the event!
    [self.tracker send:[self setCustomDimensionsAndMetrics:properties onHit:hit]];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [self.tracker set:kGAIScreenName value:screenTitle];
    GAIDictionaryBuilder *view = [GAIDictionaryBuilder createScreenView];
    [self.tracker send:[self setCustomDimensionsAndMetrics:properties onHit:view]];
}

#pragma mark - Ecommerce

- (void)completedOrder:(NSDictionary *)properties
{
    NSString *orderId = properties[@"orderId"];
    NSString *currency = properties[@"currency"] ?: @"USD";

    SEGLog(@"Tracking completed order to Google Analytics with properties: %@", properties);

    [self.tracker
        send:[[GAIDictionaryBuilder createTransactionWithId:orderId
                                                affiliation:properties[@"affiliation"]
                                                    revenue:[self.class extractRevenue:properties]
                                                        tax:properties[@"tax"]
                                                   shipping:properties[@"shipping"]
                                               currencyCode:currency] build]];

    [self.tracker
        send:[[GAIDictionaryBuilder createItemWithTransactionId:orderId
                                                           name:properties[@"name"]
                                                            sku:properties[@"sku"]
                                                       category:properties[@"category"]
                                                          price:properties[@"price"]
                                                       quantity:properties[@"quantity"]
                                                   currencyCode:currency] build]];
}

- (void)reset
{
    [super reset];

    [self.tracker set:@"&uid" value:nil];

    [self resetTraits];
}


- (void)flush
{
    [[GAI sharedInstance] dispatch];
}

#pragma mark - Private

// event and screen properties are generall hit-scoped dimensions, so we want
// to set them on the hits, not the tracker
- (NSDictionary *)setCustomDimensionsAndMetrics:(NSDictionary *)properties onHit:(GAIDictionaryBuilder *)hit
{
    NSDictionary *customDimensions = self.settings[@"dimensions"];
    NSDictionary *customMetrics = self.settings[@"metrics"];

    for (NSString *key in properties) {
        NSString *dimensionString = [customDimensions objectForKey:key];
        // [@"dimension" length] == 8
        NSUInteger dimension = [self extractNumber:dimensionString from:8];
        if (dimension != 0) {
            [hit set:[properties objectForKey:key]
                forKey:[GAIFields customDimensionForIndex:dimension]];
        }

        NSString *metricString = [customMetrics objectForKey:key];
        // [@"metric" length] == 5
        NSUInteger metric = [self extractNumber:metricString from:5];
        if (metric != 0) {
            [hit set:[properties objectForKey:key]
                forKey:[GAIFields customMetricForIndex:metric]];
        }
    }

    return [hit build];
}

// e.g. extractNumber("dimension3", 8) returns 3
// e.g. extractNumber("dimension9", 8) returns 9
- (int)extractNumber:(NSString *)text from:(NSUInteger)start
{
    if (text == nil || [text length] == 0) {
        return 0;
    }
    return [[text substringFromIndex:start] intValue];
}

// traits are user-scoped dimensions. as such, it makes sense to set them on the tracker
- (void)setCustomDimensionsAndMetricsOnDefaultTracker:(NSDictionary *)traits
{
    NSDictionary *customDimensions = self.settings[@"dimensions"];
    NSDictionary *customMetrics = self.settings[@"metrics"];

    for (NSString *key in traits) {
        NSString *dimensionString = [customDimensions objectForKey:key];
        // [@"dimension" length] == 8
        NSUInteger dimension = [self extractNumber:dimensionString from:8];
        if (dimension != 0) {
            [self.tracker set:[GAIFields customDimensionForIndex:dimension]
                        value:[traits objectForKey:key]];
        }

        NSString *metricString = [customMetrics objectForKey:key];
        // [@"metric" length] == 5
        NSUInteger metric = [self extractNumber:metricString from:5];
        if (metric != 0) {
            [self.tracker set:[GAIFields customMetricForIndex:metric]
                        value:[traits objectForKey:key]];
        }
    }
}

- (BOOL)shouldSendUserId
{
    return [[self.settings objectForKey:@"sendUserId"] boolValue];
}

- (void)resetTraits
{
    [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [self.tracker set:key value:nil];
    }];
    self.traits = nil;
}

@end
