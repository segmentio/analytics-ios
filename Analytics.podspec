# using full path for when cocoapdos is building a local pod they don't alias
# the dir, they copy but only the podspec and code files.
begin
  require File.expand_path('./scripts/build.rb')
rescue LoadError
  require File.expand_path('~/dev/segmentio/analytics-ios/scripts/build.rb')
end

Pod::Spec.new do |s|
  s.name            = "Analytics"
  s.version         = "1.5.9"
  s.summary         = "Segment.io analytics and marketing tools library for iOS."
  s.homepage        = "https://segment.io/libraries/ios"
  s.license         = { :type => "MIT", :file => "License.md" }
  s.author          = { "Segment.io" => "friends@segment.io" }

  s.source          = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.requires_arc    = true

  s.subspec 'Core-iOS' do |ss|
    ss.public_header_files = 'Analytics/*'
    ss.source_files = ['Analytics/*.{h,m}', 'Analytics/Helpers/*.{h,m}', 'Analytics/Integrations/SEGAnalyticsIntegrations.h']
    ss.platforms = [:ios]
    ss.dependency "Analytics/Segmentio"
    ss.weak_frameworks = ['iAd', 'AdSupport', 'CoreBlueTooth']
    ss.dependency 'TRVSDictionaryWithCaseInsensitivity', '0.0.2'
    s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => "ANALYTICS_VERSION=#{s.version}" }
  end

  Build.subspecs.each do |a|
    s.subspec a.name do |ss|
      ss.prefix_header_contents = "#define USE_ANALYTICS_#{a.name.upcase} 1"
      ss.public_header_files = 'Analytics/Integrations/*'
      ss.ios.source_files = "Analytics/Integrations/#{a.name}/SEG#{a.name}Integration.{h,m}"
      ss.platforms = [:ios]
      ss.dependency 'Analytics/Core-iOS'

      (a.dependencies || []).each do |d|
        if d.version
          ss.dependency d.name, d.version
        else
          ss.dependency d.name
        end
      end
    end
  end
end
