// ProviderManager.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface ProviderManager : NSObject

// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context;


// Application state API
// ---------------------

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;


// Initialization
// --------------

+ (instancetype)withSecret:(NSString *)secret;

- (id)initWithSecret:(NSString *)secret;

@end
