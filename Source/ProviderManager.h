// ProviderManager.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface ProviderManager : NSObject

// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;
- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context;


// Initialization
// --------------

+ (instancetype)withSecret:(NSString *)secret;

- (id)initWithSecret:(NSString *)secret;

@end
