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
- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context;

@end
