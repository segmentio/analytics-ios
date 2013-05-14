// Provider.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface Provider : NSObject


// Enabled State
// -------------

- (void)enable;
- (void)disable;


// Initialization
// --------------

- (void)setSettings:(NSDictionary *)settings;


// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;
- (void)alias:(NSString *)from to:(NSString *)to;

@end
