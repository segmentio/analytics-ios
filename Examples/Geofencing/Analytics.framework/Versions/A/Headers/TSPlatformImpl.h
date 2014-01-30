#pragma once
#import <Foundation/Foundation.h>
#import "TSPlatform.h"
#import "TSResponse.h"

@interface TSPlatformImpl : NSObject<TSPlatform> {}

- (NSString *)loadUuid;
- (NSMutableSet *)loadFiredEvents;
- (void)saveFiredEvents:(NSMutableSet *)firedEvents;
- (NSString *)getResolution;
- (NSString *)getManufacturer;
- (NSString *)getModel;
- (NSString *)getOs;
- (NSString *)getLocale;
- (NSString *)getWifiMac;
- (NSString *)getAppName;
- (NSString *)getAppVersion;
- (NSString *)getPackageName;
- (TSResponse *)request:(NSString *)url data:(NSString *)data method:(NSString *)method;
- (NSSet *)getProcessSet;
@end
