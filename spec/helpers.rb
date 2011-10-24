require 'fileutils'
require 'tmpdir'
require 'msp_release'
require 'popen4'

shared_context "tmpdir" do
  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    @tmpdir = nil
  end
end

shared_context "project_helpers" do
  include_context "tmpdir"

  def run(cmd)
    @last_command = cmd

    @last_status = POpen4.popen4(@last_command) do |stdout, stderr, stdin, pid|
      @last_stdout = stdout.read.strip
      @last_stderr = stderr.read.strip
      @last_pid = pid
    end
  end

  def exec(cmd)
    run cmd
    if @last_status.exitstatus != 0
      raise "command: #{cmd} failed with #{@last_status.exitstatus}\n#{@all_output}"
    end
    true
  end

  def all_output
    @last_stdout + "\n" + @last_stderr
  end

  attr_reader :last_stdout, :last_stderr, :last_status

  def assert_exit_status(code=0)
    @last_status.exitstatus.should eql code
  end

  def create_project_dir(name)
    @project_dir = FileUtils.mkdir(File.join(@tmpdir, name)).first unless @project_dir
  end

  def write_project(name, yaml_string)
    create_project_dir(name)
    fname = File.join(@project_dir, '.msp_project')
    File.open(fname, 'w') {|f| f.write(yaml_string) }
    MSPRelease::Project.new(fname)
  end

  def init_project(name, options)
    changelog_path = options.fetch(:changelog_path, "debian/changelog")
    ruby_version_file = options.fetch(:ruby_version_file, "lib/#{name}/version.rb")
    status = options.fetch(:status, :Dev)
    version = options.fetch(:version, '0.0.1')

    create_project_dir(name)
    remote_repo = File.expand_path(@project_dir + "/../#{name}-remote.git")
    Dir.chdir(@project_dir + '/..') do
      exec "git init --bare #{remote_repo}"
    end

    in_project_dir(name) do
      exec "git clone #{remote_repo} ."
    end

    project = write_project name, <<YAML
---
:status: :#{status}
:changelog_path: #{changelog_path}
:ruby_version_file: #{ruby_version_file}
YAML

    FileUtils.mkdir_p(File.join(@project_dir, File.dirname(ruby_version_file)))
    File.open(File.join(@project_dir, ruby_version_file), 'w') do |f|
      f.puts('module SomeModule')
      f.puts("  VERSION = '#{version}'")
      f.puts('end')
    end

    write_project_file changelog_path do |f|
      f.puts <<CHANGELOG
#{name} (#{version}-123435) unstable; urgency=low

  * First release

 -- A Developer <person@web.com>  Mon, 05 Sep 2011 16:33:12 +0100

CHANGELOG
    end

    in_project_dir('project') do
      exec "git add .msp_project #{changelog_path} #{ruby_version_file}"
      exec "git commit -m 'initial commit'"
      exec "git push origin master:master"
    end

    project
  end

  def write_project_file(fname)
    FileUtils.mkdir_p(File.join(@project_dir, File.dirname(fname)))
    File.open(File.join(@project_dir, fname), 'w') do |f|
      yield f
    end
  end

  def in_project_dir(project_name)
    raise 'no project exists' if @project_dir.nil?
    Dir.chdir(@project_dir) do
      yield @project_dir
    end
  end
end

RSpec.configure do |config|
  config.color_enabled = true
end
