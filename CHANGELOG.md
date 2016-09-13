Change Log
==========

Version 3.5.0 *(12th September, 2016)*
-------------------------------------

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
