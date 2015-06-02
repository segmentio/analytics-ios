// GoogleAnalyticsIntegration.m
// Copyright (c) 2014 Segment.io. All rights reserved.


#import <GoogleAnalytics-iOS-SDK/GAIDictionaryBuilder.h>
#import <GoogleAnalytics-iOS-SDK/GAIFields.h>
#import <GoogleAnalytics-iOS-SDK/GAI.h>
#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import "SEGGoogleAnalyticsIntegration.h"

@interface SEGGoogleAnalyticsIntegration ()

@property (nonatomic, copy) NSDictionary *traits;

@end

@implementation SEGGoogleAnalyticsIntegration

#pragma mark - Initialization

+ (void)load {
    [SEGAnalytics registerIntegration:self withIdentifier:@"Google Analytics"];
}

- (id)init {
    if (self = [super init]) {
        self.name = @"Google Analytics";
        self.valid = NO;
        self.initialized = NO;
    }
    return self;
}

- (void)start {
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
    [[GAI sharedInstance] setDefaultTracker:[[GAI sharedInstance] trackerWithTrackingId:trackingId]];

    // Optionally turn on uncaught exception tracking.
    NSString *reportUncaughtExceptions = [self.settings objectForKey:@"reportUncaughtExceptions"];
    if ([reportUncaughtExceptions boolValue]) {
        [GAI sharedInstance].trackUncaughtExceptions = YES;
    }

    // Optionally turn on GA remarketing features
    NSString *demographicReports = [self.settings objectForKey:@"doubleClick"];
    if ([demographicReports boolValue]) {
      [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
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

    // Optionally send the userId if they have that enabled
    if ([self shouldSendUserId])
      [[[GAI sharedInstance] defaultTracker] set:@"&uid" value:userId];

    // We can set traits though. Iterate over a ll the traits and set them.
  self.traits = traits;

  [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [[[GAI sharedInstance] defaultTracker] set:key value:obj];
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
    [[[GAI sharedInstance] defaultTracker] send:
     [[GAIDictionaryBuilder createEventWithCategory:category
                                             action:event
                                              label:label
                                              value:value] build]];
}

- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options
{
    [[[GAI sharedInstance] defaultTracker] set:kGAIScreenName value:screenTitle];
    [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createAppView] build]];
}

#pragma mark - Ecommerce

- (void)completedOrder:(NSDictionary *)properties {
  NSString *orderId = properties[@"orderId"];
  NSString *currency = properties[@"currency"] ?: @"USD";

  SEGLog(@"Tracking completed order to Google Analytics with properties: %@", properties);

  [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createTransactionWithId:orderId
                                                                                affiliation:properties[@"affiliation"]
                                                                                    revenue:[self.class extractRevenue:properties]
                                                                                        tax:properties[@"tax"]
                                                                                   shipping:properties[@"shipping"]
                                                                               currencyCode:currency] build]];

  [[[GAI sharedInstance] defaultTracker] send:[[GAIDictionaryBuilder createItemWithTransactionId:orderId
                                                                                           name:properties[@"name"]
                                                                                            sku:properties[@"sku"]
                                                                                       category:properties[@"category"]
                                                                                          price:properties[@"price"]
                                                                                       quantity:properties[@"quantity"]
                                                                                   currencyCode:currency] build]];
}

- (void)reset {
  [super reset];

  [[[GAI sharedInstance] defaultTracker] set:@"&uid" value:nil];

  [self resetTraits];
}


- (void)flush {
  [[GAI sharedInstance] dispatch];
}

#pragma mark - Private

- (BOOL)shouldSendUserId {
  return [[self.settings objectForKey:@"sendUserId"] boolValue];
}

- (void)resetTraits {
  [self.traits enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    [[[GAI sharedInstance] defaultTracker] set:key value:nil];
  }];
  self.traits = nil;
}

@end
