require 'rubygems'
require 'rake'

require 'rake/gempackagetask'
package_task = Rake::GemPackageTask.new(spec) {|task| }

desc 'build a gem release and push it to dev'
task :release => :package do
  sh "scp pkg/msp_release-#{MSPRelease::VERSION}.gem dev.playlouder.com:/var/www/gems.playlouder.com/pending"
  sh "ssh dev.playlouder.com sudo include_gems.sh /var/www/gems.playlouder.com/pending"
end
