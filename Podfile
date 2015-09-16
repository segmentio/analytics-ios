require File.expand_path("../scripts/build.rb", __FILE__)

platform :ios, '7.0'

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
  pod 'OCMock', '~> 3.1.2'
  pod 'OCMockito', '~> 1.4.0'
  pod 'Expecta', '~> 1.0.0'
end

post_install do |installer|
  if Gem::Version.new(Gem.loaded_specs['cocoapods'].version) >= Gem::Version.new('0.38.0')
    install_38 installer
  else
    install_37 installer
  end
end

def install_38 installer
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
      config.build_settings['VALID_ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
    end
  end

  default_library = installer.aggregate_targets.detect { |i| i.target_definition.name == 'Analytics' }

  puts default_library

  [default_library.xcconfig_relative_path('Debug'), default_library.xcconfig_relative_path('Release')].each do |path|
    path = File.expand_path(File.join(File.dirname(__FILE__), path))

    File.open("config.tmp", "w") do |io|
      f = File.read(path)
      ["icucore", "z", "sqlite3", "c++"].each do |lib|
        f.gsub!(/-l"#{lib}"/, '')
      end
      io << f
    end

    FileUtils.mv("config.tmp", path)
  end

end

def install_37 installer
  installer.project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
      config.build_settings['VALID_ARCHS'] = "i386 armv7 armv7s x86_64 arm64"
    end
  end

  default_library = installer.libraries.detect { |i| i.target_definition.name == 'Analytics' }

  [default_library.library.xcconfig_path('Debug'), default_library.library.xcconfig_path('Release')].each do |path|
    puts path
    File.open("config.tmp", "w") do |io|
      f = File.read(path)
      ["icucore", "z", "sqlite3", "c++"].each do |lib|
        f.gsub!(/-l"#{lib}"/, '')
      end
      io << f
    end

    FileUtils.mv("config.tmp", path)
  end
end
