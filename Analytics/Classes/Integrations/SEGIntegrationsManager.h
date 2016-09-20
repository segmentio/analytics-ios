//
//  SEGIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SEGMiddleware.h"

/**
 * NSNotification name, that is posted after integrations are loaded.
 */
extern NSString *_Nonnull SEGAnalyticsIntegrationDidStart;

@class SEGAnalytics;
@interface SEGIntegrationsManager : NSObject

- (instancetype _Nonnull)initWithAnalytics:(SEGAnalytics * _Nonnull)analytics;

@end

@interface SEGIntegrationsManager (SEGMiddleware) <SEGMiddleware>

@end