require 'fileutils'
require 'tmpdir'
require 'msp_release'
require 'open3'
require 'yaml'

RSpec::Matchers.define :exit_with do |expected, _|
  match do |actual|
    actual[:status].exitstatus == expected
  end

  failure_message_for_should do |actual|
    "expected that `#{actual[:command]}` would have exited with: #{expected}\nexited with: #{actual[:status].exitstatus}\nstderr:\n#{actual[:stderr]}\nstdout:\n#{actual[:stdout]}"
  end

end

shared_context "project_helpers" do

  before do
    @tmpdir = Dir.mktmpdir
  end

  after do
    @tmpdir = nil
  end

  before do
    @bin_path = File.expand_path('bin')
  end

  def run(cmd)
    @last_command = cmd

    @last_status = POpen4.popen4(@last_command) do |stdout, stderr, stdin, pid|
      @last_stdout = stdout.read.strip
      @last_stderr = stderr.read.strip
      @last_pid = pid
    end
  end

  def last_run
    {
      :command => @last_command,
      :stdout  => @last_stdout,
      :stderr  => @last_stderr,
      :pid     => @last_pid,
      :status  => @last_status
    }
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

  def write_project(name, to_be_yamled)
    create_project_dir(name)
    fname = File.join(@project_dir, '.msp_project')
    File.open(fname, 'w') {|f| f.write(to_be_yamled.to_yaml) }
    MSPRelease::Project.new_from_project_file(fname)
  end

  def init_project(name, options)
    changelog_path = options.fetch(:changelog_path, "debian/changelog")
    control_path = 'debian/control'
    rules_path = 'debian/rules'
    compat_path = 'debian/compat'
    ruby_version_file = options.fetch(:ruby_version_file, "lib/#{name}/version.rb")
    status = options.fetch(:status, :Dev)
    version = options.fetch(:version, '0.0.1')
    changelog_version = options[:changelog_version] || version

    create_project_dir(name)
    @remote_repo = File.expand_path(@project_dir + "/../#{name}-remote.git")
    Dir.chdir(@project_dir + '/..') do
      exec "git init --bare #{@remote_repo}"
    end

    in_project_dir(name) do
      exec "git clone #{@remote_repo} ."
    end


    deb_options = options.fetch(:deb, {}).
      map {|k, v| { :"deb_#{k}" => v } }.
      inject {|a, b| a.merge(b) }

    project = write_project name, {
      :status => status,
      :changelog_path =>  changelog_path
    }.merge(deb_options || {}).
      merge(ruby_version_file.nil?? {} :
      {:ruby_version_file => ruby_version_file})

    if ruby_version_file
      FileUtils.mkdir_p(File.join(@project_dir, File.dirname(ruby_version_file)))
      File.open(File.join(@project_dir, ruby_version_file), 'w') do |f|
        f.puts('module SomeModule')
        f.puts("  VERSION = '#{version}'")
        f.puts('end')
      end
    end

    write_project_file changelog_path do |f|
      f.puts <<CHANGELOG
#{name} (#{changelog_version}) unstable; urgency=low

  * First release

 -- A Developer <person@web.com>  Mon, 05 Sep 2011 16:33:12 +0100

CHANGELOG
    end

    File.open(File.join(@project_dir, rules_path), 'w') do |f|
      f.puts("""
#!/usr/bin/make -f
# -*- makefile -*-

%:
        dh $@
""")
    end

    File.open(File.join(@project_dir, compat_path), 'w') do |f|
      f.puts("""8
""")
    end

    File.open(File.join(@project_dir, control_path), 'w') do |f|
      f.puts("""
Source: #{name}
Section: misc
Priority: extra
Maintainer: Joe Bloggs <joe.bloggs@gmail.com>
Build-Depends: debhelper (>= 7), autotools-dev
Standards-Version: 3.8.1
Homepage: http://dev.playlouder.com/

Package: lib#{name}
Section: misc
Architecture: any
Depends: libc6 (>= 2.4), libruby1.8 (>= 1.8.7), ruby1.8
Description: Core library
 Core library for moving bytes from a to b
""")
    end

    FileUtils.chmod(0755, rules_path)

    in_project_dir('project') do
      exec "git add .msp_project #{changelog_path} #{ruby_version_file} #{control_path} #{rules_path} #{compat_path}"
      exec "git commit -m 'initial commit'"
      exec "git push origin master:master"
    end

    project
  end

  def build_init_project(*args)
    init_project(*args)
    in_project_dir do |dir|
      Dir.mkdir('bin')
      build_cmd = 'bin/build-debs.sh'
      File.open(build_cmd, 'w') do |f|
        f.write <<BASH
#!/bin/bash
#{@build_extra}
BASH
      end
      FileUtils.chmod 0755, "bin/build-debs.sh"
      exec "git add bin/build-debs.sh"
      exec "git commit -m 'build command'"
      exec "git push origin master:master"
    end
  end

  def run_msp_release(*args)
    run File.join(@bin_path, 'vershunt') + " #{args.join(' ')}"
  end

  def write_project_file(fname)
    FileUtils.mkdir_p(File.join(@project_dir, File.dirname(fname)))
    File.open(File.join(@project_dir, fname), 'w') do |f|
      yield f
    end
  end

  def in_remote_dir
    Dir.chdir @remote_repo do
      yield @remote_repo
    end
  end

  def in_project_dir(project_name=@project_name)
    raise 'no project exists' if @project_dir.nil?
    Dir.chdir(@project_dir) do
      yield @project_dir
    end
  end

  def in_tmp_dir(sub_dir=nil, &block)
    Dir.mktmpdir do |tmpdir|
      change_to = [tmpdir, sub_dir].compact.join('/')
      FileUtils.mkdir_p(change_to) unless File.exists?(change_to)
      Dir.chdir(change_to, &block)
    end
  end

  def release_branch_should_match(string)
    run_msp_release 'status'
    last_run.should exit_with(0)
    last_stdout.should match(/Release branch +: +#{Regexp.escape(string)}$/)
  end

  def project_version_should_match(string)
    run_msp_release 'status'
    last_run.should exit_with(0)
    last_stdout.should match(/Changelog says +: +#{Regexp.escape(string)}$/)
  end

end

RSpec.configure do |config|
  config.color_enabled = true
end
