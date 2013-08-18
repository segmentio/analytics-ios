// SettingsCache.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


// SettingsCacheDelegate

@protocol SettingsCacheDelegate <NSObject>

- (void)onSettingsUpdate:(NSDictionary *)settings;

@end




// SettingsCache

@interface SettingsCache : NSObject

+ (instancetype)withSecret:(NSString *)secret;
+ (instancetype)withSecret:(NSString *)secret delegate:(id<SettingsCacheDelegate>)delegate;

- (id)initWithSecret:(NSString *)secret delegate:(id<SettingsCacheDelegate>)delegate;

- (void)clear;
- (void)update;
- (NSDictionary *)getSettings;

@end
