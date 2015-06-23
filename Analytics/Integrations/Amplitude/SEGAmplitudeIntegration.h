// AmplitudeProvider.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>
#import "SEGAnalyticsIntegration.h"
#import <Amplitude-iOS/Amplitude.h>


@interface SEGAmplitudeIntegration : SEGAnalyticsIntegration

@property (assign) Amplitude *amplitude;

@end
