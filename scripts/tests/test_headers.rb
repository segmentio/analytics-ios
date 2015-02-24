#!/usr/bin/env ruby

require_relative '../build'

def current_path
  File.dirname(__FILE__)
end

def root_path
  File.join(current_path, '..', '..')
end

Dir.chdir(root_path)

class Pod
  attr_accessor :name, :filename

  def initialize path
    @name = path.split('/')[1]
    @filename = path.split('/').last
  end

  def to_s
    "#{name}: #{filename}"
  end
end

def headers
  @headers ||= begin
                 Dir.glob('**/*.h').map do |p|
                   Pod.new p
                 end.select do |p|
                   Build.all_pods.map { |p| p.name }.include? p.name
                 end
               end
end

xcodeproj = File.open(File.join(root_path, "Analytics.xcodeproj", "project.pbxproj")).read


contained = headers.select do |p|
  xcodeproj =~ /#{Regexp.escape(p.filename)}.*Public/
end

missing_headers = headers - contained

if missing_headers.length > 0
  puts "=============================================================================================================="
  puts "=============================================================================================================="
  puts "=============================================================================================================="
  puts "Test failed that checks that all integration headers are being made public, these headers need to made public:"
  puts "=============================================================================================================="
  puts "=============================================================================================================="
  puts "=============================================================================================================="
  puts missing_headers
  exit 1
end
