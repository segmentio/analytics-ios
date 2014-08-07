require './scripts/build'

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
