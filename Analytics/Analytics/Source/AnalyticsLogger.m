
// AnalyticsLogger.m
// Copyright 2013 Segment.io

#import "AnalyticsLogger.h"

static BOOL kAnalyticsLoggerShowLogs = NO;


@interface AnalyticsLogger ()
@end

@implementation AnalyticsLogger

+ (void)showDebugLogs:(BOOL)showDebugLogs
{
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

+ (void)log:(NSString *)format, ...
{
    if (kAnalyticsLoggerShowLogs) {
        va_list args;
        va_start(args, format);
        NSLogv(format, args);
        va_end(args);
    }
}

@end