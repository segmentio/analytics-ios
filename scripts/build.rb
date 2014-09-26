require 'json'

module Build
  class << self
    class Pod
      attr_accessor :name, :version

      class << self
        def pod_from_hash h
          p = Pod.new
          p.name = h["name"]
          p.version = h["version"]
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
          s.name = h["name"]
          s.dependencies = h["dependencies"].map { |d| Pod.pod_from_hash(d) }
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
      @pods ||= JSON.parse(File.read(File.join(File.dirname(__FILE__), 'integrations.json')))["integrations"].map { |p| Subspec.spec_from_hash(p) }
    end
  end
end
