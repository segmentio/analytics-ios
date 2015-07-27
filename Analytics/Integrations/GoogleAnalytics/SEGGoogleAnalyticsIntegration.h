// GoogleAnalyticsIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"
#import "SEGEcommerce.h"
#import <GoogleAnalytics/GAI.h>
#import <GoogleAnalytics/GAIDictionaryBuilder.h>
#import <GoogleAnalytics/GAIFields.h>


@interface SEGGoogleAnalyticsIntegration : SEGAnalyticsIntegration <SEGEcommerce>

@property id<GAITracker> tracker;
@property GAI *gai;
@property (nonatomic, copy) NSDictionary *traits;

- (void)resetTraits;

@end
