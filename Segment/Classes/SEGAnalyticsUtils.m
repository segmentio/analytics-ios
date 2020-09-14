#import "SEGAnalyticsUtils.h"
#import "SEGAnalytics.h"
#import "SEGUtils.h"

static BOOL kAnalyticsLoggerShowLogs = NO;

#pragma mark - Logging

void SEGSetShowDebugLogs(BOOL showDebugLogs)
{
    kAnalyticsLoggerShowLogs = showDebugLogs;
}

void SEGLog(NSString *format, ...)
{
    if (!kAnalyticsLoggerShowLogs)
        return;

    va_list args;
    va_start(args, format);
    NSLogv(format, args);
    va_end(args);
}

#pragma mark - Serialization Extensions

@interface NSDate(SEGSerializable)<SEGSerializable>
- (id)serializeToAppropriateType;
@end

@implementation NSDate(SEGSerializable)
- (id)serializeToAppropriateType
{
    return iso8601FormattedString(self);
}
@end

@interface NSURL(SEGSerializable)<SEGSerializable>
- (id)serializeToAppropriateType;
@end

@implementation NSURL(SEGSerializable)
- (id)serializeToAppropriateType
{
    return [self absoluteString];
}
@end


