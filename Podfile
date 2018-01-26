platform :ios, '11'
use_frameworks!

target 'Analytics' do
    pod 'GZIP', '~> 1.2'

    target 'AnalyticsTests' do
        inherit! :search_paths

        pod 'Quick', '~> 1.2.0' # runner lib
        pod 'Nimble', '~> 7.0.3'  # Matcher lib
        pod 'Nocilla', '~> 0.11.0' # HTTP Mocking Library
        pod 'SwiftTryCatch',  :git => 'https://github.com/segmentio/SwiftTryCatch.git' # Utils lib

    end
end
