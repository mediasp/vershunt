#!/usr/bin/env ruby
#
# Creates a very basic directory containing the union of all the lib dirs
# in the given gems dir
#

require 'fileutils'

gems_dir=ARGV[0]
output=ARGV[1]

puts "Flattening gems from #{gems_dir}"
gems = Dir[gems_dir + '/*']
puts "Gems: #{gems.inspect}"
gems.each do |gem_dir|
  FileUtils.cp_r("#{gem_dir}/lib/.", output)
end


