//
//  SEGContext.m
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGContext.h"

@interface SEGContext () <SEGMutableContext>

@property (nonatomic) SEGEventType eventType;
@property (nonatomic, nullable) NSString *userId;
@property (nonatomic, nullable) NSString *anonymousId;
@property (nonatomic, nullable) SEGPayload *payload;
@property (nonatomic, nullable) NSError *error;
@property (nonatomic) BOOL debug;

@end

@implementation SEGContext

- (instancetype)initWithAnalytics:(SEGAnalytics *)analytics {
    if (self = [super init]) {
        __analytics = analytics;
    }
    return self;
}

- (SEGContext * _Nonnull)modify:(void(^_Nonnull)(id<SEGMutableContext> _Nonnull))modify {
    // We're also being a bit clever here by implementing SEGContext actually as a mutable
    // object but hiding that implementation detail from consumer of the API.
    // In production also instead of copying self we simply just return self
    // because the net effect is the same anyways. In the end we get a lot of the benefits
    // of immutable data structure without the cost of having to allocate and reallocate
    // objects over and over again.
    SEGContext *context = self.debug ? [self copy] : self;
    modify(context);
    return self;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    SEGContext *ctx = [[SEGContext allocWithZone:zone] initWithAnalytics:self._analytics];
    ctx.eventType = self.eventType;
    ctx.userId = self.userId;
    ctx.anonymousId = self.anonymousId;
    ctx.payload = self.payload;
    ctx.error = self.error;
    ctx.debug = self.debug;
    return ctx;
}

@end
