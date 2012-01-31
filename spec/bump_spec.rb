require 'spec/helpers'

describe 'bump' do
  include_context 'project_helpers'

  describe 'on a ruby project' do

    before do
      init_project('project', {})
    end

    def project_version_should_match(string)
      run_msp_release 'status'
      last_stdout.should match(/Project says +: +#{Regexp.escape(string)}/)
    end

    it 'can bump the bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')

        run_msp_release 'bump bugfix'
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.0.2")

        project_version_should_match('0.0.2')
      end
    end

    it 'can bump the minor version, resetting the bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')

        run_msp_release 'bump minor'
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.1.0")

        project_version_should_match('0.1.0')
      end
    end

    it 'can bump the major version, resetting the minor and bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')


        run_msp_release 'bump minor'
        project_version_should_match('0.1.0')

        run_msp_release 'bump major'
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 1.0.0")

        project_version_should_match('1.0.0')
      end
    end
  end
end
