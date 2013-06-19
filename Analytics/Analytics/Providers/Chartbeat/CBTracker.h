// -*- mode: objc -*-
//
//  CBTracker.h
//
//  Chartbeat-iOS-SDK
//
//  Copyright 2012, chartbeat
//

#import <Foundation/Foundation.h>

/**
 * Chartbeat iOS Tracker.
 *
 * \b Setup
 *
 * Drag CBTracker.h and \c libChartbeat-iOS-SDK.a into your project.
 *
 * \b Usage
 *
 *  Import the CBTracker.h file in your app's delegate and files where
 *  you plan to use the tracker.
 *
 *  \code
 *  #import "CBTracker.h"
 *  \endcode
 *
 *  Start the tracker by calling the \c startTrackerWithAccountID method 
 *  on the tracker singleton obtained via \c [CBTracker \c sharedTracker]. 
 *  It is often convenient to call this method directly in the 
 *  \c applicationDidFinishLaunching method of your app's delegate. 
 *  \code
 *  [[CBTracker sharedTracker] startTrackerWithAccountID:1234];
 *  \endcode
 *  
 *  Mostly for debugging purposes, it is also possible to add a suffix
 *  to the tracked bundle identifier. So if the bundle is called
 *  com.example.ios, and the suffix is "debug", the SDK will track to
 *  "com.example.ios.debug".
 * 
 *  \code
 *  [[CBTracker sharedTracker] startTrackerWithAccountID:1234 suffix:@"mysuffix"];
 *  \endcode
 *
 *  You can find your account id here: http://chartbeat.com/docs/account_id
 *
 *  Tracking views is straightforward: simply call \c trackView 
 *  of the tracker object each time you wish to trigger a view. Pass the
 *  view id and title for your view. For example:
 *
 *  \code
 *  [[CBTracker sharedTracker] trackView:self.view viewId:@"firstview" title:@"First View"];
 *  \endcode
 * 
 *  To stop tracking call the \c stopTracker method. You don't need to call
 *  \c stopTracker before calling \c trackView.
 * 
 *  \code
 *  [[CBTracker sharedTracker] stopTracker];
 *  \endcode
 * 
 *  After a \c stopTracker call you can resume tracking with using \c trackView.
 */
@interface CBTracker : NSObject

/**
 * Singleton instance of this class for convenience.
 */
+ (CBTracker *)sharedTracker;

/**
 * Initialize the chartbeat tracker library.
 *
 * @param uid Your chartbeat account user id
 *
 * See http://chartbeat.com/docs/account_id for your account id.
 */
- (BOOL)startTrackerWithAccountID:(int)uid_;

/**
 * Initialize the chartbeat tracker library.
 *
 * @param uid Your chartbeat account user id
 * @param suffix An application identifier. Alphanumeric. 
 *               Will be attached to your bundle id com.company.product.<suffix>
 *
 * See http://chartbeat.com/docs/account_id for your account id.
 */
- (BOOL)startTrackerWithAccountID:(int)uid_ suffix:(NSString *)suffix;

/**
 * Track a view.
 *
 * Passing in an actual view is optional. If a view is passed in,
 * it is used for sending scroll height information to chartbeat.
 *
 * @param view Optional, current view (that inherits UIScrollView) 
 * @param viewId Unique identifier for the view
 * @param title Descriptive title of the view
 */
- (BOOL)trackView:(id)view viewId:(NSString *)viewId title:(NSString *)title;

/**
 * Set whether the user is in an active state or not. I.e. if the user
 * is just reading a view, not doing any interaction with the app,
 * this should be set to \c NO. The default state is \c YES.
 *
 * @note Calling \c trackView will automatically set \c active to \c YES.
 *
 * @param active \c NO if user is inactive, \c YES otherwise.
 */
- (void)active:(BOOL)active;

/**
 * Sets the minimum interval, in seconds, to wait between sending
 * chartbeat tracking beacons. The higher the number, the less
 * precise.
 *
 * The default value is 15 seconds.
 *
 * @note This will take effect on the next call to \c trackView
 *
 * @param interval New interval (seconds)
 */
- (void)setInterval:(int)interval;

/**
 * Stop tracking.
 *
 * Usually not needed. If you plan to continue tracking, use \c
 * trackView.
 */
- (void)stopTracker;

@end
