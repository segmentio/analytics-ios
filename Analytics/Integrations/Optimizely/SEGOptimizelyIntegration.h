//
//  SEGOptmizelyIntegration.h
//  Analytics
//
//  Created by Travis Jeffery on 7/16/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGAnalyticsIntegration.h"


@interface SEGOptimizelyIntegration : SEGAnalyticsIntegration

@property Class optimizelyClass;
@property (nonatomic, assign) BOOL needsToActivateMixpanel;

@end
