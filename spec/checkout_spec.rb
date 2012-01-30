require 'spec/helpers'

describe 'checkout' do
  include_context 'project_helpers'

  describe "default behaviour - no args except repository url" do

    before do
      project = init_project('project', {})
    end

    it 'lets you checkout the latest release from master when invoking with only the repository as a single argument' do

      in_tmp_dir do
        run_msp_release "checkout #{@remote_repo}"

        last_run.should exit_with(0)
        last_stdout.should match("Checking out latest commit from master")
        version_regex = /Checked out to project\-([0-9]{14}-git\+[a-f0-9]{6}~master)/
        last_stdout.should match(version_regex)

        package_version = version_regex.match(last_stdout)[1]
        full_package_name = 'project-' + package_version

        File.directory?(full_package_name).should be_true
        Dir.chdir full_package_name do
          run_msp_release 'status'
          last_run.should exit_with(0)
          last_stdout.should include("Changelog says : #{package_version}")
        end
      end
    end
  end

  describe "checking out latest from a branch" do

    before do
      project = init_project('project', {})

      in_project_dir do
        run_msp_release 'branch'
        run_msp_release 'new'
        run_msp_release 'push'
      end
    end

    it 'will checkout the lastest release on a branch if you pass BRANCH_NAME as an argument' do

      in_tmp_dir do
        run_msp_release "checkout #{@remote_repo} release-0.0.1"

        last_run.should exit_with(0)
        last_stdout.should match("Checking out latest release commit from origin/release-0.0.1")
        last_stdout.should match("Checked out to project-0.0.1-1")

        File.directory?('project-0.0.1-1').should be_true
        Dir.chdir 'project-0.0.1-1' do
          run_msp_release 'status'
          last_stdout.should match('^Release commit: 0.0.1-1')
          last_stdout.should match('^On release branch : 0.0.1')
        end
      end
    end

    it 'will fail if you give it a branch that does not exist' do
      in_tmp_dir do
        run_msp_release "checkout #{@remote_repo} release-0.1.0"

        last_run.should exit_with(1)
        last_stderr.should match("Git pathspec 'origin/release-0.1.0' does not exist")
      end
    end

  end
end
