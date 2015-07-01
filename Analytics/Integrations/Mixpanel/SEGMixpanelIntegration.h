// MixpanelIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

// Import the base class SEGAnalyticsIntegration
#import "SEGAnalyticsIntegration.h"

/* Declaration for the Mixpanel integration.
 * It will be conditionally compiled by being imported in SEGAnalyticsIntegrations.
 * All integrations extend from the SEGAnalyticsIntegration base class, which already
 * defines all the methods integrations can implement.
 * Any other publically accessible properties (such as for testing) should be declared here.
 */
@interface SEGMixpanelIntegration : SEGAnalyticsIntegration

@property Class mixpanelClass;

@end
