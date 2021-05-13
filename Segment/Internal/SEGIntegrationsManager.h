//
//  SEGIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

@import Foundation;
#import "SEGMiddleware.h"

/**
 * Filenames of "Application Support" files where essential data is stored.
 */
extern NSString *_Nonnull const kSEGAnonymousIdFilename;
extern NSString *_Nonnull const kSEGCachedSettingsFilename;

/**
 * NSNotification name, that is posted after integrations are loaded.
 */
extern NSString *_Nonnull SEGAnalyticsIntegrationDidStart;

@class SEGAnalytics;

NS_SWIFT_NAME(IntegrationsManager)
@interface SEGIntegrationsManager : NSObject

// Exposed for testing.
+ (BOOL)isIntegration:(NSString *_Nonnull)key enabledInOptions:(NSDictionary *_Nonnull)options;
+ (BOOL)isTrackEvent:(NSString *_Nonnull)event enabledForIntegration:(NSString *_Nonnull)key inPlan:(NSDictionary *_Nonnull)plan;

// @Deprecated - Exposing for backward API compat reasons only
@property (nonatomic, readonly) NSMutableDictionary *_Nonnull registeredIntegrations;

- (instancetype _Nonnull)initWithAnalytics:(SEGAnalytics *_Nonnull)analytics;

// @Deprecated - Exposing for backward API compat reasons only
- (NSString *_Nonnull)getAnonymousId;
- (void)saveAnonymousId:(NSString *_Nonnull)anonymousId;

@end


@interface SEGIntegrationsManager (SEGMiddleware) <SEGMiddleware>

@end
