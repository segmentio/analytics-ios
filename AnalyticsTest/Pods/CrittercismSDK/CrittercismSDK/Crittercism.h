//
//  Crittercism.h
//  Crittercism-iOS
//
//  Created by Robert Kwok on 8/15/10.
//  Copyright 2010-2012 Crittercism Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CrittercismDelegate.h"

@class CritterImpl;

@interface Crittercism : NSObject {
 @private
  CritterImpl *critter_;
}

//
// Methods for Enabling Crittercism
//
// You must call one of these before using any other Crittercism functionality

+ (void)enableWithAppID:(NSString *)appId;

// Designated "initializer"
+ (void)enableWithAppID:(NSString *)appId
            andDelegate:(id <CrittercismDelegate>)critterDelegate;

// When async breadcrumb mode is enabled, writes to the breadcrumb file will be
// conflated into at most one batch write per iteration of the main thread's
// run loop.
// Enabling this mode can cause breadcrumbs to be lost if your app crashes
// before the breadcrumb file has been flushed. Crittercism only recommends
// use of this mode if you are rapidly leaving breadcrumbs within a performance
// critical section of code.
+ (void)setAsyncBreadcrumbMode:(BOOL)writeAsync;

// Disable or enable all communication with Crittercism servers.
// If called to disable (status == YES), any pending crash reports will be
// purged, and feedback will be reset (if using the forum feature.)
+ (void)setOptOutStatus:(BOOL)status;

// Retrieve currently stored opt out status.
+ (BOOL)getOptOutStatus;

// Set the maximum number of Crittercism crash reports that will be stored on
// the local device if the device does not have internet connectivity.  If
// more than |maxOfflineCrashReports| crashes occur, then the oldest crash
// will be overwritten. Decreasing the value of this setting will not delete
// any offline crash reports. Unsent crash reports will be kept until they are
// sent to the Crittercism server, hence there may be more than
// |maxOfflineCrashReports| stored on the device for a short period of time.
//
// The default value is 3
+ (void)setMaxOfflineCrashReports:(NSUInteger)max;

// Get the maximum number of Crittercism crash reports that will be stored on
// the local device if the device does not have internet connectivity.
+ (NSUInteger)maxOfflineCrashReports;

// Retrieve the Crittercism generated unique identifier for this device.
// Note, this is NOT the iPhone's UDID.
//
// If called before enabling the library, will return an empty string.
+ (NSString *)getUserUUID;

// Record an exception that you purposely caught via Crittercism.
//
// Note: Crittercism limits logging handled exceptions to once per minute. If
// you've logged an exception within the last minute, we buffer the last five
// exceptions and send those after a minute has passed.
+ (BOOL)logHandledException:(NSException *)exception;

// Leave a breadcrumb for the current run of your app. If the app ever crashes,
// these breadcrumbs will be uploaded along with that crash report to
// Crittercism's servers.
+ (void)leaveBreadcrumb:(NSString *)breadcrumb;

//
// Methods for User Metadata
//

+ (void)setAge:(int)age;
+ (void)setGender:(NSString *)gender;
+ (void)setUsername:(NSString *)username;
+ (void)setEmail:(NSString *)email;
// Set an arbitrary key/value pair in the User Metadata
+ (void)setValue:(NSString *)value forKey:(NSString *)key;

////////////////////////////////////////////////////////////////////////////////
// DEPRECATED METHODS
////////////////////////////////////////////////////////////////////////////////

+ (Crittercism *)sharedInstance;

- (id <CrittercismDelegate>)delegate;
- (void)setDelegate:(id <CrittercismDelegate>)delegate;

- (BOOL)didCrashOnLastLoad;
- (void)setDidCrashOnLastLoad:(BOOL)didCrash;

//
// Initializers - Will be removed in a future release. Please change your code
// to use one of the enable* methods
//

+ (void)initWithAppID:(NSString *)appId __attribute__((deprecated));

+ (void)initWithAppID:(NSString *)appId
    andMainViewController:(UIViewController *)viewController
    __attribute__((deprecated));

+ (void)initWithAppID:(NSString *)appId
    andMainViewController:(UIViewController *)viewController
    andDelegate:(id)critterDelegate
    __attribute__((deprecated));

// Deprecated in v3.3.1 - key and secret are no longer needed
+ (void)initWithAppID:(NSString *)appId
    andKey:(NSString *)keyStr
    andSecret:(NSString *)secretStr
    __attribute__((deprecated));

// Deprecated in v3.3.1 - key and secret are no longer needed
+ (void)initWithAppID:(NSString *)appId
    andKey:(NSString *)keyStr
    andSecret:(NSString *)secretStr
    andMainViewController:(UIViewController *)viewController
    __attribute__((deprecated));

// This method does nothing and will be removed in a future release.
+ (void)configurePushNotification:(NSData *)deviceToken
    __attribute__((deprecated));

@end
