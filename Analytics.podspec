Pod::Spec.new do |s|
  s.name            = "Analytics"
  s.version         = "0.9.9"
  s.summary         = "Segment.io analytics and marketing tools library for iOS."
  s.homepage        = "https://segment.io/libraries/ios"
  s.license         = { :type => "MIT", :file => "License.md" }
  s.author          = { "Segment.io" => "friends@segment.io" }
  s.platform        = :ios, '6.0'
  s.source          = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => "#{s.version}" }
  s.requires_arc    = true

  # Use pre-compiled framework by default
  # s.default_subspec = 'Default'

  # TODO: Think about how to use pre-compiled framework by default without having to commit
  # the binary to git (which dramatically increases the repo size)
  # Perhaps use the cocoapods pre_install hook to download from s3
  # Or at least only commit the zipped version

  # s.subspec 'Default' do |ss|
  #   ss.source         = { :http => "https://s3.amazonaws.com/segmentio/releases/ios/Analytics-#{s.version}.zip", 
  #                       :flatten => true }
  #   ss.preserve_paths = 'Analytics.framework'
  #   ss.source_files   = 'Analytics.framework/**/*.h'
  #   ss.frameworks     = 'Analytics', 'Foundation', 'UIKit', 'CoreData', 'SystemConfiguration', 
  #                     'QuartzCore', 'CFNetwork', 'AdSupport', 'CoreTelephony', 'Security', 'CoreGraphics'
  #   ss.libraries      = 'sqlite3', 'z'
  #   ss.xcconfig       = { 'OTHER_LDFLAGS' => '-ObjC', 'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/Analytics"' }
  # end

  s.subspec 'Core' do |ss|
    ss.source_files   = 'Analytics/*.{h,m}', 'Analytics/Providers/Segmentio/*.{h,m}'
  end

  s.subspec 'Amplitude' do |ss|
    ss.source_files   = "Analytics/Providers/Amplitude/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'Amplitude-iOS', '~> 1.0.2'
  end

  s.subspec 'Bugsnag' do |ss|
    ss.source_files   = "Analytics/Providers/Bugsnag/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'Bugsnag', '~> 3.1.0'
  end

  s.subspec 'Countly' do |ss|
    ss.source_files   = "Analytics/Providers/Countly/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'Countly', '~> 1.0.0'
  end

  s.subspec 'Crittercism' do |ss|
    ss.source_files   = "Analytics/Providers/Crittercism/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'CrittercismSDK', '~> 4.3.1'
  end

  s.subspec 'Flurry' do |ss|
    ss.source_files   = "Analytics/Providers/Flurry/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'FlurrySDK', '~> 4.3.2'
  end

  s.subspec 'GoogleAnalytics' do |ss|
    ss.source_files   = "Analytics/Providers/GoogleAnalytics/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'GoogleAnalytics-iOS-SDK', '3.0.3a'
  end

  # Localytics-iOS-Client spec seems to be completely broken
  # s.subspec 'Localytics' do |ss|
  #   ss.source_files   = "Analytics/Providers/Localytics/*.{h,m}"
  #   ss.dependency 'Analytics/Core'
  #   ss.dependency 'Localytics-iOS-Client', '~> 2.21.1'
  # end

  s.subspec 'Mixpanel' do |ss|
    ss.source_files   = "Analytics/Providers/Mixpanel/*.{h,m}"
    ss.dependency 'Analytics/Core'
    ss.dependency 'Mixpanel', '~> 2.3.1'
  end

  s.subspec 'Tapstream' do |ss|
    ss.source_files   = 'Analytics/Providers/TapstreamProvider.{h,m}'
    ss.dependency 'Analytics/Core'
    ss.dependency 'Tapstream', '~> 2.6'
  end

end
