Pod::Spec.new do |s|
  s.name           = "Analytics"
  s.version        = "0.6.0"
  s.summary        = "Segment.io Analytics library for iOS."
  s.homepage       = "https://segment.io/libraries/ios"
  s.license        = { :type => "MIT", :file => "License.md" }
  s.author         = { "Segment.io" => "friends@segment.io" }

  s.source         = { :git => "git@github.com:segmentio/analytics-ios.git", :tag => '#{s.version}' }
  s.source_files   = 'Analytics/**/*.{h,m}'
  s.frameworks     = 'Foundation', 'UIKit'
  
  s.dependency       'Amplitude-iOS', '~> 1.0.1'
  s.dependency       'Bugsnag', '~> 2.2.3'
  s.dependency       'Chartbeat', '~> 0.0.1'
  s.dependency       'Countly', '~> 1.0.0'
  s.dependency       'FlurrySDK', '~> 4.2.3'
  s.dependency       'GoogleAnalytics-iOS-SDK', '~> 3.0'
  s.dependency       'KISSmetrics', '~> 1.1.3'
  s.dependency       'Localytics-iOS-Client', '~> 2.17.0'
  s.dependency       'Mixpanel', '~> 2.0.0'
end