// SettingsCache.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


// SettingsCacheListenerDelegate

@interface SettingsCacheListenerDelegate : NSObject

- (void)onSettingsUpdate:(NSDictionary *)settings;

@end




// SettingsCache

@interface SettingsCache : NSObject

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) SettingsCacheListenerDelegate *delegate;

+ (instancetype)sharedSettingsCacheWithSecret:(NSString *)secret;
+ (instancetype)sharedSettingsCacheWithSecret:(NSString *)secret delegate:(SettingsCacheListenerDelegate *)delegate;
+ (instancetype)sharedSettingsCache;

- (id)initWithSecret:(NSString *)secret delegate:(SettingsCacheListenerDelegate *)delegate;

- (void)updateSettings;
- (NSDictionary *)getSettings;

@end
