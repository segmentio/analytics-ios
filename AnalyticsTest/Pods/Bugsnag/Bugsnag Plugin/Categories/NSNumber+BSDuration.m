//
//  NSNumber+BSDuration
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/7/12.
//
//

#import "NSNumber+BSDuration.h"

@implementation NSNumber (BSDuration)

- (NSString *) durationString {
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:-[self intValue]];
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    unsigned int unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit | NSSecondCalendarUnit | NSYearCalendarUnit;
    
    NSDateComponents *conversionInfo = [sysCalendar components:unitFlags fromDate:date toDate:[NSDate date] options:0];
    NSMutableString *result = [[NSMutableString alloc] init];
    int entries = 0;
    
    if (conversionInfo.year) {
        [result appendFormat:@"%d years", conversionInfo.year];
        entries++;
    }
    
    if (entries < 2 && conversionInfo.month) {
        if (entries == 0) {
            [result appendFormat:@"%d months", conversionInfo.month];
        } else {
            [result appendFormat:@" and %d months", conversionInfo.month];
        }
        entries++;
    }
    
    if (entries < 2 && conversionInfo.day) {
        if (entries == 0) {
            [result appendFormat:@"%d days", conversionInfo.day];
        } else {
            [result appendFormat:@" and %d days", conversionInfo.day];
        }
        entries++;
    }
    
    if (entries < 2 && conversionInfo.minute) {
        if (entries == 0) {
            [result appendFormat:@"%d minutes", conversionInfo.minute];
        } else {
            [result appendFormat:@" and %d minutes", conversionInfo.minute];
        }
        entries++;
    }
    
    if (entries < 2 && conversionInfo.second) {
        if (entries == 0) {
            [result appendFormat:@"%d seconds", conversionInfo.second];
        } else {
            [result appendFormat:@" and %d seconds", conversionInfo.second];
        }
        entries++;
    }
    
    return result;
}

@end
