// Provider.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>

@class Analytics;
@protocol AnalyticsProvider <NSObject>

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

@optional;

- (void)registerPushDeviceToken:(NSData *)deviceToken;

// Callbacks for app state changes
// -------------------------------

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end

@interface AnalyticsProvider : NSObject <AnalyticsProvider>

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, strong) NSDictionary *settings;


- (void)validate;
- (void)start;
- (void)stop;


// Utilities
// ---------

+ (NSDictionary *)map:(NSDictionary *)dictionary withMap:(NSDictionary *)map;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary;
+ (NSNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)key;

@end
