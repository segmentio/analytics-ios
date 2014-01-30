#pragma once
#import <Foundation/Foundation.h>

@interface TSUtils : NSObject

+ (NSString *)encodeString:(NSString *)s;

+ (NSString *)stringify:(id)value;
+ (NSString *)stringifyInteger:(int)value;
+ (NSString *)stringifyUnsignedInteger:(uint)value;
+ (NSString *)stringifyDouble:(double)value;
+ (NSString *)stringifyFloat:(float)value;
+ (NSString *)stringifyBOOL:(BOOL)value;
+ (NSString *)stringifyBool:(bool)value;

+ (NSString *)encodeEventPairWithPrefix:(NSString *)prefix key:(NSString *)key value:(id)value;

@end
