require 'rubygems'
require 'rake'

spec = Gem::Specification.new do |s|
  s.name = 'msp_release'
  s.version = '0.1.0'
  s.authors = ["nick@playlouder.com"]
  s.email = ["nick@playlouder.com"]
  s.summary = 'MSP release process utility'
  s.description = 'Utility for manipulating scm to create a consistent tagging/branching scheme that matches our release process'
  s.executables = ['msp_release']
  s.files = ["bin/msp_release"] + Dir["lib/**/*.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = '1.3.5'
end

require 'rake/gempackagetask'
package_task = Rake::GemPackageTask.new(spec) {|task| }
