Change Log
==========

Version 3.0.1 *(10-24-2015)*
----------------------------------

 * Fix bug with overriding `userId` in alias calls (this bug would manifest when trying to alias anonymous users).

Version 3.0.0 *(10-24-2015)*
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
