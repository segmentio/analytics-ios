// ProviderManager.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface ProviderManager : NSObject


// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;
- (void)alias:(NSString *)from to:(NSString *)to;


// Initialization
// --------------

+ (instancetype)withSecret:(NSString *)secret;

- (id)initWithSecret:(NSString *)secret;

@end
