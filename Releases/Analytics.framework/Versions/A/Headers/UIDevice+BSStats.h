//
//  UIDevice+BSStats.h
//  Bugsnag Notifier
//
//  Created by Simon Maynard on 12/6/12.
//
//

#import <UIKit/UIKit.h>

@interface UIDevice (BSStats)
+ (NSString*) platform;
+ (NSString *) osVersion;
+ (NSString *) arch;
+ (NSDictionary *) memoryStats;
+ (NSNumber *)uptime;
@end
