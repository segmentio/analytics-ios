//
//  SEGSourceMiddleware.h
//  Analytics
//
//  Created by Brandon Sneed on 1/23/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGContext.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(SourceMiddleware)
@protocol SEGSourceMiddleware
@required
- (SEGContext * _Nullable)event:(SEGPayload *)payload context:(SEGContext *)context;
@end

typedef void (^RunSourceMiddlewareCallback)(BOOL earlyExit, NSArray<id<SEGSourceMiddleware>> *_Nonnull remainingMiddlewares);

@interface SEGSourceMiddlewareRunner : NSObject
@property (nonnull, nonatomic, readonly) NSArray<id<SEGSourceMiddleware>> *middleware;

- (void)run:(SEGContext *_Nonnull)context callback:(RunSourceMiddlewareCallback _Nullable)callback;
- (instancetype _Nonnull)initWithMiddleware:(NSArray<id<SEGSourceMiddleware>> *_Nonnull)middleware;
@end

NS_ASSUME_NONNULL_END
