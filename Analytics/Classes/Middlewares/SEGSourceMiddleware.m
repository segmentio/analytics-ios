//
//  SEGSourceMiddleware.m
//  Analytics
//
//  Created by Brandon Sneed on 1/23/20.
//  Copyright © 2020 Segment. All rights reserved.
//

#import "SEGSourceMiddleware.h"
#import "SEGAnalyticsUtils.h"

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

    SEGContext *workingContext = context;
    for (id<SEGSourceMiddleware> item in middleware) {
        SEGPayload *payload = workingContext.payload;
        
        if ([item respondsToSelector:@selector(event:context:)]) {
            // try the catch-all first.
            payload = [item event:workingContext.payload context:workingContext];
        } else {
            // otherwise, hit the pre-typed ones instead.
            switch (workingContext.eventType) {
                case SEGEventTypeIdentify:
                    if ([item respondsToSelector:@selector(identifyEvent:context:)]) {
                        payload = [item identifyEvent:(SEGIdentifyPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeTrack:
                    if ([item respondsToSelector:@selector(trackEvent:context:)]) {
                        payload = [item trackEvent:(SEGTrackPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeScreen:
                    if ([item respondsToSelector:@selector(screenEvent:context:)]) {
                        payload = [item screenEvent:(SEGScreenPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeGroup:
                    if ([item respondsToSelector:@selector(groupEvent:context:)]) {
                        payload = [item groupEvent:(SEGGroupPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeAlias:
                    if ([item respondsToSelector:@selector(aliasEvent:context:)]) {
                        payload = [item aliasEvent:(SEGAliasPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeApplicationLifecycle:
                    if ([item respondsToSelector:@selector(applicationLifecycleEvent:context:)]) {
                        payload = [item applicationLifecycleEvent:(SEGApplicationLifecyclePayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeContinueUserActivity:
                    if ([item respondsToSelector:@selector(continueUserActivityEvent:context:)]) {
                        payload = [item continueUserActivityEvent:(SEGContinueUserActivityPayload *)payload context:workingContext];
                    }
                    break;
                case SEGEventTypeOpenURL:
                    if ([item respondsToSelector:@selector(openURLEvent:context:)]) {
                        payload = [item openURLEvent:(SEGOpenURLPayload *)payload context:workingContext];
                    }
                    break;
                    
                case SEGEventTypeFailedToRegisterForRemoteNotifications:
                case SEGEventTypeRegisteredForRemoteNotifications:
                case SEGEventTypeHandleActionWithForRemoteNotification:
                case SEGEventTypeReceivedRemoteNotification:
                    if ([item respondsToSelector:@selector(remoteNotificationEvent:context:)]) {
                        payload = [item remoteNotificationEvent:(SEGRemoteNotificationPayload *)payload context:workingContext];
                    }
                    break;

                case SEGEventTypeReset:
                case SEGEventTypeFlush:
                case SEGEventTypeUndefined:
                    break;
            }
        }
        
        if (payload == nil) {
            break;
        } else {
            workingContext = [workingContext modify:^(id<SEGMutableContext>  _Nonnull ctx) {
                ctx.payload = payload;
            }];
        }
    }
}

@end
