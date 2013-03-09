// DateFormat8601.m
// Copyright 2013 Segment.io

#import "DateFormat8601.h"

@implementation DateFormat8601

+ (NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormat setLocale:enUSPOSIXLocale];

    NSString *timestamp = [[dateFormat stringFromDate:date] stringByAppendingString:@"Z"];

    [enUSPOSIXLocale release];
    [dateFormat release];

    return timestamp;
}

@end