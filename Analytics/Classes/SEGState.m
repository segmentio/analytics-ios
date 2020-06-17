//
//  SEGState.m
//  Analytics
//
//  Created by Brandon Sneed on 6/9/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "SEGState.h"
#import "SEGAnalyticsUtils.h"

typedef void (^SEGStateSetBlock)(void);
typedef _Nullable id (^SEGStateGetBlock)(void);


@interface SEGState()
// State Objects
@property (nonatomic, nonnull) SEGUserInfo *userInfo;
// State Accessors
- (void)setValueWithBlock:(SEGStateSetBlock)block;
- (id)valueWithBlock:(SEGStateGetBlock)block;
@end


@protocol SEGStateObject
@property (nonatomic, weak) SEGState *state;
- (instancetype)initWithState:(SEGState *)state;
@end


@interface SEGUserInfo () <SEGStateObject>
@end

@implementation SEGUserInfo

@synthesize state;

@synthesize anonymousId = _anonymousId;
@synthesize userId = _userId;
@synthesize traits = _traits;

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
        return self->_anonymousId;
    }];
}

- (void)setAnonymousId:(NSString *)anonymousId
{
    [state setValueWithBlock: ^{
        self->_anonymousId = [anonymousId copy];
    }];
}

- (NSString *)userId
{
    return [state valueWithBlock: ^id{
        return self->_userId;
    }];
}

- (void)setUserId:(NSString *)userId
{
    [state setValueWithBlock: ^{
        self->_userId = [userId copy];
    }];
}

- (NSDictionary *)traits
{
    return [state valueWithBlock:^id{
        return self->_traits;
    }];
}

- (void)setTraits:(NSDictionary *)traits
{
    [state setValueWithBlock: ^{
        self->_traits = [traits serializableDeepCopy];
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
        _stateQueue = dispatch_queue_create("com.segment.state.queue", DISPATCH_QUEUE_CONCURRENT);
        self.userInfo = [[SEGUserInfo alloc] initWithState:self];
    }
    return self;
}

- (void)setValueWithBlock:(SEGStateSetBlock)block
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
