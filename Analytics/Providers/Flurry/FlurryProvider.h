// FlurryProvider.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>
#import "AnalyticsProvider.h"


@interface FlurryProvider : AnalyticsProvider

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, strong) NSDictionary *settings;

@end
