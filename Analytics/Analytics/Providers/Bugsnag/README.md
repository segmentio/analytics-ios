Bugsnag Notifier for iOS
========================

The Bugsnag Notifier for iOS gives you instant notification of exceptions thrown from your iOS applications.
The notifier hooks into `NSSetUncaughtExceptionHandler`, which means any uncaught exceptions will trigger a notification to be sent to your Bugsnag project. Bugsnag will also monitor for fatal signals sent to your application, for example a Segmentation Fault.

[Bugsnag](http://bugsnag.com) captures errors in real-time from your web, mobile and desktop applications, helping you to understand and resolve them as fast as possible. [Create a free account](http://bugsnag.com) to start capturing exceptions from your applications.


Installation & Setup
--------------------

###CocoaPods (Recommended)

[Cocoapods](http://cocoapods.org/) is a library management system for iOS which allows you to manage your libraries, detail your dependencies and handle updates nicely. It is the recommended way of installing the Bugsnag iOS library.

- Add Bugsnag to your Podfile

```ruby
pod 'Bugsnag'
```

- Install Bugsnag

```bash
pod install
```

- Import the `Bugsnag.h` file into your application delegate.

```objective-c
#import "Bugsnag.h"
```

- In your application:didFinishLaunchingWithOptions: method, register with bugsnag by calling,

```objective-c
[Bugsnag startBugsnagWithApiKey:@"your-api-key-goes-here"];
```

### Manual Install

- Download and unzip the latest version.

```bash
wget -O bugsnag.zip https://github.com/bugsnag/bugsnag-ios/zipball/master
unzip bugsnag.zip
```

- Include all files in the `Bugsnag Plugin` folder in your Xcode project.

- Add `SystemConfiguration.framework` to your Link Binary With Libraries section in your project's Build Phases.

- Import the `Bugsnag.h` file into your application delegate.

```objective-c
#import "Bugsnag.h"
```

- In your application:didFinishLaunchingWithOptions: method, register with bugsnag by calling,

```objective-c
[Bugsnag startBugsnagWithApiKey:@"your-api-key-goes-here"];
```

###ARC Support

Since version 2.2.0 Bugsnag has fully supported Arc. If you wish to run a non-Arc build of Bugsnag you should use version 2.1.0 or older.

If you are using Bugsnag 2.2.0 or newer in your non-arc project, you will need to set a `-fobjc-arc` compiler flag on all of the Bugsnag source files. Conversely, if you are adding a pre-2.2.0 version of Bugsnag, you will need to set a `-fno-objc-arc` compiler flag.

To set a compiler flag in Xcode, go to your active target and select the "Build Phases" tab. Now select all Bugsnag source files, press Enter, insert `-fobjc-arc` or `-fno-objc-arc` and then "Done" to enable or disable ARC for Bugsnag.

JSON Library
------------

The Bugsnag iOS notifier requires a JSON library. It is able to use the library introduced in iOS 5 if it is available. Otherwise it looks for any of the following libraries:

- [JSONKit](https://github.com/johnezang/JSONKit)
- [NextiveJson](https://github.com/nextive/NextiveJson)
- [SBJson](https://stig.github.com/json-framework/)
- [YAJL](https://lloyd.github.com/yajl/)

If you are targetting iOS 4.3 or older, you should include one of these libraries in your project to ensure you are notified of crashes on those versions of iOS.


Send Non-Fatal Exceptions to Bugsnag
------------------------------------

If you would like to send non-fatal exceptions to Bugsnag, you can pass any `NSException` to the `notify` method:

```objective-c
[Bugsnag notify:[NSException exceptionWithName:@"ExceptionName" reason:@"Something bad happened" userInfo:nil]];
```

You can also send additional meta-data with your exception:

```objective-c
[Bugsnag notify:[NSException exceptionWithName:@"ExceptionName" reason:@"Something bad happened" userInfo:nil]
       withData:[NSDictionary dictionaryWithObjectsAndKeys:@"username", @"bob-hoskins", nil]];
```

Adding Tabs to Bugsnag Error Reports
------------------------------------

If you want to add a tab to your Bugsnag error report, you can call the `addToTab` method:

```objective-c
[Bugsnag addAttribute:@"username" withValue:@"bob-hoskins" toTabWithName:@"user"];
[Bugsnag addAttribute:@"registered-user" withValue:@"yes" toTabWithName:@"user"];
```

This will add a user tab to any error report sent to bugsnag.com that contains the username and whether the user was registered or not.

You can clear a single attribute on a tab by calling:

```objective-c
[Bugsnag addAttribute:@"username" withValue:nil toTabWithName:@"user"];
```

or you can clear the entire tab:

```objective-c
[Bugsnag clearTabWithName:@"user"];
```

Configuration
-------------

###context

Bugsnag uses the concept of "contexts" to help display and group your errors. Contexts represent what was happening in your application at the time an error occurs. The iOS Notifier will set this to be the top most UIViewController, but if in a certain case you need to override the context, you can do so using this property:

```objective-c
[Bugsnag instance].context = @"MyUIViewController";
```

###userId

Bugsnag helps you understand how many of your users are affected by each error. In order to do this, we send along a userId with every exception. By default we will generate a unique ID and send this ID along with every exception from an individual device.

If you would like to override this `userId`, for example to set it to be a username of your currently logged in user, you can set the `userId` property:

```objective-c
[Bugsnag instance].userId = @"leeroy-jenkins";
```

###releaseStage

In order to distinguish between errors that occur in different stages of the application release process a release stage is sent to Bugsnag when an error occurs. This is automatically configured by the iOS notifier to be "production", unless DEBUG is defined during compilation. In this case it will be set to "development". If you wish to override this, you can do so by setting the releaseStage property manually:

```objective-c
[Bugsnag instance].releaseStage = @"development";
```

###notifyReleaseStages

By default, we will only notify Bugsnag of exceptions that happen when your `releaseStage` is set to be either "production" or "development". If you would like to change which release stages notify Bugsnag of exceptions you can set the `notifyReleaseStages` property:

```objective-c
[Bugsnag instance].notifyReleaseStages = [NSArray arrayWithObjects:@"production", nil];
```

###autoNotify

By default, we will automatically notify Bugsnag of any fatal exceptions in your application. If you want to stop this from happening, you can set `autoNotify` to NO:

```objective-c
[Bugsnag instance].autoNotify = NO;
```

###enableSSL

By default, Bugsnag enables the use of SSL encryption when sending errors to Bugsnag. If you want to use an unencrypted connection to Bugsnag, you can set `enableSSL` to NO:

```objective-c
[Bugsnag instance].enableSSL = NO;
```

Stacktrace Information
----------------------

In order for the stacktrace information to be included with the bug reports on Bugsnag, the following settings should be
configured.

- Deployment Postprocessing: Off
- Strip debug symbols during copy: Off
- Strip linked product: Off

**Note:** This will increase the size of the application slightly.


Reporting Bugs or Feature Requests
----------------------------------

Please report any bugs or feature requests on the github issues page for this project here:

<https://github.com/bugsnag/bugsnag-ios/issues>


Contributing
------------

-   [Fork](https://help.github.com/articles/fork-a-repo) the [notifier on github](https://github.com/bugsnag/bugsnag-ios)
-   Commit and push until you are happy with your contribution
-   [Make a pull request](https://help.github.com/articles/using-pull-requests)
-   Thanks!


License
-------

The Bugsnag iOS notifier is free software released under the MIT License. See [LICENSE.txt](https://github.com/bugsnag/bugsnag-ios/blob/master/LICENSE.txt) for details.
