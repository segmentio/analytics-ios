Pod::Spec.new do |s|
  s.name             = "Segment-Adevinta"
  s.module_name      = "Segment"
  s.version          = "4.1.8"
  s.summary          = "The hassle-free way to add analytics to your iOS app."

  s.description      = <<-DESC
                       Analytics for iOS provides a single API that lets you
                       integrate with over 100s of tools.
                       DESC

  s.homepage         = "http://segment.com/"
  s.license          =  { :type => 'MIT' }
  s.author           = { "Adevinta" => "miquel.alvarado@adevinta.com" }
  s.source           = { :git => "https://github.com/AdevintaSpain/analytics-ios-adevinta", :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.13'

  s.source_files = [
    'Segment/Classes/**/*.{h,m}',
    'Segment/Internal/**/*.{h,m}'
  ]
  s.resources = ['Segment/PrivacyInfo.xcprivacy']
end
