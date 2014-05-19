//
//  AnalyticsIntegrations.h
//  Analytics
//
//  Created by Travis Jeffery on 5/2/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#ifdef USE_ANALYTICS_AMPLITUDE
#import "SEGAmplitudeIntegration.h"
#endif

#ifdef USE_ANALYTICS_BUGSNAG
#import "SEGBugsnagIntegration.h"
#endif

#ifdef USE_ANALYTICS_COUNTLY
#import "SEGCountlyIntegration.h"
#endif

#ifdef USE_ANALYTICS_CRITTERCISM
#import "SEGCrittercismIntegration.h"
#endif

#ifdef USE_ANALYTICS_FLURRY
#import "SEGFlurryIntegration.h"
#endif

#ifdef USE_ANALYTICS_GOOGLEANALYTICS
#import "SEGGoogleAnalyticsIntegration.h"
#endif

#ifdef USE_ANALYTICS_LOCALYTICS
#import "SEGLocalyticsIntegration.h"
#endif

#ifdef USE_ANALYTICS_MIXPANEL
#import "SEGMixpanelIntegration.h"
#endif

#ifdef USE_ANALYTICS_TAPSTREAM
#import "SEGTapstreamIntegration.h"
#endif

#ifdef USE_ANALYTICS_QUANTCAST
#import "SEGQuantcastIntegration.h"
#endif

#ifdef USE_ANALYTICS_SEGMENTIO
#import "SEGSegmentioIntegration.h"
#endif

