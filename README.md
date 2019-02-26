# Analytics
[![Circle CI](https://circleci.com/gh/segmentio/analytics-ios.svg?style=shield&circle-token=31c5b3e5edeb404b30141ead9dcef3eb37d16d4d)](https://circleci.com/gh/segmentio/analytics-ios)
[![Version](https://img.shields.io/cocoapods/v/Analytics.svg?style=flat)](https://cocoapods.org//pods/Analytics)
[![License](https://img.shields.io/cocoapods/l/Analytics.svg?style=flat)](http://cocoapods.org/pods/Analytics)
[![codecov](https://codecov.io/gh/segmentio/analytics-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/segmentio/analytics-ios)

analytics-ios is an iOS client for Segment.

Special thanks to [Tony Xiao](https://github.com/tonyxiao), [Lee Hasiuk](https://github.com/lhasiuk) and [Cristian Bica](https://github.com/cristianbica) for their contributions to the library!

## Installation

Analytics is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

```ruby
pod "Analytics", "3.6.10"
```

### Carthage

```
github "segmentio/analytics-ios"
```

## 🏃💨 Swift Quickstart
<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53451779-77f67000-39d4-11e9-8657-861c97c5de1b.png"/>
  <p><b><i>You can't fix what you can't measure</i></b></p>
</div>

Analytics helps you measure your users, product, and business. It unlocks insights into your app's funnel, core business metrics, and whether you have product-market fit.

### How to get started
1. **Collect analytics data** from your app(s).
    - The top 200 Segment companies collect data from 5+ source types (web, mobile, server, CRM, etc.).
2. **Send the data to analytics tools** (for example, Google Analytics, Amplitude, Mixpanel).
    - Over 250+ Segment companies send data to eight categories of destinations such as analytics tools, warehouses, email marketing and remarketing systems, session recording, and more.
3. **Explore your data** by creating metrics (for example, new signups, retention cohorts, and revenue generation).
    - The best Segment companies use retention cohorts to measure product market fit. Netflix has 70% paid retention after 12 months, 30% after 7 years.

[Segment](https://segment.com?utm_source=github&utm_medium=click&utm_campaign=protos_swift) collects analytics data and allows you to send it to more than 250 apps (such as Google Analytics, Mixpanel, Optimizely, Facebook Ads, Slack, Sentry) just by flipping a switch. You only need one Segment code snippet, and you can turn integrations on and off at will, with no additional code. [Sign up with Segment today](https://app.segment.com/signup?utm_source=github&utm_medium=click&utm_campaign=protos_swift).

### Why?
1. **Power all your analytics apps with the same data**. Instead of writing code to integrate all of your tools individually, send data to Segment, once.

2. **Install tracking for the last time**. We're the last integration you'll ever need to write. You only need to instrument Segment once. Reduce all of your tracking code and advertising tags into a single set of API calls.

3. **Send data from anywhere**. Send Segment data from any device, and we'll transform and send it on to any tool.

4. **Query your data in SQL**. Slice, dice, and analyze your data in detail with Segment SQL. We'll transform and load your customer behavioral data directly from your apps into Amazon Redshift, Google BigQuery, or Postgres. Save weeks of engineering time by not having to invent your own data warehouse and ETL pipeline.

    For example, you can capture data on any app:
    ```js
    analytics.track('Order Completed', { price: 99.84 })
    ```
    Then, query the resulting data in SQL:
    ```sql
    select * from app.order_completed
    order by price desc
    ```
---
In this tutorial you'll add your write key to the Swift demo app to start sending data from the app to Segment, and from there to any of our destinations, using our [analytics-ios library](https://segment.com/docs/sources/mobile/ios?utm_source=github&utm_medium=click&utm_campaign=protos_swift). Once your app is set up, you'll be able to turn on new destinations with the click of a button! Ready to try it for yourself? Scroll down to the <a href="#demo">demo section</a> and run the app!

Start sending data from your iOS source by interacting with the demo app:

<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53607045-f0defe80-3b71-11e9-9e38-2b844fc3ec4b.gif" height="700"/>
</div>
<br/>

And view events occur live in your Segment Debugger:

<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53607629-664bce80-3b74-11e9-9d6d-d4b3331e7bae.gif"/>
</div>

## 🔌 Installing on Your App
How do you get this in your own Swift app? Follow the steps below.

### 📦 Step 1: Install the SDK
To install Segment in your own app, follow the 3 steps below:
1. The recommended way to install Analytics for iOS is via [Cocoapods](http://cocoapods.org/). Add the `Analytics` dependency to your `Podfile` to access the SDK:
	```Swift
	pod 'Analytics', :git => 'https://github.com/segmentio/analytics-ios.git', :branch => 'master'
	```
	If you are using [Carthage](https://github.com/Carthage/Carthage), use this line in your  `Cartfile`:
	```Swift
	github "segmentio/analytics-ios" "master"
	```

2. In `AppDelegate`, import the library:
	```Swift
	import Analytics
	```

	Then, modify your `application` method with the following snippet below:
    ```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = SEGAnalyticsConfiguration(writeKey: "YOUR_WRITE_KEY")
        SEGAnalytics.setup(with: config)
        return true
    }
    ```

3. [Sign up with Segment](https://app.segment.com/signup?utm_source=github&utm_medium=click&utm_campaign=protos_swift) and locate your Segment project's **Write Key**. Replace `YOUR_WRITE_KEY` in the snippet above with your Segment project's write key.<br/>
    > **Tip!** You can find your write key in your Segment project setup guide or settings.

Now `SEGAnalytics.shared()` is loaded and available to use throughout your app!

#### Logging
To see a trace of your data going through the SDK, you can enable debug logging with  `debug` property. Set the `debug` property to `true` on the `config` object in your `AppDelegate`:
```Swift
config.debug = true
```
#### Middleware
A middleware is a simple function that is invoked by the Segment SDK and can be used to monitor, modify or reject events.

See the middlewares section in our [official documentation](https://segment.com/docs/sources/mobile/ios/#middlewares).

In the next sections you'll build out your implementation to track screen loads, to identify individual users of your app, and track the actions they take.

### 📱 Step 2: Track Screen Views
The snippet from Step 1 loads `analytics-ios` into your app and is ready to track screen loads. The `screen` method lets you record screen views on your website, along with optional information about the screen being viewed. You can read more about how this works in the [screen reference](https://segment.com/docs/sources/mobile/ios/#screen?utm_source=github&utm_medium=click&utm_campaign=protos_swift).

#### Automatic Screen Calls
Our SDK can automatically instrument screen calls. It can detect when `ViewControllers` are loaded and uses the label of the view controller (or the class name if a label is not available) as the screen name. If present, it removes the string "ViewController" from the name.

Set the `recordScreenViews` property to `true` on the `config` object in your `AppDelegate`:

```Swift
config.recordScreenViews = true
```

#### Manual Screen Calls
If your screens are separated into their own `UIViewController` classes, you can use the inherited `viewDidAppear` method to invoke `screen` calls. The example below shows one way you could do this.

```Swift
import UIKit
import Analytics

class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SEGAnalytics.shared().screen("Home")
    }
}
```

### 🔍 Step 3: Identify Users
The `identify` method is how you tell Segment who the current user is. It includes a unique User ID and any optional traits you can pass on about them. You can read more about this in the [identify reference](https://segment.com/docs/sources/mobile/ios/#identify?utm_source=github&utm_medium=click&utm_campaign=protos_swift).

**Note:** You don't need to call `identify` for anonymous visitors to your site. Segment automatically assigns them an `anonymousId`, so just calling `screen` and `track` still works just fine without `identify`.

Here's what a basic call to `identify` might look like:

```Swift
SEGAnalytics.shared().identify("f4ca124298", properties: [
    "name": "Michael Bolton",
    "email": "mbolton@initech.com"
])
```

This call identifies Michael by his unique User ID and labels him with `name` and `email` traits.

In Swift, if you have a form where users sign up or log in, you can use an action method and bind a `UIButton` handler to call `identify`, as in the example below:

```Swift
import UIKit
import Analytics

class SignUpViewController: UIViewController {

    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var emailField: UITextField!
    @IBOutlet fileprivate var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        usernameField.text = ""
        emailField.text = ""
        passwordField.text = ""
    }

    @IBAction func signUp(_ sender: UIButton) {
        // Handle sign up validation logic...
      
        // Add your own unique ID here or we will automatically assign an anonymousID
        SEGAnalytics.shared().identify(traits: [
            "name": usernameField.text,
            "email": emailField.text
        ])
    }
}
```

### ⏰ Step 4: Track Actions
The `track` method is how you tell Segment about which actions your users are performing on your site. Every action triggers what we call an "event", which can also have associated properties. It is important to figure out exactly what events you want to `track` instead of tracking anything and everything. A good way to do this is to build a [tracking plan](https://segment.com/docs/guides/sources/can-i-see-an-example-of-a-tracking-plan?utm_source=github&utm_medium=click&utm_campaign=protos_swift). You can read more about `track` in the [track reference](https://segment.com/docs/sources/mobile/ios/#track?utm_source=github&utm_medium=click&utm_campaign=protos_swift).

Here's what a call to `track` might look like when a user bookmarks an article:

```Swift
SEGAnalytics.shared().track("Article Bookmarked", properties: [
    "title": "Snow Fall",
    "subtitle": "The Avalanche at Tunnel Creek",
    "author": "John Branch"
])
```

The snippet tells us that the user just triggered the **Article Bookmarked** event, and the article they bookmarked was the `Snow Fall` article authored by `John Branch`. Properties can be anything you want to associate to an event when it is tracked.

#### Track Calls with Event Handlers
In Swift, you can use an action method to call the `track` events. In the example below, we bind a `UIButton` handler to make a `track` call to log a `User Signup`.

```Swift
@IBAction func handleSignupEvent(_ sender: UIButton) {
    SEGAnalytics.shared().track("User Signup")
}
```

### 🎓 Advanced
Once you've mastered the basics, here are some advanced use cases you can apply with Segment.

#### Eureka Form
If you're using the [Eureka library](https://github.com/xmartlabs/Eureka) to build your forms, you can use the `onChange` callback to send `track` calls for when a user interacts with part of the form.

```Swift
import Eureka
import Analytics

class MyFormViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        form +++ Section("Section1")
            <<< TextRow(){ row in
                row.title = "Text Row"
                row.placeholder = "Enter text here"
            }.onChange { row in
                SEGAnalytics.shared().track("Updated Text Row With \(row.value)")
            }

            <<< PhoneRow(){
                $0.title = "Phone Row"
                $0.placeholder = "And numbers here"
            }.onChange {
                SEGAnalytics.shared().track("Updated Phone Row With \($0.value)")
            }

        +++ Section("Section2")
            <<< DateRow(){
                $0.title = "Date Row"
                $0.value = Date(timeIntervalSinceReferenceDate: 0)
            }.onChange {
                SEGAnalytics.shared().track("Updated Date Row With \($0.value)")
            }
    }
}
```

### ⌛ Batching
You may see a delay in some of your events because of the behavior of our SDK. Our SDK queues API calls so that we:
+ **Reduce Network Usage** — Each batch is gzip compressed, decreasing the amount of bytes on the wire by 10x-20x.
+ **Save Battery** — Because of data batching and compression, Segment's SDKs reduce energy overhead by 2-3x which means longer battery life for your app's users.

It is **not recommended**, but you can immediately send your queued events by calling `flush` after your original call:
```Swift
SEGAnalytics.shared().screen("About")
SEGAnalytics.shared().flush()
```
Or, set your batch size to 1 by modifying the `flushAt` property  on the `config` object in your `AppDelegate`:
```Swift
config.flushAt = 1;
```

You can read more about the lifecycle of a mobile API call by reading our [blog post](https://segment.com/blog/lifecycle-of-a-mobile-message/).

### 🤔 What's next?
Once you've added a few track calls, **you're done**! You've successfully installed `analytics-ios` tracking with your Swift app. Now you're ready to see your data in the Segment dashboard, and turn on any destination tools. 🎉

You may wondering what you can be doing with all the raw data you are sending to Segment from your Swift app. With our [warehouses product](https://segment.com/product/warehouses?utm_source=github&utm_medium=click&utm_campaign=protos_swift), your analysts and data engineers can shift focus from data normalization and pipeline maintenance to providing insights for business teams. Having the ability to query data directly in SQL and layer on visualization tools can take your product to the next level.

### 💾 Warehouses
A warehouse is a special subset of destinations where we load data in bulk at a regular intervals, inserting and updating events and objects while automatically adjusting their schema to fit the data you've sent to Segment. We do the heavy lifting of capturing, schematizing, and loading your user data into your data warehouse of choice.

Examples of data warehouses include Amazon Redshift, Google BigQuery, MySQL, and Postgres.

<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53608172-9bf1b700-3b76-11e9-9c20-b9790f7ea33e.gif"/>
</div>

### 📺 <span name="demo">Demo</span>
#### Requirements:
+ Swift 4.2+
+ Xcode 10.1+
+ `analytics-ios` 3.6.10

To run the demo app, follow the instructions below:
1. [Sign up with Segment](https://app.segment.com/signup?utm_source=github&utm_medium=click&utm_campaign=protos_swift) and edit the snippet in [AppDelegate](https://github.com/segmentio/analytics-ios/tree/master/Examples/AnalyticsSwiftExample/AnalyticsSwiftExample/AppDelegate.swift#L18) to replace `YOUR_WRITE_KEY` with your Segment **Write Key**.
    > **Tip!** You can find your key in your project setup guide or settings in the Segment.

    ```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = SEGAnalyticsConfiguration(writeKey: "YOUR_WRITE_KEY")
        SEGAnalytics.setup(with: config)
        return true
    }
    ```

4. From the command line, use `pod install` to install the dependencies:
    ```bash
    pod install
    ```
	  Then, open the project in `Xcode` and press `⌘R` to run the app.
5. Go to the Segment site, and in the Debugger look at the live events being triggered in your app. You should see the following:
    - Screen event: `Home` - When someone views the `home` screen.
    - Screen event: `About` - When someone views the `about` screen.
    - Track event: `Learn About Segment Clicked` - When someone clicks the "Learn About Segment" link.

Congrats! You're seeing live data from your demo Swift app in Segment! 🎉

### 🚀 Startup Program
<div align="center">
  <a href="https://segment.com/startups"><img src="https://user-images.githubusercontent.com/16131737/53128952-08d3d400-351b-11e9-9730-7da35adda781.png" /></a>
</div>
If you are part of a new startup  (&lt;$5M raised, &lt;2 years since founding), we just launched a new startup program for you. You can get a Segment Team plan  (up to <b>$25,000 value</b> in Segment credits) for free up to 2 years — <a href="https://segment.com/startups/">apply here</a>!

### 📝 Docs & Feedback
Check out our full [analytics-ios reference](https://segment.com/docs/sources/mobile/ios?utm_source=github&utm_medium=click&utm_campaign=protos_swift) to see what else is possible, or read about the [Tracking API methods](https://segment.com/docs/sources/server/http?utm_source=github&utm_medium=click&utm_campaign=protos_swift) to get a sense for the bigger picture. If you have any questions, or see anywhere we can improve our documentation, [let us know](https://segment.com/contact?utm_source=github&utm_medium=click&utm_campaign=protos_swift)!
