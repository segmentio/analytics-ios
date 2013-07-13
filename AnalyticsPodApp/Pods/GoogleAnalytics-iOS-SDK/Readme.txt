Google Analytics iOS SDK version 2.0 Beta 4

Copyright 2009 - 2013 Google, Inc. All rights reserved.

================================================================================
DESCRIPTION:

This SDK provides developers with the capability to use Google Analytics
to track iOS application usage.

The SDK is packaged as a set of header files and a static library. Get started
by adding the header files from the Library subdirectory (GAI.h, GAITracker.h,
GAITransaction.h, and GAITransactionItem.h) and libGoogleAnalytics.a to your
XCode project. You must also include the CoreData framework in your project.

To use a version of the library with debug symbols intact, link against
libGoogleAnalytics_debug.a instead of libGoogleAnalytics.a. This may be useful
if you experience exceptions or crashes originating in the SDK.

See the Examples/CuteAnimals application for an illustration of how to use
automatic screen tracking, event tracking, and uncaught exception tracking.

You will need a Google Analytics tracking ID to track application usage with the
SDK. It is recommended to create an account for each set of applications that
are to be tracked together, and to use that account's tracking ID in each
application. To create a new tracking ID, go to your admin panel in Google
Analytics and select "New Account". Under "What would you like to track?",
choose "App" and complete the remainder of the form. When you are finished,
click "Get Tracking ID". The tracking ID will be of the form "UA-" followed by a
sequence of numbers and dashes.

You must indicate to your users, either in the app itself or in your terms of
service, that you reserve the right to anonymously track and report a user's
activity inside of your app.

Implementation Details:

Tracking information is stored in an SQLite database and dispatched to the
Google Analytics servers in a manner set by the developer: periodically at an
interval determined by the developer, immediately when tracking calls are made,
or manually. A battery efficient strategy may be to initiate a dispatch when the
application needs to access the network. Tracking information is dispatched
using HTTP or HTTPS requests to a Google Analytics server.

================================================================================
BUILD REQUIREMENTS:

Mac OS X 10.6 or later.
XCode with iOS SDK 4.0 or later (iOS SDK 5.0 or later is required to build the
included example application).

================================================================================
RUNTIME REQUIREMENTS:

iOS 4.0 or later.

Your app must link the following frameworks:
  CoreData.framework
  SystemConfiguration.framework

================================================================================
PACKAGING LIST:

Library/ (contains header and library files to compile and link with)
  GAI.h
  GAITrackedViewController.h
  GAITracker.h
  GAITransaction.h
  GAITransactionItem.h
  libGoogleAnalytics.a
  libGoogleAnalytics_debug.a
Examples/ (contains an example tracked application)
Documentation/ (contains documentation)

================================================================================
