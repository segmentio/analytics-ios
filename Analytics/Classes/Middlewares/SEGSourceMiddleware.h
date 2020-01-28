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
@protocol SEGSourceMiddleware<NSObject>
@optional
// Implement this method when you want to do event typing yourself.
- (SEGPayload * _Nullable)event:(SEGPayload *)payload context:(SEGContext *)context;
// Pre-typed event handling methods.
- (SEGPayload * _Nullable)trackEvent:(SEGTrackPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)identifyEvent:(SEGIdentifyPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)aliasEvent:(SEGAliasPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)groupEvent:(SEGGroupPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)screenEvent:(SEGScreenPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)applicationLifecycleEvent:(SEGApplicationLifecyclePayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)openURLEvent:(SEGOpenURLPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)remoteNotificationEvent:(SEGRemoteNotificationPayload *)payload context:(SEGContext *)context;
- (SEGPayload * _Nullable)continueUserActivityEvent:(SEGContinueUserActivityPayload *)payload context:(SEGContext *)context;

@end

typedef void (^RunSourceMiddlewareCallback)(BOOL earlyExit, NSArray<id<SEGSourceMiddleware>> *_Nonnull remainingMiddlewares);

@interface SEGSourceMiddlewareRunner : NSObject
@property (nonnull, nonatomic, readonly) NSArray<id<SEGSourceMiddleware>> *middleware;

- (void)run:(SEGContext *_Nonnull)context callback:(RunSourceMiddlewareCallback _Nullable)callback;
- (instancetype _Nonnull)initWithMiddleware:(NSArray<id<SEGSourceMiddleware>> *_Nonnull)middleware;
@end

NS_ASSUME_NONNULL_END
