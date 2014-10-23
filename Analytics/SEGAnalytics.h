// Analytics.h
// Copyright (c) 2014 Segment.io. All rights reserved.
// Version 1.0.0 (Do not change this line. It is automatically modified by the build process)

#import <Foundation/Foundation.h>

/**
* This object provides a set of properties to control various policies of the analytics client. Other than `writeKey`, these properties can be changed at any time.
*/
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
* Whether the analytics client should use location services. If `YES` and the host app hasn't asked for permission to use location services then the user will be presented with an alert view asking to do so. `NO` by default.
*/
@property (nonatomic, assign) BOOL shouldUseLocationServices;

/**
 * Whether the analytics client should track advertisting info. `YES` by default.
 */
@property (nonatomic, assign) BOOL enableAdvertisingTracking;

/**
* The number of queued events that the analytics client should flush at. Setting this to `1` will not queue any events and will use more battery. `20` by default.
*/
@property (nonatomic, assign) NSUInteger flushAt;

/**
* For segment's use only.
*/
@property (nonatomic, strong) NSMutableDictionary *integrations;

@end

/**
* This object provides an API for recording analytics.
*/
@interface SEGAnalytics : NSObject

/**
* Used by the analytics client to configure various options.
*/
@property (nonatomic, strong, readonly) SEGAnalyticsConfiguration *configuration;

/**
* Setup the analytics client.
*
* @param configuration The configuration used to setup the client.
*/
+ (void)setupWithConfiguration:(SEGAnalyticsConfiguration *)configuration;

/**
* Enabled/disables debug logging to trace your data going through the SDK.
*
* @param showDebugLogs `YES` to enable logging, `NO` otherwise. `NO` by default.
*/
+ (void)debug:(BOOL)showDebugLogs;

/**
* Returns the shared analytics client.
*
* @see -setupWithConfiguration:
*/
+ (instancetype)sharedAnalytics;

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
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits options:(NSDictionary *)options;
- (void)identify:(NSString *)userId;
- (void)identify:(NSString *)userId traits:(NSDictionary *)traits;


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
 Register the given device to receive push notifications from applicable integrations.

 @discussion
 Some integrations (such as Mixpanel) are capable of sending push notification to users based on
 their traits and actions. This will associate the device token with the current user in integrations
 that have this capability. You should call this method with the <code>NSData</code> token passed to
 <code>application:didRegisterForRemoteNotificationsWithDeviceToken:</code>.

 @param deviceToken     device token as returned <code>application:didRegisterForRemoteNotificationsWithDeviceToken:</code>
 */
- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)registerForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken options:(NSDictionary *)options;


/*!
 @method

 @abstract
 Reset any user state that is cached on the device.

 @discussion
 This is useful when a user logs out and you want to clear the identity. It will clear any
 traits or userId's cached on the device.
 */
- (void)reset;


/*!
 @method

 @abstract
 Enable the sending of analytics data. Enabled by default.

 @discussion
 Occasionally used in conjunction with disable user opt-out handling.
 */
- (void)enable;


/*!
 @method

 @abstract
 Completely disable the sending of any analytics data.

 @discussion
 If have a way for users to actively or passively (sometimes based on location) opt-out of
 analytics data collection, you can use this method to turn off all data collection.
 */
- (void)disable;


/**
* Version of the library.
*/
+ (NSString *)version;

@end

@interface SEGAnalytics (Internal)

/**
 * Integrations registered with the shared instance. For internal SEG use only!
 */
+ (NSDictionary *)registeredIntegrations;

/**
 * Used to register integrations with the shared instance. For internal SEG use only!
 */
+ (void)registerIntegration:(Class)integrationClass withIdentifier:(NSString *)identifer;

/**
 * Creates and returns an analytics instance. For internal SEG use only!
 *
 * @param configuration The configuration used to setup the analyics instance.
 */
- (instancetype)initWithConfiguration:(SEGAnalyticsConfiguration *)configuration;

@end

@interface SEGAnalytics (Deprecated)

+ (void)initializeWithWriteKey:(NSString *)writeKey __attribute__((deprecated("Use +setupWithConfiguration: instead")));
- (id)initWithWriteKey:(NSString *)writeKey __attribute__((deprecated("Use -initWithConfiguration: instead")));
- (void)registerPushDeviceToken:(NSData *)deviceToken __attribute__((deprecated("Use -registerForRemoteNotificationsWithDeviceToken: instead")));

@end
