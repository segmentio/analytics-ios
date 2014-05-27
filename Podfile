inhibit_all_warnings!

def import_integrations
  pod 'Amplitude-iOS', '~> 2.0.0'
  pod 'Bugsnag', '3.1.0.fork'
  pod 'Countly', '~> 1.0.0'
  pod 'CrittercismSDK', '~> 4.3.3'
  pod 'FlurrySDK', '~> 4.4.0'
  pod 'GoogleAnalytics-iOS-SDK', '3.0.6'
  pod 'Localytics', '2.21.0.fork'
  pod 'Mixpanel', '2.3.4'
  pod 'Tapstream', '~> 2.6'
  pod 'Quantcast-Measure', '1.4.4'
end

def import_utilities
  pod 'Reachability', '3.1.1'
end

def import_pods
  import_integrations
  import_utilities
end

target 'Analytics', :exclusive => true do
  import_pods
end

target 'AnalyticsTests', :exclusive => true do
  pod 'Kiwi', '~> 2.2.3'
end

