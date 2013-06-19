# Setup #
1. If you haven't already, go to https://amplitude.com and register for an account. You will receive an API Key.
2. [Download the source code](https://dl.dropbox.com/s/lkevdzghs245ai6/Amplitude-iOS.zip?dl=1) and extract the zip file. Alternatively, you can pull directly from GitHub.
3. Copy the Amplitude-iOS folder into the source of your project in XCode. Check "Copy items into destination group's folder (if needed)".
4. In every file that uses analytics, import Amplitude.h at the top:

        #import "Amplitude.h"

5. In the application:didFinishLaunchingWithOptions: method of your YourAppNameAppDelegate.m file, initialize the SDK:

        [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE"];

6. To track an event anywhere in the app, call:

        [Amplitude logEvent:@"EVENT_IDENTIFIER_HERE"];

7. Events are saved locally. Uploads are batched to occur every 30 events and every 30 seconds, as well as on app close. After calling logEvent in your app, you will immediately see data appear on the Amplitude Website.

# Tracking Events #

It's important to think about what types of events you care about as a developer. You should aim to track between 5 and 50 types of events within your app. Common event types are different screens within the app, actions the user initiates (such as pressing a button), and events you want the user to complete (such as filling out a form, completing a level, or making a payment). Contact us if you want assistance determining what would be best for you to track.

# Tracking Sessions #

A session is a period of time that a user has the app in the foreground. Sessions within 10 seconds of each other are merged into a single session. In the iOS SDK, sessions are tracked automatically.

# Settings Custom User IDs #

If your app has its own login system that you want to track users with, you can call setUserId: at any time:

    [Amplitude setUserId:@"USER_ID_HERE"];

A user's data will be merged on the backend so that any events up to that point on the same device will be tracked under the same user.

You can also add the user ID as an argument to the initializeApiKey: call:
    
    [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE" userId:@"USER_ID_HERE"];

# Campaign Tracking #

Set up links for each of your campaigns on the campaigns tab at https://amplitude.com.

To track installs from each campaign source in your app, call initializeApiKey:trackCampaignSource: with an extra boolean argument to turn on campaign tracking:

    [Amplitude initializeApiKey:@"YOUR_API_KEY_HERE" trackCampaignSource:YES];

If you are not using analytics, and only want campaign tracking, call enableCampaignTrackingApiKey: instead of initializeApiKey:trackCampaignSource: in the application:didFinishLaunchingWithOptions: method of your YourAppNameAppDelegate.m file:

    [Amplitude enableCampaignTrackingApiKey:@"YOUR_API_KEY_HERE"];

You can retrieve the campaign information associated with a user by calling getCampaignInformation after you've called initializeApiKey:trackCampaignSource: or enableCampaignTrackingApiKey:

    [Amplitude getCampaignInformation];

If the SDK has successfully contacted our servers and saved the result, the @"tracked" key in the returned NSDictionary will be set to YES. You can then get the details of the campaign from the fields of the returned NSDictionary. If the SDK has not contacted our servers yet, all fields will be empty and @"tracked" will be set to NO. Only fields set in links you create will be set in the returned NSDictionary. For example, if you set "campaign" in the link, but do not set "source", "medium", "term", or "content", only the @"campaign" field will be present in the returned NSDictionary.

# Setting Custom Properties #

You can attach additional data to any event by passing a NSDictionary object as the second argument to logEvent:withCustomProperties:

    NSMutableDictionary *customProperties = [NSMutableDictionary dictionary];
    [customProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
    [Amplitude logEvent:@"Compute Hash" withCustomProperties:customProperties];

To add properties that are tracked in every event, you can set global properties for a user:

    NSMutableDictionary *globalProperties = [NSMutableDictionary dictionary];
    [globalProperties setValue:@"VALUE_GOES_HERE" forKey:@"KEY_GOES_HERE"];
    [Amplitude setGlobalUserProperties:globalProperties];

# Tracking Revenue #

To track revenue from a user, call [Amplitude logRevenue:[NSNumber numberWithDouble:3.99]] each time the user generates revenue. logRevenue: takes in an NSNumber with the dollar amount of the sale as the only argument. This allows us to automatically display data relevant to revenue on the Amplitude website, including average revenue per daily active user (ARPDAU), 7, 30, and 90 day revenue, lifetime value (LTV) estimates, and revenue by advertising campaign cohort and daily/weekly/monthly cohorts.

# Advanced #

This SDK automatically grabs useful data from the phone, including app version, phone model, operating system version, and carrier information. If the user has granted your app has location permissions, the SDK will also grab the location of the user. Amplitude will never prompt the user for location permissions itself, this must be done by your app. Amplitude only polls for a location once on startup of the app, once on each app open, and once when the permission is first granted. There is no continuous tracking of location. If you wish to disable location tracking done by the app, you can call [Amplitude disableLocationListening] at any point. If you want location tracking disabled on startup of the app, call disableLocationListening before you call initializeApiKey:. You can always reenable location tracking through Amplitude with [Amplitude enableLocationListening].

User IDs are automatically generated and will default to device specific identifiers if not specified.

This code will work with both ARC and non-ARC projects. Preprocessor macros are used to determine which version of the compiler is being used.
