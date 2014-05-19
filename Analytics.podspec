Pod::Spec.new do |s|
  s.name            = "Analytics"
  s.version         = "1.0.0"
  s.summary         = "Segment.io analytics and marketing tools library for iOS."
  s.homepage        = "https://segment.io/libraries/ios"
  s.license         = { :type => "MIT", :file => "License.md" }
  s.author          = { "Segment.io" => "friends@segment.io" }

  s.source          = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.requires_arc    = true

  s.subspec 'Core-iOS' do |ss|
    ss.public_header_files = 'Analytics/*'
    ss.source_files = ['Analytics/*.{h,m}', 'Analytics/Helpers/*.{h,m}', 'Analytics/Integrations/AnalyticsIntegrations.h']
    ss.platforms = [:ios]
  end

  amplitude = { :name => 'Amplitude', :dependencies => [{ :pod => 'Amplitude-iOS' }]}
  bugsnag = { :name => 'Bugsnag', :dependencies => [{ :pod => 'Bugsnag' }]}
  countly = { :name => 'Countly', :dependencies => [{ :pod => 'Countly' }]}
  crittercism = { :name => 'Crittercism', :dependencies => [{ :pod => 'CrittercismSDK' }]}
  flurry = { :name => 'Flurry', :dependencies => [{ :pod => 'FlurrySDK' }]}
  google = { :name => 'GoogleAnalytics', :dependencies => [{ :pod => 'GoogleAnalytics-iOS-SDK' }]}
  localytics = { :name => 'Localytics', :dependencies => [{ :pod => 'Localytics', :version => '2.21.0.fork' }]}
  mixpanel = { :name => 'Mixpanel', :dependencies => [{ :pod => 'Mixpanel' }]}
  tapstream = { :name => 'Tapstream', :dependencies => [{ :pod => 'Tapstream' }]}
  quantcast = { :name => 'Quantcast', :dependencies => [{ :pod => 'Quantcast-Measure' }]}
  segmentio = { :name => 'Segmentio', :dependencies => [{ :pod => 'Reachability', :version => '3.1.1' }]}

  analytics = [segmentio, amplitude, bugsnag, countly, crittercism, flurry, google, localytics, mixpanel, tapstream, quantcast]

  analytics.each do |a|
    s.subspec a[:name] do |ss|
      ss.prefix_header_contents = "#define USE_ANALYTICS_#{a[:name].upcase} 1"
      ss.public_header_files = 'Analytics/Integrations/*'
      ss.ios.source_files = "Analytics/Integrations/#{a[:name]}/SEG#{a[:name]}Integration.{h,m}"
      ss.platforms = [:ios]
      ss.dependency 'Analytics/Core-iOS'

      (a[:dependencies] || []).each do |d|
        if d[:version]
          ss.dependency d[:pod], d[:version]
        else
          ss.dependency d[:pod]
        end
      end
    end
  end
end
