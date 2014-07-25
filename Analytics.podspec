Pod::Spec.new do |s|
  s.name            = "Analytics"
  s.version         = "1.5.2"
  s.summary         = "Segment.io analytics and marketing tools library for iOS."
  s.homepage        = "https://segment.io/libraries/ios"
  s.license         = { :type => "MIT", :file => "License.md" }
  s.author          = { "Segment.io" => "friends@segment.io" }

  s.source          = { :git => "https://github.com/segmentio/analytics-ios.git", :tag => s.version.to_s }
  s.ios.deployment_target = '6.0'
  s.requires_arc    = true

  amplitude = { :name => 'Amplitude', :dependencies => [{ :pod => 'Amplitude-iOS', :version => '~> 2.1.0' }]}
  bugsnag = { :name => 'Bugsnag', :dependencies => [{ :pod => 'Bugsnag', :version => '~> 3.1.2' }]}
  countly = { :name => 'Countly', :dependencies => [{ :pod => 'Countly', :version => '~> 2.0.0' }]}
  crittercism = { :name => 'Crittercism', :dependencies => [{ :pod => 'CrittercismSDK', :version => '~> 4.3.3' }]}
  flurry = { :name => 'Flurry', :dependencies => [{ :pod => 'FlurrySDK', :version => '~> 4.4.0' }]}
  google = { :name => 'GoogleAnalytics', :dependencies => [{ :pod => 'GoogleAnalytics-iOS-SDK', :version => '3.0.7' }]}
  localytics = { :name => 'Localytics', :dependencies => [{ :pod => 'Localytics-iOS-Client', :version => '~> 2.23.0' }]}
  mixpanel = { :name => 'Mixpanel', :dependencies => [{ :pod => 'Mixpanel', :version => '~> 2.3.6' }]}
  optimizely = { :name => 'Optimizely', :dependencies => [{ :pod => 'Optimizely-iOS-SDK', :version => '~> 0.5.51' }]}
  quantcast = { :name => 'Quantcast', :dependencies => [{ :pod => 'Quantcast-Measure', :version => '~> 1.4.4' }]}
  segmentio = { :name => 'Segmentio', :dependencies => [{ :pod => 'Reachability', :version => '3.1.1' }]}
  taplytics = { :name => 'Taplytics', :dependencies => [{ :pod => 'Taplytics', :version => '~> 1.3.0' }]}
  tapstream = { :name => 'Tapstream', :dependencies => [{ :pod => 'Tapstream', :version => '~> 2.7' }]}

  analytics = [segmentio, amplitude, bugsnag, countly, crittercism, flurry, google, localytics, mixpanel, optimizely, taplytics, tapstream, quantcast]

  s.subspec 'Core-iOS' do |ss|
    ss.public_header_files = 'Analytics/*'
    ss.source_files = ['Analytics/*.{h,m}', 'Analytics/Helpers/*.{h,m}', 'Analytics/Integrations/SEGAnalyticsIntegrations.h']
    ss.platforms = [:ios]
    ss.dependency "Analytics/#{segmentio[:name]}"
    ss.dependency 'TRVSDictionaryWithCaseInsensitivity', '0.0.2'
  end

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
