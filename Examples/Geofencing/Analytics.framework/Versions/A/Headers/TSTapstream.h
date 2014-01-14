#pragma once
#import <Foundation/Foundation.h>
#import "TSApi.h"
#import "TSDelegate.h"
#import "TSPlatform.h"
#import "TSCoreListener.h"
#import "TSAppEventSource.h"
#import "TSCore.h"
#import "TSEvent.h"
#import "TSResponse.h"
#import "TSLogging.h"

@interface TSTapstream : NSObject<TSApi> {
@private
	id<TSDelegate> del;
	id<TSPlatform> platform;
	id<TSCoreListener> listener;
	id<TSAppEventSource> appEventSource;
	TSCore *core;
}

+ (void)createWithAccountName:(NSString *)accountName developerSecret:(NSString *)developerSecret config:(TSConfig *)config;
+ (id)instance;

- (void)fireEvent:(TSEvent *)event;
- (void)fireHit:(TSHit *)hit completion:(void(^)(TSResponse *))completion;
- (void)getConversionData:(void(^)(NSData *))completion;

@end
