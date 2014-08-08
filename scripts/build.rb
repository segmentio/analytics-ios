module Build
  class << self
    class Pod
      attr_accessor :name, :version

      class << self
        def pod_from_hash h
          p = Pod.new
          p.name = h[:name]
          p.version = h[:version]
          p
        end
      end

      def to_s
        "#{name}: #{version}"
      end
    end

    class Subspec
      attr_accessor :name, :dependencies

      class << self
        def spec_from_hash h
          s = Subspec.new
          s.name = h[:name]
          s.dependencies = h[:dependencies].map { |d| Pod.pod_from_hash d }
          s
        end
      end

      def to_s
        "#{name}: #{dependencies.map { |d| d.to_s }}"
      end
    end

    def all_pods
      subspecs.map { |p| p.dependencies }.flatten
    end

    def subspecs
      @pods ||= begin
                  amplitude = { :name => 'Amplitude', :dependencies => [{ :name => 'Amplitude-iOS', :version => '~> 2.1.0' }]}
                  bugsnag = { :name => 'Bugsnag', :dependencies => [{ :name => 'Bugsnag', :version => '~> 3.1.2' }]}
                  countly = { :name => 'Countly', :dependencies => [{ :name => 'Countly', :version => '~> 1.0.0' }]}
                  crittercism = { :name => 'Crittercism', :dependencies => [{ :name => 'CrittercismSDK', :version => '~> 4.3.3' }]}
                  flurry = { :name => 'Flurry', :dependencies => [{ :name => 'FlurrySDK', :version => '~> 4.4.0' }]}
                  google = { :name => 'GoogleAnalytics', :dependencies => [{ :name => 'GoogleAnalytics-iOS-SDK', :version => '~> 3.0.7' }]}
                  localytics = { :name => 'Localytics', :dependencies => [{ :name => 'Localytics-iOS-Client', :version => '~> 2.23.0' }]}
                  mixpanel = { :name => 'Mixpanel', :dependencies => [{ :name => 'Mixpanel', :version => '~> 2.3.6' }]}
                  optimizely = { :name => 'Optimizely', :dependencies => [{ :name => 'Optimizely-iOS-SDK', :version => '~> 0.6.52' }]}
                  quantcast = { :name => 'Quantcast', :dependencies => [{ :name => 'Quantcast-Measure', :version => '~> 1.4.4' }]}
                  segmentio = { :name => 'Segmentio', :dependencies => [{ :name => 'Reachability', :version => '3.1.1' }]}
                  taplytics = { :name => 'Taplytics', :dependencies => [{ :name => 'Taplytics', :version => '~> 1.3.0' }]}
                  tapstream = { :name => 'Tapstream', :dependencies => [{ :name => 'Tapstream', :version => '~> 2.7' }]}

                  pods = [segmentio, amplitude, bugsnag, countly, crittercism, flurry, google, localytics, mixpanel, optimizely, taplytics, tapstream, quantcast]

                  pods.map { |p| Subspec.spec_from_hash p }
                end

    end

  end
end
