def shared_testing_pods
    pod 'Quick', '~> 1.2.0'
    pod 'Nimble', '~> 7.3.4'
    pod 'Nocilla', '~> 0.11.0'
    pod 'Alamofire', '~> 4.5'
    pod 'Alamofire-Synchronous', '~> 4.0'
    # TODO: Change to git url when updated. :git => 'https://github.com/segmentio/SwiftTryCatch.git'
    pod 'SwiftTryCatch', :path => '../SwiftTryCatch'
end

target 'AnalyticsTests' do
    platform :ios, '11'
    use_frameworks!
    shared_testing_pods
end

target 'AnalyticsTestsTVOS' do
  platform :tvos
  use_frameworks!
  shared_testing_pods
end
