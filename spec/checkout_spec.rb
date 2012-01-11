require 'spec/helpers'

describe 'checkout' do
  include_context 'project_helpers'

  describe "default behaviour - no args except repository url" do

    before do
      project = init_project('project', {})
      in_project_dir do
        run_msp_release 'new'
        run_msp_release 'push'
      end
    end

    it 'lets you checkout the latest release from master when invoking with only the repository as a single argument' do

      in_tmp_dir do
        run_msp_release "checkout #{@remote_repo}"

        puts last_stdout
        puts last_stderr

        last_status.exitstatus.should == 0
        last_stdout.should match('^Checking out lastest release commit from #{remote_repo}...')

        File.directory?('project-0.0.1-rc1').should be_true
        Dir.chdir 'project-0.0.1-rc1' do
          run_msp_release 'status'
          last_stdout.should match('^Release commit: 0.0.1-rc1')
        end
      end
    end

    it 'fails if there is no release commit on master' do

      in_tmp_dir do
        run_msp_release "checkout #{@remote_repo}"
        last_status.exitstatus.should == 1
        last_stderr.should match("^Could not find a release commit on master")
      end
    end
  end
end
