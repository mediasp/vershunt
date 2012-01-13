require 'spec/helpers'

describe 'MSPRelease::Project' do
  include_context 'project_helpers'

  describe 'reading the project file' do

    it 'can return the source package name of the project' do
      project = write_project('dev_project', {
        :changelog_path => 'debian/changelog',
        :ruby_version_file => 'lib/my_project/version.rb'
      })

      project.source_package_name.should == 'dev_project'
    end

  end
end
