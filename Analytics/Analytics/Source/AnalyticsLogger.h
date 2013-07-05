// AnalyticsLogger.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>

@interface AnalyticsLogger : NSObject

+ (void)showDebugLogs:(BOOL)showDebugLogs;
+ (void)log:(NSString *)format, ...;

@end
