#import <Foundation/Foundation.h>
#import "SEGIntegrationFactory.h"

/** Provides a set of properties to construct the analytics client. */
@interface SEGAnalyticsConfiguration : NSObject

/**
 * Creates and returns a configuration with default settings and the given write key.
 *
 * @param writeKey Your project's write key from segment.io.
 */
+ (instancetype)configurationWithWriteKey:(NSString *)writeKey;

/**
 * Your project's write key from segment.io.
 *
 * @see +configurationWithWriteKey:
 */
@property (nonatomic, copy, readonly) NSString *writeKey;

/**
 * Whether the analytics client should use location services.
 * If `YES` and the host app hasn't asked for permission to use location services then
 * the user will be presented with an alert view asking to do so. `NO` by default.
 */
@property (nonatomic, assign) BOOL shouldUseLocationServices;

/**
 * Whether the analytics client should track advertisting info. `YES` by default.
 */
@property (nonatomic, assign) BOOL enableAdvertisingTracking;

/**
 * The number of queued events that the analytics client should flush at. Setting this
 * to `1` will not queue any events and will use more battery. `20` by default.
 */
@property (nonatomic, assign) NSUInteger flushAt;

/** Register an integration factory. */
- (void)use:(id<SEGIntegrationFactory>)factory;

@end

@interface SEGAnalytics : NSObject

@end
