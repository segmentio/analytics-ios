begin
  require File.expand_path('./scripts/build.rb')
rescue LoadError
  require File.expand_path('~/dev/segmentio/analytics-ios/scripts/build.rb')
end

inhibit_all_warnings!

def import_utilities
  pod 'TRVSDictionaryWithCaseInsensitivity', '0.0.2'
end

def import_pods
  Build.all_pods.each do |p|
    send :pod, p.name, p.version
  end
  import_utilities
end

target 'Analytics', :exclusive => true do
  import_pods
end

target 'iOS Tests', :exclusive => true do
  import_pods
  pod 'TRVSKit/TRVSAssertions', '~> 0.0.8'
  pod 'OCMock', '~> 2.2.4'
  pod 'Expecta', '~> 0.3.0'
end

post_install do |installer|
    installer.project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
            config.build_settings['VALID_ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
        end
    end

    default_library = installer.libraries.detect { |i| i.target_definition.name == 'Analytics' }

    config_file_path = default_library.library.xcconfig_path('Release')

    File.open("config.tmp", "w") do |io|
      f = File.read(config_file_path)
      ["icucore", "z", "sqlite3"].each do |lib|
        f.gsub!(/-l"#{lib}"/, '')
      end
      io << f
    end

    FileUtils.mv("config.tmp", config_file_path)
end
