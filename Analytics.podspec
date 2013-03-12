Pod::Spec.new do |s|
  s.name         = "Analytics"
  s.version      = "0.0.2"
  s.summary      = "Segment.io Analytics library for iOS and OSX."
  s.homepage     = "https://segment.io/libraries/ios"
  s.license      = "MIT"
  s.author       = { "Peter Reinhardt" => "peter@segment.io" }

  s.source       = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => "0.0.2" }
  s.source_files = 'Analytics.{h,m}'
  s.requires_arc = true

  s.osx.deployment_target = '10.7'
  s.ios.deployment_target = '5.0'

end
