require 'lib/msp_release/version'

spec = Gem::Specification.new do |s|
  s.name = 'msp_release'
  s.version = MSPRelease::VERSION
  s.authors = ["nick@playlouder.com"]
  s.email = ["nick@playlouder.com"]
  s.summary = 'MSP release process utility'
  s.description = 'Utility for manipulating scm to create a consistent tagging/branching scheme that matches our release process'
  s.executables = ['msp_release']
  s.files = ["bin/msp_release"] + Dir["lib/**/*.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = '1.3.5'

  s.add_development_dependency('rspec', '~> 2.6.0')
  s.add_development_dependency('aruba')
end


