// AnalyticsIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

@class SEGAnalytics;
@class SEGAnalyticsConfiguration;

extern NSString *SEGAnalyticsIntegrationDidStart;

@protocol SEGAnalyticsIntegration <NSObject>

// State
// -----

- (NSString *)name;
- (BOOL)ready;
- (void)updateSettings:(NSDictionary *)settings;

@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) BOOL initialized;

// Analytics API
// -------------


// Identify will be called when the user calls either of the following:
// 1. [[SEGAnalytics sharedInstance] identify:someUserId];
// 2. [[SEGAnalytics sharedInstance] identify:someUserId traits:someTraits];
// 3. [[SEGAnalytics sharedInstance] identify:someUserId traits:someTraits options:someOptions];
// @see https://segment.com/docs/spec/identify/
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options;

// Track will be called when the user calls either of the following:
// 1. [[SEGAnalytics sharedInstance] track:someEvent];
// 2. [[SEGAnalytics sharedInstance] track:someEvent properties:someProperties];
// 3. [[SEGAnalytics sharedInstance] track:someEvent properties:someProperties options:someOptions];
// @see https://segment.com/docs/spec/track/
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options;

// Screen will be called when the user calls either of the following:
// 1. [[SEGAnalytics sharedInstance] screen:someEvent];
// 2. [[SEGAnalytics sharedInstance] screen:someEvent properties:someProperties];
// 3. [[SEGAnalytics sharedInstance] screen:someEvent properties:someProperties options:someOptions];
// @see https://segment.com/docs/spec/screen/
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options;


// Group will be called when the user calls either of the following:
// 1. [[SEGAnalytics sharedInstance] group:someGroupId];
// 2. [[SEGAnalytics sharedInstance] group:someGroupId traits:];
// 3. [[SEGAnalytics sharedInstance] group:someGroupId traits:someGroupTraits options:someOptions];
// @see https://segment.com/docs/spec/group/
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options;

// Alias will be called when the user calls either of the following:
// 1. [[SEGAnalytics sharedInstance] alias:someNewId];
// 2. [[SEGAnalytics sharedInstance] alias:someNewId options:someOptions];
// @see https://segment.com/docs/spec/alias/
- (void)alias:(NSString *)newId options:(NSDictionary *)options;

// Reset is invoked when the user logs out, and any data saved about the user should be cleared.
- (void)reset;

// Flush is invoked when any queued events should be uploaded.
- (void)flush;

@optional
;

- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options;

// Callbacks for app state changes
// -------------------------------

- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end


@interface SEGAnalyticsIntegration : NSObject <SEGAnalyticsIntegration>

- (id)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration;

@property (nonatomic, strong) SEGAnalyticsConfiguration *configuration;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSDictionary *settings;
@property (nonatomic, assign) BOOL valid;
@property (nonatomic, assign) BOOL initialized;

- (void)validate;
- (void)start;
- (void)stop;


// Utilities
// ---------

+ (NSDictionary *)map:(NSDictionary *)dictionary withMap:(NSDictionary *)map;
+ (NSString *)extractEmail:(NSString *)userId traits:(NSDictionary *)traits;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)key;

@end
