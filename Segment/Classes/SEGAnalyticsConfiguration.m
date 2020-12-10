//
//  SEGIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import "SEGAnalyticsConfiguration.h"
#import "SEGAnalytics.h"
#import "SEGMiddleware.h"
#import "SEGCrypto.h"
#import "SEGHTTPClient.h"
#import "SEGUtils.h"
#if TARGET_OS_IPHONE
@import UIKit;
#elif TARGET_OS_OSX
@import Cocoa;
#endif

#if TARGET_OS_IPHONE
@implementation UIApplication (SEGApplicationProtocol)

- (UIBackgroundTaskIdentifier)seg_beginBackgroundTaskWithName:(nullable NSString *)taskName expirationHandler:(void (^__nullable)(void))handler
{
    return [self beginBackgroundTaskWithName:taskName expirationHandler:handler];
}

- (void)seg_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier
{
    [self endBackgroundTask:identifier];
}

@end
#endif

@implementation SEGAnalyticsExperimental
@end

@interface SEGAnalyticsConfiguration ()

@property (nonatomic, copy, readwrite) NSString *writeKey;
@property (nonatomic, strong, readonly) NSMutableArray *factories;
@property (nonatomic, strong) SEGAnalyticsExperimental *experimental;

- (instancetype)initWithWriteKey:(NSString *)writeKey defaultAPIHost:(NSURL * _Nullable)defaultAPIHost;

@end


@implementation SEGAnalyticsConfiguration

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey
{
    return [[SEGAnalyticsConfiguration alloc] initWithWriteKey:writeKey defaultAPIHost:nil];
}

+ (instancetype)configurationWithWriteKey:(NSString *)writeKey defaultAPIHost:(NSURL * _Nullable)defaultAPIHost
{
    return [[SEGAnalyticsConfiguration alloc] initWithWriteKey:writeKey defaultAPIHost:defaultAPIHost];
}

- (instancetype)initWithWriteKey:(NSString *)writeKey defaultAPIHost:(NSURL * _Nullable)defaultAPIHost
{
    if (self = [self init]) {
        self.writeKey = writeKey;
        
        // get the host we have stored
        NSString *host = [SEGUtils getAPIHost];
        if ([host isEqualToString:kSegmentAPIBaseHost]) {
            // we're getting the generic host back.  have they
            // supplied something other than that?
            if (defaultAPIHost && ![host isEqualToString:defaultAPIHost.absoluteString]) {
                // we should use the supplied default.
                host = defaultAPIHost.absoluteString;
                [SEGUtils saveAPIHost:host];
            }
        }
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.experimental = [[SEGAnalyticsExperimental alloc] init];
        self.shouldUseLocationServices = NO;
        self.enableAdvertisingTracking = YES;
        self.shouldUseBluetooth = NO;
        self.flushAt = 20;
        self.flushInterval = 30;
        self.maxQueueSize = 1000;
        self.payloadFilters = @{
            @"(fb\\d+://authorize#access_token=)([^ ]+)": @"$1((redacted/fb-auth-token))"
        };
        _factories = [NSMutableArray array];
#if TARGET_OS_IPHONE
        if ([UIApplication respondsToSelector:@selector(sharedApplication)]) {
            _application = [UIApplication performSelector:@selector(sharedApplication)];
        }
#elif TARGET_OS_OSX
        if ([NSApplication respondsToSelector:@selector(sharedApplication)]) {
            _application = [NSApplication performSelector:@selector(sharedApplication)];
        }
#endif
    }
    return self;
}

- (NSURL *)apiHost
{
    return [SEGUtils getAPIHostURL];
}

- (void)use:(id<SEGIntegrationFactory>)factory
{
    [self.factories addObject:factory];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%p:%@, %@>", self, self.class, [self dictionaryWithValuesForKeys:@[ @"writeKey", @"shouldUseLocationServices", @"flushAt" ]]];
}

// MARK: remove these when `middlewares` property is removed.

- (void)setMiddlewares:(NSArray<id<SEGMiddleware>> *)middlewares
{
    self.sourceMiddleware = middlewares;
}

- (NSArray<id<SEGMiddleware>> *)middlewares
{
    return self.sourceMiddleware;
}

- (void)setEdgeFunctionMiddleware:(id<SEGEdgeFunctionMiddleware>)edgeFunctionMiddleware
{
    _edgeFunctionMiddleware = edgeFunctionMiddleware;
    self.sourceMiddleware = edgeFunctionMiddleware.sourceMiddleware;
    self.destinationMiddleware = edgeFunctionMiddleware.destinationMiddleware;
}

@end
