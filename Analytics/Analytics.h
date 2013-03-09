// Analytics.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface Analytics : NSObject



// Initialization
// --------------

+ (id)createSharedInstance:(NSString *)secret;
+ (id)getSharedInstance;

- (void)reset;



// Analytics API 
// -------------

- (void)identify:(NSString *)userId;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;

- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;



// Utilities
// ---------

- (void)flush;


@end
