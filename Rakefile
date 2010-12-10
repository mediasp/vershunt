require 'rubygems'
require 'rake'

version = '0.3.3'

spec = Gem::Specification.new do |s|
  s.name = 'msp_release'
  s.version = version
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

desc 'build a gem release and push it to dev'
task :release => :package do
  sh "scp pkg/msp_release-#{version}.gem dev.playlouder.com:/var/www/gems.playlouder.com/pending"
  sh "ssh dev.playlouder.com sudo include_gems.sh /var/www/gems.playlouder.com/pending"
end
