def shared_testing_pods
    pod 'Nocilla', '~> 0.11.0'
end

target 'SegmentTests' do
    platform :ios, '11'
    use_frameworks!
    shared_testing_pods
end

target 'SegmentTestsTVOS' do
  platform :tvos
  use_frameworks!
  shared_testing_pods
end
