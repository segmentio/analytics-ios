//
//  SEGSourceMiddleware.m
//  Analytics
//
//  Created by Brandon Sneed on 1/23/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "SEGSourceMiddleware.h"

@implementation SEGSourceMiddlewareRunner

- (instancetype)initWithMiddleware:(NSArray<id<SEGSourceMiddleware>> *_Nonnull)middleware
{
    if (self = [super init]) {
        _middleware = middleware;
    }
    return self;
}

- (void)run:(SEGContext *_Nonnull)context callback:(RunSourceMiddlewareCallback _Nullable)callback
{
    [self runMiddleware:self.middleware context:context callback:callback];
}

- (void)runMiddleware:(NSArray<id<SEGSourceMiddleware>> *_Nonnull)middleware
               context:(SEGContext *_Nonnull)context
              callback:(RunSourceMiddlewareCallback _Nullable)callback
{
    BOOL earlyExit = context == nil;
    if (middleware.count == 0 || earlyExit) {
        if (callback) {
            callback(earlyExit, middleware);
        }
        return;
    }

    SEGContext *workingContext = [context copy];
    for (id<SEGSourceMiddleware> item in middleware) {
        workingContext = [item event:workingContext.payload context:workingContext];
        if (workingContext == nil) {
            break;
        }
    }
}

@end
