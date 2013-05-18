// Analytics.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>
#import "ProviderManager.h"

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


// Utilities
// ---------

- (void)reset;


// Initialization
// --------------

+ (instancetype)withSecret:(NSString *)secret;
+ (instancetype)sharedAnalytics;

- (id)initWithSecret:(NSString *)secret;

@end
