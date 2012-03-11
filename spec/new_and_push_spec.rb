require 'spec/helpers'

describe 'creating and pushing releases' do
  include_context 'project_helpers'

  describe 'new' do

    before do
      @project = init_project('project', :version => '0.0.1')
    end

    it 'fails if you are not on a release branch' do
      in_project_dir do |dir|
        run_msp_release 'new'
        last_run.should exit_with(1)
        last_stderr.should include('You must be on a release branch to create release commits')
      end
    end

    it 'creates a -1 release on a release branch' do
      in_project_dir do |dir|
        run_msp_release 'branch'
        last_run.should exit_with(0)

        run_msp_release 'new'

        last_run.should exit_with(0)
        last_stdout.should include("Changelog now at 0.0.1-1\n")
      end
    end

    it 'will not let you create a release commit if you have an operation pending' do
      in_project_dir 'project' do |dir|
        run_msp_release 'branch'
        run_msp_release 'new'
        last_run.should exit_with(0)
        assert_exit_status

        run_msp_release 'new'
        last_run.should exit_with(1)
        last_stderr.should include('You have a release commit pending to be pushed')
      end
    end

    it 'can create a subsequent -2 release on a release branch' do
      in_project_dir do
        run_msp_release 'branch'
        run_msp_release 'new'

        last_stdout.should include('Changelog now at 0.0.1-1')

        run_msp_release 'push'
        last_run.should exit_with(0)

        run_msp_release 'new'
        last_run.should exit_with(0)
        last_stdout.should include('Changelog now at 0.0.1-2')
      end
    end
  end

  describe "new releases with ruby != debian version" do
    it "uses the existing debian version where the main parts match" do

      @project = init_project('project', :version => '0.1.0',
        :changelog_version => '0.1.0-3')

      in_project_dir do
        run_msp_release 'branch'
        run_msp_release 'new'

        last_stdout.should include('Changelog now at 0.1.0-4')
      end
    end

    it "uses the existing debian version where the main parts match, but " +
      "the debian suffix is rubbish" do

      @project = init_project('project', :version => '0.1.0',
        :changelog_version => '0.1.0~upstreamcats')

      in_project_dir do
        run_msp_release 'branch'
        run_msp_release 'new'

        last_stdout.should include('Changelog now at 0.1.0-1')
        last_stderr.should include('Warning: project version (0.1.0) did not match changelog version (0.1.0~upstreamcats), project version wins')
      end
    end

    it "uses the ruby version over the debian version where they are different" do
      @project = init_project('project', :version => '0.1.0',
        :changelog_version => '0.2.0-20120101')

      in_project_dir do
        run_msp_release 'branch'
        run_msp_release 'new'

        last_stdout.should include('Changelog now at 0.1.0-1')
        last_stderr.should include('Warning: project version (0.1.0) did not match changelog version (0.2.0-20120101), project version wins')
      end

    end
  end

  def assert_push
    run_msp_release 'push'
    assert_exit_status
    tagline = last_stdout.split("\n").grep(/Pushing new release tag: /).first
    tagline.should_not be_nil
    @pushed_tag = /new release tag: (.+)$/.match(tagline)[1]
  end

end
