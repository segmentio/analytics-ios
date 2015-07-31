//
//  QuantcastProvider.h
//  Analytics
//
//  Created by Travis Jeffery on 4/26/14.
//  Copyright (c) 2014 Segment.io. All rights reserved.
//

#import "SEGAnalyticsIntegration.h"
#import <Quantcast-Measure/QuantcastMeasurement.h>


@interface SEGQuantcastIntegration : SEGAnalyticsIntegration

@property (assign) QuantcastMeasurement *quantcast;

@end
