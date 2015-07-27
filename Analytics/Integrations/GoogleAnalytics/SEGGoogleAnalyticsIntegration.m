// GoogleAnalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.


#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import "SEGGoogleAnalyticsIntegration.h"


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
        self.gai = [GAI sharedInstance];
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
    _tracker = [_gai trackerWithTrackingId:trackingId];
    [_gai setDefaultTracker:_tracker];

    // Optionally turn on uncaught exception tracking.
    NSString *reportUncaughtExceptions = [self.settings objectForKey:@"reportUncaughtExceptions"];
    if ([reportUncaughtExceptions boolValue]) {
        [_gai setTrackUncaughtExceptions:YES];
    }

    // Optionally turn on GA remarketing features
    NSString *demographicReports = [self.settings objectForKey:@"doubleClick"];
    if ([demographicReports boolValue]) {
        [_tracker setAllowIDFACollection:YES];
    }

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

    // Optionally send the userId if they have that enabled
    if ([self shouldSendUserId]) {
        [_tracker set:@"&uid" value:userId];
    }

    // We can set traits though. Iterate over a ll the traits and set them.
    self.traits = traits;

    [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [_tracker set:key value:obj];
    }];
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

    // Track the event!
    [_tracker send:
                  [[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:event
                                                           label:label
                                                           value:value] build]];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [_tracker set:kGAIScreenName value:screenTitle];
    [_tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

#pragma mark - Ecommerce

- (void)completedOrder:(NSDictionary *)properties
{
    NSString *orderId = properties[@"orderId"];
    NSString *currency = properties[@"currency"] ?: @"USD";

    SEGLog(@"Tracking completed order to Google Analytics with properties: %@", properties);

    [_tracker send:[[GAIDictionaryBuilder createTransactionWithId:orderId
                                                      affiliation:properties[@"affiliation"]
                                                          revenue:[self.class extractRevenue:properties]
                                                              tax:properties[@"tax"]
                                                         shipping:properties[@"shipping"]
                                                     currencyCode:currency] build]];

    [_tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:orderId
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

    [_tracker set:@"&uid" value:nil];

    [self resetTraits];
}


- (void)flush
{
    [_gai dispatch];
}

#pragma mark - Private

- (BOOL)shouldSendUserId
{
    return [[self.settings objectForKey:@"sendUserId"] boolValue];
}

- (void)resetTraits
{
    [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      [_tracker set:key value:nil];
    }];
    self.traits = nil;
}

@end
