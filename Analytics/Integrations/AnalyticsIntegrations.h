//
//  AnalyticsIntegrations.h
//  Analytics
//
//  Created by Travis Jeffery on 5/2/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#ifdef USE_ANALYTICS_AMPLITUDE
#import "AmplitudeIntegration.h"
#endif

#ifdef USE_ANALYTICS_BUGSNAG
#import "BugsnagIntegration.h"
#endif

#ifdef USE_ANALYTICS_COUNTLY
#import "CountlyIntegration.h"
#endif

#ifdef USE_ANALYTICS_CRITTERCISM
#import "CrittercismIntegration.h"
#endif

#ifdef USE_ANALYTICS_FLURRY
#import "FlurryIntegration.h"
#endif

#ifdef USE_ANALYTICS_GOOGLEANALYTICS
#import "GoogleAnalyticsIntegration.h"
#endif

#ifdef USE_ANALYTICS_LOCALYTICS
#import "LocalyticsIntegration.h"
#endif

#ifdef USE_ANALYTICS_MIXPANEL
#import "MixpanelIntegration.h"
#endif

#ifdef USE_ANALYTICS_TAPSTREAM
#import "TapstreamIntegration.h"
#endif

#ifdef USE_ANALYTICS_QUANTCAST
#import "QuantcastIntegration.h"
#endif

#ifdef USE_ANALYTICS_SEGMENTIO
#import "SegmentioIntegration.h"
#endif

