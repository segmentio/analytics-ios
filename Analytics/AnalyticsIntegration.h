// AnalyticsIntegration.h
// Copyright (c) 2014 Segment.io. All rights reserved.

#import <Foundation/Foundation.h>

@class Analytics;

@protocol AnalyticsIntegration <NSObject>

- (id)initWithAnalytics:(Analytics *)analytics;

// State
// -----

- (NSString *)name;
- (BOOL)ready;
- (void)updateSettings:(NSDictionary *)settings;

// Analytics API
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options;
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options;
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options;
- (void)reset;

@optional;

- (void)registerPushDeviceToken:(NSData *)deviceToken;

// Callbacks for app state changes
// -------------------------------

- (void)applicationDidFinishLaunching;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end

@interface AnalyticsIntegration : NSObject <AnalyticsIntegration>

@property(nonatomic, copy) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, copy) NSDictionary *settings;

- (void)validate;
- (void)start;
- (void)stop;


// Utilities
// ---------

+ (NSDictionary *)map:(NSDictionary *)dictionary withMap:(NSDictionary *)map;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)key;

@end
