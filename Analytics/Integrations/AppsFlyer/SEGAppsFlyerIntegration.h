//
//  SEGAppsFlyerIntegration.h
//  Analytics
//
//  Created by Travis Jeffery on 8/27/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGAnalyticsIntegration.h"
#import <AppsFlyer-SDK/AppsFlyerTracker.h>


@interface SEGAppsFlyerIntegration : SEGAnalyticsIntegration

@property AppsFlyerTracker *appsFlyer;

@end
