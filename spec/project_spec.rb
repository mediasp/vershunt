require 'spec/helpers'

describe 'MSPRelease::Project' do
  include_context 'project_helpers'

  describe 'debian project', self do
    before do
      init_debian_project('dev_project', {})
    end

    let :project do
      MSPRelease::Project.new_from_project_file('.msp_project')
    end

    it 'can return the source package name' do
      in_project_dir do
        project.source_package_name.should == 'dev_project'
      end
    end

    it 'can return a changelog object' do
      in_project_dir do
        project.changelog.should_not be_nil
      end
    end

    it 'can return the version of the project according to the changelog' do
      in_project_dir do
        project.version.should == MSPRelease::Version.new("0", "0", "1")
      end
    end

  end

  describe 'gem project', self do
    before do
      init_gem_project('gem_project', {})
    end

    let :project do
      MSPRelease::Project.new_from_project_file('.msp_project')
    end

    it 'can return the version of the project according to the ruby VERSION constant' do
      in_project_dir do
        project.version.should == MSPRelease::Version.new("0", "0", "1")
      end
    end

    it 'can return the gemspec file name' do
      in_project_dir do
        project.gemspec_file.should match /gem_project.gemspec$/
      end
    end

    it 'can return the name of the gem' do
      in_project_dir do
        project.gemspec_name.should == 'gem_project'
      end
    end

  end
end
