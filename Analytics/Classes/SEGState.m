//
//  SEGState.m
//  Analytics
//
//  Created by Brandon Sneed on 6/9/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "SEGState.h"
#import "SEGAnalyticsUtils.h"

typedef void (^SEGStateBlock)(void);
typedef id (^SEGStateGetBlock)(void);


@interface SEGState()
@property (nonatomic, nonnull) SEGUserInfo *userInfo;
- (void)setValueWithBlock:(SEGStateBlock)block;
- (id)valueWithBlock:(SEGStateGetBlock)block;
@end


@protocol SEGStateObject
@property (nonatomic, weak) SEGState *state;
- (instancetype)initWithState:(SEGState *)state;
@end


@interface SEGUserInfo () <SEGStateObject>
@property (nonatomic, copy, nonnull) NSString *anonymousId;
@property (nonatomic, copy, nullable) NSString *userId;
@property (nonatomic, copy, nullable) NSDictionary *traits;
@end

@implementation SEGUserInfo

@synthesize state;

- (instancetype)initWithState:(SEGState *)state
{
    if (self = [super init]) {
        self.state = state;
    }
    return self;
}

- (NSString *)anonymousId
{
    return [state valueWithBlock: ^id{
        return self.anonymousId;
    }];
}

- (void)setAnonymousId:(NSString *)anonymousId
{
    [state setValueWithBlock: ^{
        self.anonymousId = [anonymousId copy];
    }];
}

- (NSString *)userId
{
    return [state valueWithBlock: ^id{
        return self.userId;
    }];
}

- (void)setUserId:(NSString *)userId
{
    [state setValueWithBlock: ^{
        self.userId = [userId copy];
    }];
}

- (NSDictionary *)traits
{
    return [state valueWithBlock:^id{
        return self.traits;
    }];
}

- (void)setTraits:(NSDictionary *)traits
{
    [state setValueWithBlock: ^{
        self.traits = [traits serializableDeepCopy];
    }];
}

@end



@implementation SEGState {
    dispatch_queue_t _stateQueue;
}

+ (instancetype)sharedInstance
{
    static SEGState *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _stateQueue = dispatch_queue_create("com.segment.state.queue", DISPATCH_QUEUE_SERIAL);
        self.userInfo = [[SEGUserInfo alloc] init];
    }
    return self;
}

- (void)setValueWithBlock:(SEGStateBlock)block
{
    dispatch_barrier_async(_stateQueue, block);
}

- (id)valueWithBlock:(SEGStateGetBlock)block
{
    __block id value = nil;
    dispatch_sync(_stateQueue, ^{
        value = block();
    });
    return value;
}

@end
