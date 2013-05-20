// Provider.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface Provider : NSObject

@property(nonatomic, strong) NSString *name;
@property(nonatomic, assign) BOOL enabled;
@property(nonatomic, assign) BOOL valid;
@property(nonatomic, assign) BOOL initialized;
@property(nonatomic, strong) NSDictionary *settings;

// Enabled State
// -------------

- (void)enable;
- (void)disable;

- (BOOL)ready;


// Initialization
// --------------

- (void)updateSettings:(NSDictionary *)settings;
- (void)validate;
- (void)start;


// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties context:(NSDictionary *)context;


// Callbacks for app state changes
// -------------------------------

- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationWillResignActive;
- (void)applicationDidBecomeActive;

@end
