## Developer Feedback Requested: Analytics-Swift Pilot

**A pilot release of the new Analytics-Swift library is available at the [Analytics-Swift repository](https://github.com/segmentio/analytics-swift). This library is governed by [Segment’s First-Access and Beta terms](https://segment.com/legal/first-access-beta-preview/), and should not be used in production scenarios.**

During the pilot phase, Segment wants your feedback, contributions, and ideas. If you have requirements or ideas for features for Analytics-Swift and Segment's integration with the Apple platform, let us know.

# Analytics
[![Circle CI](https://circleci.com/gh/segmentio/analytics-ios.svg?style=shield&circle-token=31c5b3e5edeb404b30141ead9dcef3eb37d16d4d)](https://circleci.com/gh/segmentio/analytics-ios)
[![Version](https://img.shields.io/cocoapods/v/Analytics.svg?style=flat)](https://cocoapods.org//pods/Analytics)
[![License](https://img.shields.io/cocoapods/l/Analytics.svg?style=flat)](http://cocoapods.org/pods/Analytics)
[![codecov](https://codecov.io/gh/segmentio/analytics-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/segmentio/analytics-ios)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM Compatible](https://img.shields.io/badge/SwiftPM-Compatible-F05138.svg)](https://swift.org/package-manager/)

analytics-ios is an iOS client for Segment.

Special thanks to [Tony Xiao](https://github.com/tonyxiao), [Lee Hasiuk](https://github.com/lhasiuk) and [Cristian Bica](https://github.com/cristianbica) for their contributions to the library!

<div align="center">
  <img src="https://user-images.githubusercontent.com/16131737/53752615-e66b8000-3e63-11e9-98f6-f478c7076537.png"/>
  <p><b><i>You can't fix what you can't measure</i></b></p>
</div>

Analytics helps you measure your users, product, and business. It unlocks insights into your app's funnel, core business metrics, and whether you have product-market fit.

## How to get started
1. **Collect analytics data** from your app(s).
    - The top 200 Segment companies collect data from 5+ source types (web, mobile, server, CRM, etc.).
2. **Send the data to analytics tools** (for example, Google Analytics, Amplitude, Mixpanel).
    - Over 250+ Segment companies send data to eight categories of destinations such as analytics tools, warehouses, email marketing and remarketing systems, session recording, and more.
3. **Explore your data** by creating metrics (for example, new signups, retention cohorts, and revenue generation).
    - The best Segment companies use retention cohorts to measure product market fit. Netflix has 70% paid retention after 12 months, 30% after 7 years.

[Segment](https://segment.com) collects analytics data and allows you to send it to more than 250 apps (such as Google Analytics, Mixpanel, Optimizely, Facebook Ads, Slack, Sentry) just by flipping a switch. You only need one Segment code snippet, and you can turn integrations on and off at will, with no additional code. [Sign up with Segment today](https://app.segment.com/signup).

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

### 🚀 Startup Program
<div align="center">
  <a href="https://segment.com/startups"><img src="https://user-images.githubusercontent.com/16131737/53128952-08d3d400-351b-11e9-9730-7da35adda781.png" /></a>
</div>
If you are part of a new startup  (&lt;$5M raised, &lt;2 years since founding), we just launched a new startup program for you. You can get a Segment Team plan  (up to <b>$25,000 value</b> in Segment credits) for free up to 2 years — <a href="https://segment.com/startups/">apply here</a>!

## Installation

Analytics is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

```ruby
pod "Analytics", "3.7.0"
```
Note: Segment _strongly_ recommends that you use a dynamic framework to manage your project dependencies. If you prefer static libraries, you can add `use_modular_headers!` or `use_frameworks! :linkage => :static` in your Podfile. However, you must then _manually update_ all of your dependencies on a regular schedule.

### Carthage

```
github "segmentio/analytics-ios"
```

### Swift Package Manager (SPM)

To add analytics-ios via Swift Package Mangaer, it is possible to add it one of two ways:

#### Xcode
![Xcode Add SPM Package](https://user-images.githubusercontent.com/917994/119199146-69765200-ba3f-11eb-9173-93cfb5f3cabd.png)

![ChoosePackageRepository](https://user-images.githubusercontent.com/917994/119199143-68ddbb80-ba3f-11eb-9bf2-5dc11c208abd.png)

![ChoosePackageOptions](https://user-images.githubusercontent.com/917994/119199139-67ac8e80-ba3f-11eb-9941-fc541030f3df.png)


#### Package.swift
```
import PackageDescription

let package = Package(
    name: "MyApplication",
    dependencies: [
        // Add a package containing Analytics as the name along with the git url
        .package(
            name: "Segment",
            url: "git@github.com:segmentio/analytics-ios.git"
        )
    ],
    targets: [
        name: "MyApplication",
        dependencies: ["Segment"] // Add Analytics as a dependency of your application
    ]
)
```
Note: Segment recommends that you use Xcode to add your package.

## Quickstart

Refer to the Quickstart documentation at [https://segment.com/docs/libraries/ios/quickstart](https://segment.com/docs/libraries/ios/quickstart/).

## Documentation

More detailed documentation is available at [https://segment.com/docs/libraries/ios](https://segment.com/docs/libraries/ios/).
