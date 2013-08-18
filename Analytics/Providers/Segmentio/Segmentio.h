// Segmentio.h
// Copyright 2013 Segment.io

#import <Foundation/Foundation.h>


@interface SegmentioListenerDelegate : NSObject

- (void)onAPISuccess;
- (void)onAPIFailure;

@end


@interface Segmentio : NSObject

@property(nonatomic, strong) NSString *secret;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *sessionId;
@property(nonatomic, assign) NSUInteger flushAt;
@property(nonatomic, assign) NSUInteger flushAfter;
@property(nonatomic, strong) SegmentioListenerDelegate *delegate;



// Analytics API 
// -------------

- (void)identify:(NSString *)userId traits:(NSDictionary *)traits context:(NSDictionary *)context;
- (void)track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;
- (void)alias:(NSString *)from to:(NSString *)to context:(NSDictionary *)context;

// Utilities
// ---------

- (NSString *)getSessionId;
- (void)flush;
- (void)reset;

// Initialization
// --------------

- (id)initWithSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter delegate:(SegmentioListenerDelegate *)delegate;

+ (instancetype)withSecret:(NSString *)secret;
+ (instancetype)withSecret:(NSString *)secret delegate:(SegmentioListenerDelegate *)delegate;
+ (instancetype)withSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter;
+ (instancetype)withSecret:(NSString *)secret flushAt:(NSUInteger)flushAt flushAfter:(NSUInteger)flushAfter delegate:(SegmentioListenerDelegate *)delegate;
+ (instancetype)sharedInstance;

@end
