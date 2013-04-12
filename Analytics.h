// Analytics.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface AnalyticsListenerDelegate : NSObject

- (void)onAPISuccess;
- (void)onAPIFailure;

@end


@interface Analytics : NSObject

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *sessionId;
@property(nonatomic, assign) NSUInteger flushAt;
@property(nonatomic, assign) NSUInteger flushAfter;
@property(nonatomic, strong) AnalyticsListenerDelegate *delegate;



// Analytics API 
// -------------

- (void)identify:(NSString *)userId;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;

- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;

// Utilities
// ---------

- (void)flush;
- (void)reset;

// Initialization
// --------------

- (id)initWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter;

+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret;
+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret delegate:(AnalyticsListenerDelegate *)delegate;
+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter;
+ (instancetype)sharedAnalyticsWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter delegate:(AnalyticsListenerDelegate *)delegate;
+ (instancetype)sharedAnalytics;

@end
