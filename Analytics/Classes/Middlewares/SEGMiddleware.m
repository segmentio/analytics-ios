//
//  SEGMiddleware.m
//  Analytics
//
//  Created by Tony Xiao on 9/19/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGUtils.h"
#import "SEGMiddleware.h"

@implementation SEGNoopMiddleware

- (void)context:(SEGContext *)context next:(id<SEGMiddleware>)next {
    SEGLog(@"[Noop] Middleware received event %d", context.eventType);
}

@end

@implementation SEGMiddlewareManager

@end
