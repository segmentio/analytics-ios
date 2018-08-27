Change Log
==========

Version 3.7.0-beta *(27th August, 2018)*
----------------------------------------

* [Improvement](https://github.com/segmentio/analytics-ios/pull/765): Make the maximum queue size configurable
* [Improvement](https://github.com/segmentio/analytics-ios/pull/767): Make the flush interval configurable

* [Fix](https://github.com/segmentio/analytics-ios/pull/773): Fix linking issues when automatic framework linking is disabled
* [Fix](https://github.com/segmentio/analytics-ios/pull/763): Retry HTTP 429 status codes
* [Fix](https://github.com/segmentio/analytics-ios/pull/761): Send RFC 7231 Formatted User Agent
* [Fix](https://github.com/segmentio/analytics-ios/pull/751): Ensure queue is always < 1000 items
* [Fix](https://github.com/segmentio/analytics-ios/pull/750): Reset SEGUserIdKey only on tvOS
* [Fix](https://github.com/segmentio/analytics-ios/pull/749): Renames GZIP category to prevent collisions
* [Fix](https://github.com/segmentio/analytics-ios/pull/744): sharedAnalytics returns null before setup
* [Fix](https://github.com/segmentio/analytics-ios/pull/741): Swift 4 support

Version 3.6.9 *(3rd December, 2017)*
-------------------------------------

* [Fix](https://github.com/segmentio/analytics-ios/pull/736): Reverts [ability to run connection factories asynchronously](https://github.com/segmentio/analytics-ios/pull/720). This fixes a bug in 3.6.9 that caused the library to not send events to the Segment API.

Version 3.6.8 *(28th October, 2017)*
-------------------------------------

This version included a bug that caused the library to not send events to the Segment API. We recommend using version `3.6.9` which fixes this bug and includes all the other improvements available in this release.

* [Fix](https://github.com/segmentio/analytics-ios/pull/700): Fixes some compiler warnings seen when importing analytics-ios via Swift in a Carthage project.
* [Fix](https://github.com/segmentio/analytics-ios/pull/730): Fix crash when trying to get screen name in some cases.
* [New](https://github.com/segmentio/analytics-ios/pull/727): Support schema defaults.
* [New](https://github.com/segmentio/analytics-ios/pull/724): Send disabled events to Segment so they can be surfaced in the debugger. This won't be sent to any destinations.
* [Fix](https://github.com/segmentio/analytics-ios/pull/723): Fix date formatting to be RFC 3339 compliant.
* [Fix](https://github.com/segmentio/analytics-ios/pull/715): Always deliver events asynchronously to integrations.

~~* [Improvement](https://github.com/segmentio/analytics-ios/pull/720): Run connection factory asynchronously so it doesn't block queuing events.~~

Version 3.6.7 *(24th August, 2017)*
-------------------------------------
* Use DEBUG preprocessor flag to conditionally disable assertions in prod #711

Version 3.6.6 *(15th August, 2017)*
-------------------------------------
* Update Info.plist version with library version. Add Makefile for building dynamic framework via Carthage. Explicitly distributing frameworks for installation outside of dependency managers.

Version 3.6.5 *(7th August, 2017)*
-------------------------------------
* Default to empty values rather than `NSNull` for automatically tracked events #706
* Fix events not persisting to disk when `NSNull` values are sent by removing keys containing `NSNull` values from events #707
  * Note this will remove `NSNull` values from dictionaries and arrays, modifying the tracked data

Version 3.6.4 *(19th July, 2017)*
-------------------------------------
* Add workaround for UIApplication type mismatch with Swift mapping. #704

Version 3.6.3 *(7th July, 2017)*
-------------------------------------
* Fix NSURLSession being prematurely invalidated (#702)

Version 3.6.2 *(6th July, 2017)*
-------------------------------------
* Remove canceling ongoing requests in reset method. (#691)
* Extract UIApplication to permit linkage with iOS extensions. (#698)
* Add missing includes to umbrella header (#696)
* Reuse NSURLSession in SEGHTTPCLient (#699)

Version 3.6.1 *(24th May, 2017)*
-------------------------------------
* Pass through userInfo when posting NSNotification
* Fix `Application Updated` event #685
* Fix `Application Opened` event #675
 * Fire during applicationWillEnterForeground, not just applicationDidFinishLaunching
 * Adding from_background, referring_application and url to Application Opened event
* Add [session finishTasksAndInvalidate] to SEGHTTPClient.m to prevent memory leak #679
* Use a separate queue for endBackgroundTask to fix deadlock (#684)
* Exposing SEGMiddleware and SEGContext header publicly
* Removing deprecated APIs
* Adding several test suites - reaching 70% coverage

Version 3.6.0 *(28th February, 2017)*
-------------------------------------
* Promoting `3.6.0-rc` to stable release `3.6.0` after sufficient time and exposure in pre-release.

Version 3.6.0-rc *(10th January, 2017)*
-------------------------------------
* Publicly exposing the middleware API, allowing custom middlewares to be inserted into the chain
* Added `SEGBlockMiddleware` helper to make it easier to create middleware out of anonymous functions

Version 3.6.0-beta *(1st December, 2016)*
-------------------------------------
* Major refactor laying the groundwork for a new middleware based architecture that will enable a whole new class of capabilities for analytics-ios

Version 3.5.5 *(30th November, 2016)*
-------------------------------------
* [Fix](1eeafe261887877b24b7197c991457b72379fc7e): Fix issue where calling `[analytics continueUserActivity:activity]` would cause events in the application session to be dropped. Events from prior and future sessions will be unaffected.

Version 3.5.4 *(28th November, 2016)*
-------------------------------------
* [Fix](https://github.com/segmentio/analytics-ios/commit/7d4cecbd723b6086f7d7a1df8cb0f4a1951539f3): Fall back to using Segment integration when we cannot get settings.

Version 3.5.3 *(7th November, 2016)*
-------------------------------------
* Update cdn hostname from cdn.segment.com to cdn-settings.segment.com

Version 3.5.2 *(10th October, 2016)*
-------------------------------------

* [Fix](https://github.com/segmentio/analytics-ios/pull/615): Fixed regression introduced in 3.5.0 that would generate a new anonymousId on every app launch.


Version 3.5.1 *(5th October, 2016)*
-------------------------------------
* Not a recommended version.  Regression introduced in 3.5.0 will generate a new anonymousId on every app launch.

* [Fix](https://github.com/segmentio/analytics-ios/pull/613): Removed automatic bluetooth and location info collection to workaround app submission issues.

Version 3.5.0 *(12th September, 2016)*
-------------------------------------
* Not a recommended version.  Regression introduced in 3.5.0 will generate a new anonymousId on every app launch.

* [New](https://github.com/segmentio/analytics-ios/pull/592): Adds a `SEGCrypto` API that can be used to configure the at rest encryption strategy for the client.

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];

 // Set a custom crypto implementation. An AES-256 implementation is provided out of the box.
 configuration.crypto = [SEGAES256Crypto initWithPassword:"YOUR_PRIVATE_PASSWORD"];

 // Set any other custom configuration options.
 ...

 // Initialize the SDK with the configuration.
 [SEGAnalytics setupWithConfiguration:configuration]
 ```

 * [New](https://github.com/segmentio/analytics-ios/commit/0c646e1c44df4134a984f1fcb741f5b1d418ab30): Add the ability for the SDK to natively report attribution information via Segment integrations enabled for your project, without needing to bundle their SDKs. Attribution information is sent as a track call as documented in the [mobile lifecycle spec](https://segment.com/docs/spec/mobile/#install-attributed).

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];

 // Enable attribution tracking.
 configuration.trackAttributionData = @YES;

 // Set any other custom configuration options.
 ...

 // Initialize the SDK with the configuration.
 [SEGAnalytics setupWithConfiguration:configuration]
 ```

 * [New](https://github.com/segmentio/analytics-ios/pull/597): Add the ability for the SDK to disable bluetooth collection. Going forwards, bluetooth information will **not** be collected by default. This is because iOS 10 requires [explicit documentation](https://developer.apple.com/library/prerelease/content/releasenotes/General/WhatsNewIniOS/Articles/iOS10.html) on why the CoreBluetooth APIs are accessed. If you enable this flag, your app's Info.plist must contain an [`NSBluetoothPeripheralUsageDescription` key](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW20) with a string value explaining to the user how the app uses this data. On this note, you should do the same for [`NSLocationAlwaysUsageDescription`](https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW18) if you have `shouldUseLocationServices` set to `@YES`. If you are linking against iOS 10, you'll want to update to this version to prevent your app submission from being rejected (or provide `NSBluetoothPeripheralUsageDescription` and/or `NSLocationAlwaysUsageDescription` descriptions in your app's Info.plist).

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];

 // Enable bluetooth collection.
 configuration.shouldUseBluetooth = @YES;

 // Set any other custom configuration options.
 ...

 // Initialize the SDK with the configuration.
 [SEGAnalytics setupWithConfiguration:configuration]
 ```

Version 3.4.0 *(1st September, 2016)*
-------------------------------------

 * [New](https://github.com/segmentio/analytics-ios/commit/d5db28ab9d15aa06b4e3a5c91f813d5c12a419a8): Adds a `SEGRequestFactory` API that can be used to configure the HTTP requests made by Segment.

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];

 // Set a custom request factory which allows you to modify the way the library creates an HTTP request.
 // In this case, we're transforming the URL to point to our own custom non-Segment host.
 configuration.requestFactory = ^(NSURL *url) {
     NSURLComponents \*components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
     // Replace YOUR_PROXY_HOST with the address of your proxy, e.g. aba64da6.ngrok.io.
     components.host = @"YOUR_PROXY_HOST";
     NSURL \*transformedURL = components.URL;
     return [NSMutableURLRequest requestWithURL:transformedURL];
 };

 // Set any other custom configuration options.
 ...

 // Initialize the SDK with the configuration.
 [SEGAnalytics setupWithConfiguration:configuration]
 ```


 * [New](https://github.com/segmentio/analytics-ios/commit/b8aed9692e82ad1dbbecfae0ad5fc353a9eb2220): Add method to retrieve anonymous ID.

 ```objc
 [[SEGAnalytics sharedAnalytics] getAnonymousId];
 ```

 * [Improvement](https://github.com/segmentio/analytics-ios/commit/98a467292de62eb6179107b6ebbc59f13caf16a2): Store `context` object with every event. This makes it more accurate collecting the context at the time the event was observed, rather than uploaded.

 * [Improvement](https://github.com/segmentio/analytics-ios/commit/66fdd8c25fbd28311cc99c0d6ccf8884e065d8b3): Automatic screen tracking improvements, specifically in the case when the root view is a `UINavigationController`.

 * [Improvement](https://github.com/segmentio/analytics-ios/commit/1ddcf615942125ecf791a8001794a27f7cb0385c): Don't send `Segment.io: false` in integration dictionary.

 * [Improvement](https://github.com/segmentio/analytics-ios/commit/0125804698f5e7087ca49f79f4ad99cc78aa2437): Friendly assert messages.

 * [Fix](https://github.com/segmentio/analytics-ios/pull/585): Namespace GZIP extension to avoid conflicts.

 * [Fix](https://github.com/segmentio/analytics-ios/pull/583/files): Fix assertion in `identify` method.

 * [Fix](https://github.com/segmentio/analytics-ios/commit/bad7259ed649f48629fda5373c0f4100b52537ed): Static analyzer warnings for reachability implementation.

 * [Fix](https://github.com/segmentio/analytics-ios/commit/3ac7115dde4fe0fc97fde61ac548111ddf76f694): Handle case where screen name is empty.

Version 3.3.0 *(08-05-2016)*
-----------------------------
 * New: Add Carthage support.
 * Fix: Flush timer behaviour. Previously it was not being invoked periodically as expected.
 * [New](https://github.com/segmentio/analytics-ios/pull/557): Automatically track campaign data.

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];
 configuration.trackPushNotifications = YES;
 [SEGAnalytics setupWithConfiguration:configuration];
 ```

 * [New](https://github.com/segmentio/analytics-ios/pull/573): Automatically track deep links. Please note that you'll still need to call the `continueUserActivity` and `openURL` methods on the analytics client.

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];
 configuration.trackDeepLinks = YES;
 [SEGAnalytics setupWithConfiguration:configuration];
 ```

 * [Improvement](https://github.com/segmentio/analytics-ios/pull/565): Limit queue size to 1000. This will prevent crashes/memory issues from the queue being too large.
 * [Fix](https://github.com/segmentio/analytics-ios/pull/563): Replace Foundation import with UIKit import.
 * [Improvement](https://github.com/segmentio/analytics-ios/pull/567): Exclude cache files from backup.
 * [New](https://github.com/segmentio/analytics-ios/pull/572): Add tvOS support.
 * [New](https://github.com/segmentio/analytics-ios/pull/575): Update context object with referrer information.

Version 3.2.6 *(07-10-2016)*
-----------------------------
 * Improvement: Handle case when root view is a navigation controller.
 * Improvement: More user friendly assert messages.
 * New: Add method to retrieve anonymousID.
 * New: Carthage support.
 * Fix: Case when ViewController title is an empty string.
 * Improvement: Fixes the following static analyzer warnings.

 ```
 SEGReachability.m:115:9: Potential leak of an object stored into 'ref'
 SEGReachability.m:131:9: Potential leak of an object stored into 'ref'
 ```

Version 3.2.5 *(06-30-2016)*
-----------------------------
 * Fix: Correctly skip sending events for disabled events in the tracking plan.

Version 3.2.4 *(06-08-2016)*
-----------------------------
 * Fix: Handle case when ViewController is named simply "ViewController".

Version 3.2.3 *(06-08-2016)*
-----------------------------

 * Fix: Handle case when ViewController is named simply "ViewController".
 * Fix: Namespace NSData GZIP extension methods to avoid conflicts.
 * Fix: Build and version were reversed in automatic application lifecycle tracking.
 * Instrument automatic in app purchase tracking. Enable this during initialization.

 ```objc
 SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];
 configuration.trackInAppPurchases = YES;
 [SEGAnalytics setupWithConfiguration:configuration];
 ```

Version 3.2.2 *(06-06-2016)*
-----------------------------

 * Improvement: gzip http request body.
 * Fix: Implement workaround for CTTelephonyNetworkInfo bug.

Version 3.2.1 *(06-03-2016)*
-----------------------------

 * Fix potential duplication of events in queue when there are events queued in NSUserDefaults and on disk.

Version 3.2.0 *(06-01-2016)*
-----------------------------

 * Analytics-iOS Core SDK now includes support for iOS 7.0+ (Previously 8.0+). Bundled integrations may have different OS version requirements, please check the specific integration you use for details.

Version 3.1.2 *(05-31-2016)*
-----------------------------

 * Store event queue and traits to disk instead of NSUserDefaults. We will check for queue/traits in NSUserDefaults and copy to disk if they exist.

Version 3.1.1 *(05-24-2016)*
-----------------------------

 * Instrument automatic screen view tracking. Enable this during initialization.

```objc
SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];
configuration.recordScreenViews = YES;
[SEGAnalytics setupWithConfiguration:configuration];
```

Version 3.1.0 *(05-09-2016)*
-----------------------------

 * Instrument automatic application lifecycle event tracking. Enable this during initialization.

```objc
SEGAnalyticsConfiguration *configuration = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];
configuration.trackApplicationLifecycleEvents = YES;
[SEGAnalytics setupWithConfiguration:configuration];
```

 * Make `SEGAnalyticsIntegrationDidStart` public (use this to be notified when an integration is initialized).
 * Fixed crashes due to NSNotificationCenter observers not being removed.

Version 3.0.7 *(02-01-2016)*
-----------------------------

 * Make `initWithConfiguration` public.

Version 3.0.6 *(01-12-2016)*
-----------------------------

 * Fix crash with forwarding notification info to integrations.

Version 3.0.5 *(01-08-2016)*
-----------------------------

 * Fix crash with using NSUserDefaults.
 * Fix issue with location updates.
 * Forward notification info to integrations.

Version 3.0.4 *(01-05-2016)*
----------------------------------

 * Use NSUserDefaults for persistence where possible.
 * Fix how we detect whether the device is offline or not.
 * Correctly send `context.library.version`.


Version 3.0.3 *(12-11-2015)*
----------------------------------

 * Deliver application lifecycle and push events synchronously to integrations when possible.

Version 3.0.2 *(12-07-2015)*
----------------------------------

 * Add ability to set a custom anonymous ID.

Version 3.0.1 *(11-24-2015)*
----------------------------------

 * Fix bug with overriding `userId` in alias calls (this bug would manifest when trying to alias anonymous users).

Version 3.0.0 *(11-24-2015)*
----------------------------------

 * v3 Release. This release restructures bundled integrations, which requires a few additional steps.

Add the integration dependencies.
```
pod `Segment`
pod `Segment-Bugsnag`
pod `Segment-Branch`
...
```

Register them in your configuration when you initialize the SDK.
```
SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY"];

// Add any of your bundled integrations.
config use:[SEGGoogleAnalyticsIntegrationFactory instance];
config use:[BNCBranchIntegrationFactory instance];
...

[SEGAnalytics setupWithConfiguration:config];
```

Version 3.0.4-alpha *(10-24-2015)*
----------------------------------

 * Adds API to track notification lifecycle.


Version 3.0.3-alpha *(10-21-2015)*
----------------------------------

 * Fixes bug where traits in identify and group were ignored.


Version 3.0.2-alpha *(10-11-2015)*
----------------------------------

 * Fixes `pod lib lint` warnings.
