require 'spec/helpers'


describe 'bump' do

  shared_examples 'bump operations' do

    it 'can bump the bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')

        run_msp_release 'bump bugfix'
        last_run.should exit_with(0)
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.0.2")

        project_version_should_match('0.0.2')
      end
    end

    it 'can bump the bugfix version, creating and switching to a new release ' +
      'branch if you are already on a release branch' do
      in_project_dir do
        project_version_should_match('0.0.1')
        run_msp_release 'branch'
        last_run.should exit_with(0)
        release_branch_should_match('0.0.1')

        run_msp_release 'bump bugfix'
        last_run.should exit_with(0)
        last_stdout.should include("Making and switching to release branch: release-0.0.2\n")
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.0.2")
        project_version_should_match('0.0.2')
        release_branch_should_match('0.0.2')

        # check it does not alter the history of the previous branch
        run "git checkout release-0.0.1"
        run "git --no-pager log -1"
        last_stdout.should include("initial commit")
        project_version_should_match('0.0.1')
        release_branch_should_match('0.0.1')
      end
    end

    it 'can bump the bugfix version, staying on the existing branch if you ' +
      'pass --no-branch' do
      in_project_dir do
        project_version_should_match('0.0.1')
        run_msp_release 'branch'
        release_branch_should_match('0.0.1')

        run_msp_release 'bump bugfix --no-branch'
        last_run.should exit_with(0)
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.0.2")

        project_version_should_match('0.0.2')
        release_branch_should_match('0.0.1')
      end
    end

    it 'can bump the minor version, resetting the bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')

        run_msp_release 'bump minor'
        last_run.should exit_with(0)
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.1.0")

        project_version_should_match('0.1.0')
      end
    end

    it 'will fail to bump the minor version if you are not on master' do
      in_project_dir do
        project_version_should_match('0.0.1')
        run_msp_release 'branch'
        release_branch_should_match('0.0.1')

        run_msp_release 'bump minor'
        last_run.should exit_with(1)
        last_stderr.should include("You must be on master to bump the minor " +
          "version, or pass --force if you are sure this is what you want to do")
        project_version_should_match('0.0.1')
      end
    end

    it 'can bump the minor version if you are not on master if you pass' +
      '--force' do
      in_project_dir do
        project_version_should_match('0.0.1')
        run_msp_release 'branch'
        release_branch_should_match('0.0.1')

        run_msp_release 'bump minor --force'
        last_run.should exit_with(0)
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 0.1.0")

        project_version_should_match('0.1.0')
      end
    end

    it 'can bump the major version, resetting the minor and bugfix version' do
      in_project_dir do
        project_version_should_match('0.0.1')

        run_msp_release 'bump minor'
        last_run.should exit_with(0)
        project_version_should_match('0.1.0')

        run_msp_release 'bump major'
        last_run.should exit_with(0)
        run "git --no-pager log -1"
        last_stdout.should include("BUMPED VERSION TO 1.0.0")

        project_version_should_match('1.0.0')
      end
    end
  end

  include_context 'project_helpers'

  def release_branch_should_match(string)
    run_msp_release 'status'
    last_run.should exit_with(0)
    last_stdout.should match(/Release branch +: +#{Regexp.escape(string)}/)
  end

  describe 'on a changelog only project' do

    include_examples 'bump operations'

    def project_version_should_match(string)
      run_msp_release 'status'
      last_run.should exit_with(0)
      last_stdout.should match(/Changelog says +: +#{Regexp.escape(string)}/)
    end

    before do
      init_project('project', {:ruby_version_file => nil})
    end

  end

  describe 'on a ruby project' do

    include_examples 'bump operations'

    def project_version_should_match(string)
      run_msp_release 'status'
      last_run.should exit_with(0)
      last_stdout.should match(/Project says +: +#{Regexp.escape(string)}/)
      last_stdout.should match(/Changelog says +: +#{Regexp.escape(string)}/)
    end

    before do
      init_project('project', {})
    end

  end
end
