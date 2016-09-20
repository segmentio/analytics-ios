//
//  SEGMiddleware.h
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGContext.h"

@protocol SEGMiddleware

// NOTE: If you want to hold onto references of context AFTER passing it through to the next
// middleware, you should explicitly create a copy via `[context copy]` to guarantee
// that it does not get changed from underneath you because contexts can be implemented
// as mutable objects under the hood for performance optimization.
// The behavior of keeping reference to a context AFTER passing it to the next middleware
// is strictly undefined.
- (void)context:(SEGContext * _Nonnull)context next:(id<SEGMiddleware> _Nonnull)next;

@end

@interface SEGMiddlewareManager : NSObject

@property (nonnull, nonatomic, strong) NSMutableArray<id<SEGMiddleware>> *middlewares;

@end
