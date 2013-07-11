// Analytics.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>
#import "ProviderManager.h"

#define ANALYTICS_VERSION @"0.5.1"

@interface Analytics : NSObject

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) ProviderManager *providerManager;


// Analytics API 
// -------------

- (void)identify:(NSString *)userId;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context;

- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;

- (void)screen:(NSString *)screenTitle;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context;


// Application state API
// ---------------------

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;


// Utilities
// ---------

- (void)reset;
- (void)debug:(BOOL)showDebugLogs;


// Initialization
// --------------

+ (instancetype)withSecret:(NSString *)secret;
+ (instancetype)sharedAnalytics;

- (id)initWithSecret:(NSString *)secret;

@end
