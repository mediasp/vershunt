require 'spec/helpers'

describe 'creating and pushing releases' do
  include_context 'project_helpers'

  describe 'new' do

    let :project do
      init_project('project', :status => :Dev, :version => '0.0.1')
    end

    before do
      @bin_path = File.expand_path('bin')
    end

    def run_msp_release(*args)
      run File.join(@bin_path, 'msp_release') + " #{args.join(' ')}"
    end

    it 'lets you create a new release commit' do
      project
      project.dev?.should be_true

      in_project_dir 'project' do |dir|
        run_msp_release 'new'
        assert_exit_status
        # fixme is there a way to get a timestamp match here?
        last_stdout.should include("Changelog now at 0.0.1-")
      end
    end

    it 'will not let you create a release commit if you have an operation pending' do
      project

      in_project_dir 'project' do |dir|
        run_msp_release 'new'
        assert_exit_status

        run_msp_release 'new'
        assert_exit_status 1
        last_stderr.should include('You have a release commit pending to be pushed')
      end
    end

    it 'will let you push a release commit' do
      project

      in_project_dir 'project' do |dir|
        run_msp_release 'new'
        assert_exit_status

        assert_push
      end

      in_remote_dir do
        run 'git tag'
        last_stdout.split('\n').grep(@pushed_tag).first.should_not be_nil
      end
    end

    it 'will let you push a release commit from a release branch' do
      project

      in_project_dir 'project' do |dir|
        run_msp_release 'branch'
        assert_exit_status

        run_msp_release 'new'
        assert_exit_status

        assert_push
      end

      in_remote_dir do
        run 'git tag'
        last_stdout.split('\n').grep(@pushed_tag).first.should_not be_nil
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
end
