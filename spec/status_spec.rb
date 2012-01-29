require 'spec/helpers'

describe 'msp_release status' do
  include_context 'project_helpers'

  before do
    init_project 'project', {:version => '0.0.1'}
  end

  it 'does not show any release commit information if you are not on a release commit' do
    in_project_dir 'project' do
      run_msp_release 'status'
      last_stdout.should include('Release commit: <none>')
      last_stdout.should match(/Changelog says +: +0\.0\.1$/)
    end
  end

  it 'shows release commit information if you are on a release commit' do
    in_project_dir 'project' do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'status'
      last_stdout.should include('Release commit: 0.0.1-1')
      last_stdout.should match(/Changelog says +: +0\.0\.1-1$/)
    end
  end

end
