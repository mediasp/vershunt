require 'spec/helpers'

describe 'MSPRelease::Project' do
  include_context 'project_helpers'

  before do
    init_project('dev_project', {})
  end

  let :project do
    MSPRelease::Project.new('.msp_project')
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

  it 'can return the version of the project according to the ruby VERSION constant' do
    in_project_dir do
      project.version.should == MSPRelease::Version.new("0", "0", "1")
    end
  end
end
