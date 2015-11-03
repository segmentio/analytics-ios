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

/*!
 @method
 
 @abstract
 Associate a user with their unique ID and record traits about them.
 
 @param userId        A database ID (or email address) for this user. If you don't have a userId
 but want to record traits, you should pass nil. For more information on how we
 generate the UUID and Apple's policies on IDs, see https://segment.io/libraries/ios#ids
 
 @param traits        A dictionary of traits you know about the user. Things like: email, name, plan, etc.
 
 @discussion
 When you learn more about who your user is, you can record that information with identify.
 */
- (void)identify:(NSString *)userId;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options;

/*!
 @method
 
 @abstract
 Record the actions your users perform.
 
 @param event         The name of the event you're tracking. We recommend using human-readable names
 like `Played a Song` or `Updated Status`.
 
 @param properties    A dictionary of properties for the event. If the event was 'Added to Shopping Cart', it might
 have properties like price, productType, etc.
 
 @discussion
 When a user performs an action in your app, you'll want to track that action for later analysis. Use the event name to say what the user did, and properties to specify any interesting details of the action.
 */
- (void)track:(NSString *)event;
- (void)track:(NSString *)event properties:(NSDictionary *)properties;
- (void)track:(NSString *)event properties:(NSDictionary *)properties options:(NSDictionary *)options;

/*!
 @method
 
 @abstract
 Record the screens or views your users see.
 
 @param screenTitle   The title of the screen being viewed. We recommend using human-readable names
 like 'Photo Feed' or 'Completed Purchase Screen'.
 
 @param properties    A dictionary of properties for the screen view event. If the event was 'Added to Shopping Cart',
 it might have properties like price, productType, etc.
 
 @discussion
 When a user views a screen in your app, you'll want to record that here. For some tools like Google Analytics and Flurry, screen views are treated specially, and are different from "events" kind of like "page views" on the web. For services that don't treat "screen views" specially, we map "screen" straight to "track" with the same parameters. For example, Mixpanel doesn't treat "screen views" any differently. So a call to "screen" will be tracked as a normal event in Mixpanel, but get sent to Google Analytics and Flurry as a "screen".
 */
- (void)screen:(NSString *)screenTitle;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties;
- (void)screen:(NSString *)screenTitle properties:(NSDictionary *)properties options:(NSDictionary *)options;

/*!
 @method
 
 @abstract
 Associate a user with a group, organization, company, project, or w/e *you* call them.
 
 @param groupId       A database ID for this group.
 
 @param traits        A dictionary of traits you know about the group. Things like: name, employees, etc.
 
 @discussion
 When you learn more about who the group is, you can record that information with group.
 */
- (void)group:(NSString *)groupId;
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits;
- (void)group:(NSString *)groupId traits:(NSDictionary *)traits options:(NSDictionary *)options;

/*!
 @method
 
 @abstract
 Merge two user identities, effectively connecting two sets of user data as one.
 This may not be supported by all integrations.
 
 @param newId         The new ID you want to alias the existing ID to. The existing ID will be either the
 previousId if you have called identify, or the anonymous ID.
 
 @discussion
 When you learn more about who the group is, you can record that information with group.
 */
- (void)alias:(NSString *)newId;
- (void)alias:(NSString *)newId options:(NSDictionary *)options;


@end
