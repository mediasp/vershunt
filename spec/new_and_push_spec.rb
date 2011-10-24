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
      project.dev?.should be_true

      in_project_dir 'project' do |dir|
        run_msp_release 'new'
        assert_exit_status

        run_msp_release 'new'
        assert_exit_status 1
        last_stderr.should include('You have a release commit pending to be pushed')
      end
    end

  end
end
