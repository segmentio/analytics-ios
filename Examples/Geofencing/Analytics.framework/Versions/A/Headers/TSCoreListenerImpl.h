#pragma once
#import <Foundation/Foundation.h>
#import "TSCoreListener.h"

@interface TSCoreListenerImpl : NSObject<TSCoreListener> {}

- (void)reportOperation:(NSString *)op;
- (void)reportOperation:(NSString *)op arg:(NSString *)arg;

@end
