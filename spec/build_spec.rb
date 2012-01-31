require 'spec/helpers'

describe 'build' do
  include_context 'project_helpers'

  before do
    # change this before you build_init_project
    @deb_exit_code = 0
  end

  it 'fails if no build command has been specified' do
    project = build_init_project('project', {})
    in_project_dir do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'build'
      assert_exit_status 1
      last_stderr.should include('project does not define a build_command')
    end
  end

  let :deb_options do
    {:build_command => 'bin/build-debs.sh', :output_directory => '.',
    :package_name => 'project'}
  end

  it 'fails if you are not commiting from a release commit' do
    project = build_init_project('project', :deb => deb_options)

    in_project_dir do
      run_msp_release 'build'
      assert_exit_status 1
      last_stderr.should include('HEAD is not a release commit')
    end
  end

  it 'fails if the build command fails' do
    @build_extra = "exit 1"
    project = build_init_project('project', {
      :deb => deb_options
    })

    in_project_dir do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'build'
      assert_exit_status 1
      last_stderr.should include('Command failed')
    end
  end

  it 'fails if no changes file results from the build' do
    project = build_init_project('project', {
      :deb => deb_options
    })

    in_project_dir do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'build'
      assert_exit_status 1
      last_stderr.should include('Unable to find changes file')
    end
  end

  it 'fails if the resulting changes file does not match the expected version' do

    @build_extra = "touch project_0.1.0~1_all.changes"

    project = build_init_project('project', {
      :deb => deb_options
    })

    in_project_dir do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'build'
      assert_exit_status 1
      last_stderr.should include('Unable to find changes file with version: 0.0.1-1')
    end
  end

  it 'calls the build command, scanning for resulting build product' do

    @build_extra = "touch project_0.0.1-1_all.changes"

    project = build_init_project('project', {
      :deb => deb_options
    })

    in_project_dir do
      run_msp_release 'branch'
      run_msp_release 'new'
      run_msp_release 'push'
      run_msp_release 'build'
      assert_exit_status
      last_stdout.should match(/^Package built: (.+)project_0\.0\.1\-1_all\.changes$/)
    end

  end

  def build_init_project(*args)
    init_project(*args)
    in_project_dir do |dir|
      Dir.mkdir('bin')
      build_cmd = 'bin/build-debs.sh'
      File.open(build_cmd, 'w') do |f|
        f.write <<BASH
#!/bin/bash
echo 'lolcats'
#{@build_extra}
BASH
      end
      FileUtils.chmod 0755, build_cmd
    end
  end
end
