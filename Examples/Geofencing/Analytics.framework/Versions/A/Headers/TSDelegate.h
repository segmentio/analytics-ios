#pragma once
#import <Foundation/Foundation.h>

@protocol TSDelegate<NSObject>
- (int)getDelay;
- (void)setDelay:(int)delay;
- (BOOL)isRetryAllowed;
@end
