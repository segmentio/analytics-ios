Change Log
==========

Version 3.1.0 *(05-09-2016)*
-----------------------------

 * Make `SEGAnalyticsIntegrationDidStart` public (use this to be notified when an integration is initialized).
 * Fixed crashes due to NSNotificationCenter observers not being removed.
 * Instrument automatic application lifecycle event tracking.

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
