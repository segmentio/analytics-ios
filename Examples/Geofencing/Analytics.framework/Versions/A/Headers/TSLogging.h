#pragma once
#import <Foundation/Foundation.h>
#import "TSLogLevel.h"

@interface TSLogging : NSObject {
}

+ (void)setLogger:(void(^)(int logLevel, NSString *msg))logger;
+ (void)logAtLevel:(TSLoggingLevel)level format:(NSString *)format, ...;

@end
