//
//  SEGIntegrationsManager.h
//  Analytics
//
//  Created by Tony Xiao on 9/20/16.
//  Copyright © 2016 Segment. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SEGApplicationProtocol <NSObject>
@property (nullable, nonatomic, assign) id<UIApplicationDelegate> delegate;
- (UIBackgroundTaskIdentifier)seg_beginBackgroundTaskWithName:(nullable NSString *)taskName expirationHandler:(void (^__nullable)(void))handler;
- (void)seg_endBackgroundTask:(UIBackgroundTaskIdentifier)identifier;
@end


@interface UIApplication (SEGApplicationProtocol) <SEGApplicationProtocol>
@end

typedef NSMutableURLRequest *_Nonnull (^SEGRequestFactory)(NSURL *_Nonnull);

@protocol SEGIntegrationFactory;
@protocol SEGCrypto;
@protocol SEGMiddleware;

/**
 * This object provides a set of properties to control various policies of the analytics client. Other than `writeKey`, these properties can be changed at any time.
 */
@interface SEGAnalyticsConfiguration : NSObject

/**
 * Creates and returns a configuration with default settings and the given write key.
 *
 * @param writeKey Your project's write key from segment.io.
 */
+ (_Nonnull instancetype)configurationWithWriteKey:(NSString *_Nonnull)writeKey;

/**
 * Your project's write key from segment.io.
 *
 * @see +configurationWithWriteKey:
 */
@property (nonatomic, copy, readonly, nonnull) NSString *writeKey;

/**
 * Whether the analytics client should use location services.
 * If `YES` and the host app hasn't asked for permission to use location services then the user will be presented with an alert view asking to do so. `NO` by default.
 * If `YES`, please make sure to add a description for `NSLocationAlwaysUsageDescription` in your `Info.plist` explaining why your app is accessing Location APIs.
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
 * The amount of time to wait before each tick of the flush timer.
 * Smaller values will make events delivered in a more real-time manner and also use more battery.
 * A value smaller than 10 seconds will seriously degrade overall performance.
 * 30 seconds by default.
 */
@property (nonatomic, assign) NSTimeInterval flushInterval;

/**
 * The maximum number of items to queue before starting to drop old ones. This should be a value greater than zero, the behaviour is undefined otherwise. `1000` by default.
 */
@property (nonatomic, assign) NSUInteger maxQueueSize;

/**
 * Whether the analytics client should automatically make a track call for application lifecycle events, such as "Application Installed", "Application Updated" and "Application Opened".
 */
@property (nonatomic, assign) BOOL trackApplicationLifecycleEvents;


/**
 * Whether the analytics client should record bluetooth information. If `YES`, please make sure to add a description for `NSBluetoothPeripheralUsageDescription` in your `Info.plist` explaining explaining why your app is accessing Bluetooth APIs. `NO` by default.
 */
@property (nonatomic, assign) BOOL shouldUseBluetooth;

/**
 * Whether the analytics client should automatically make a screen call when a view controller is added to a view hierarchy. Because the underlying implementation uses method swizzling, we recommend initializing the analytics client as early as possible (before any screens are displayed), ideally during the Application delegate's applicationDidFinishLaunching method.
 */
@property (nonatomic, assign) BOOL recordScreenViews;

/**
 * Whether the analytics client should automatically track in-app purchases from the App Store.
 */
@property (nonatomic, assign) BOOL trackInAppPurchases;

/**
 * Whether the analytics client should automatically track push notifications.
 */
@property (nonatomic, assign) BOOL trackPushNotifications;

/**
 * Whether the analytics client should automatically track deep links. You'll still need to call the continueUserActivity and openURL methods on the analytics client.
 */
@property (nonatomic, assign) BOOL trackDeepLinks;

/**
 * Whether the analytics client should automatically track attribution data from enabled providers using the mobile service.
 */
@property (nonatomic, assign) BOOL trackAttributionData;

/**
 * Dictionary indicating the options the app was launched with.
 */
@property (nonatomic, strong, nullable) NSDictionary *launchOptions;

/**
 * Set a custom request factory.
 */
@property (nonatomic, strong, nullable) SEGRequestFactory requestFactory;

/**
 * Set a custom crypto
 */
@property (nonatomic, strong, nullable) id<SEGCrypto> crypto;

/**
 * Set custom middlewares. Will be run before all integrations
 */
@property (nonatomic, strong, nullable) NSArray<id<SEGMiddleware>> *middlewares;

/**
 * Register a factory that can be used to create an integration.
 */
- (void)use:(id<SEGIntegrationFactory> _Nonnull)factory;

/**
 * Leave this nil for iOS extensions, otherwise set to UIApplication.sharedApplication.
 */
@property (nonatomic, strong, nullable) id<SEGApplicationProtocol> application;

@end
