Pod::Spec.new do |s|
  s.name         = "Analytics"
  s.version      = "0.3.0"
  s.summary      = "Segment.io Analytics library for iOS and OSX."
  s.homepage     = "https://segment.io/libraries/ios-osx"
  s.license      = { :type => "MIT", :file => "License.md" }
  s.author       = { "Segment.io" => "friends@segment.io" }

  s.source       = { :git => "https://github.com/segmentio/analytics-ios-osx.git", :tag => "0.3.0" }
  s.source_files = ['Analytics.{h,m}', 'Source/**/*.{h,m}']
  s.requires_arc = true

  s.osx.deployment_target = '10.7'
  s.ios.deployment_target = '5.0'

  s.dependency 'Bugsnag'
  s.dependency 'CrittercismSDK'
  s.dependency 'FlurrySDK'
  s.dependency 'GoogleAnalytics-iOS-SDK'
  s.dependency 'Localytics'
  s.dependency 'Mixpanel'
  s.dependency 'Chartbeat'

end
