require 'lib/msp_release/version'

spec = Gem::Specification.new do |s|
  s.name = 'vershunt'
  s.version = MSPRelease::VERSION
  s.authors = ["nick@playlouder.com"]
  s.email = ["nick@playlouder.com"]
  s.summary = 'Repeatable build system tool'
  s.description = 'Maintain versioning information in a consistent way, then build debian packages consistently.'
  s.executables = ['vershunt']
  s.files = ["bin/vershunt"] + Dir["lib/**/*.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = '1.3.5'

  s.add_dependency('POpen4', '~> 0.1.0')
  s.add_dependency('climate', '~> 0.5.0')

  s.add_development_dependency('rspec', '~> 2.8.0')
  s.add_development_dependency('rake')
end


