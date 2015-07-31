begin
  require File.expand_path('./scripts/build.rb')
rescue LoadError
  require File.expand_path('~/dev/segmentio/analytics-ios/scripts/build.rb')
end

Pod::Spec.new do |s|
  s.name            = "Analytics"
  s.version         = "1.12.3"
  s.summary         = "Segment analytics and marketing tools library for iOS."
  s.homepage        = "https://segment.com/libraries/ios"
  s.license         = { :type => "MIT", :file => "License.md" }
  s.author          = { "Segment" => "friends@segment.io" }

  s.source          = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.requires_arc    = true

  s.subspec 'Core-iOS' do |ss|
    ss.public_header_files = ['Analytics/*.h', 'Analytics/Helpers/*.h', 'Analytics/Integrations/SEGAnalyticsIntegrations.h']
    ss.source_files = ['Analytics/*.{h,m}', 'Analytics/Helpers/*.{h,m}', 'Analytics/Integrations/SEGAnalyticsIntegrations.h']
    ss.platform = :ios, '6.0'
    ss.weak_frameworks = ['CoreBluetooth', 'SystemConfiguration', 'CoreLocation']
    ss.dependency 'TRVSDictionaryWithCaseInsensitivity', '0.0.2'
    s.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => "ANALYTICS_VERSION=#{s.version}" }
  end

  Build.subspecs.each do |a|
    s.subspec a.name do |ss|
      ss.prefix_header_contents = "#define USE_ANALYTICS_#{a.name.upcase} 1"
      ss.public_header_files = ['Analytics/Integrations/*.h', "Analytics/Integrations/#{a.name}/SEG#{a.name}Integration.h"]
      ss.ios.source_files = "Analytics/Integrations/#{a.name}/SEG#{a.name}Integration.{h,m}"
      ss.platform = :ios, '6.0'

      ss.dependency 'Analytics/Core-iOS'
      ss.dependency 'Analytics/Segmentio' unless a.is_segment?

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
