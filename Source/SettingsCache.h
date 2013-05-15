// SettingsCache.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


// SettingsCacheDelegate

@interface SettingsCacheDelegate : NSObject

- (void)onSettingsUpdate:(NSDictionary *)settings async:(BOOL)async;

@end




// SettingsCache

@interface SettingsCache : NSObject

+ (instancetype)withSecret:(NSString *)secret;
+ (instancetype)withSecret:(NSString *)secret delegate:(SettingsCacheDelegate *)delegate;

- (id)initWithSecret:(NSString *)secret delegate:(SettingsCacheDelegate *)delegate;

- (void)clear;
- (void)update;
- (NSDictionary *)getSettings;

@end
