require 'yaml'

module MSPRelease

  module Exec
    def exec(command, ret_code=0)
      ret_codes = [*ret_code]
      res = `#{command}`
      unless ret_codes.include?($?)
        $stderr.puts("Command failed: #{command}")
        $stderr.puts("Return code   : #{$?}")
        raise "Command failed"
      end
      res
    end
  end

  include Exec

  module Helpers

    PROJECT_FILE = ".msp_project"

    # Slush bucket for stuff :)
    def add_changelog_entry(stub_comment)
      changelog = project.changelog
      changelog.add(msp_version, timestamp, stub_comment)
    end

    def msp_version
      project.version
    end

    def git_version
      Version.from_string(/release-(.+)/.match(Git.cur_branch)[1])
    end

    def time; @time ||= Time.now; end

    def timestamp
      @timestamp ||= time.strftime("%Y%m%d%H%M%S")
    end

    def time_rfc
      offset = time.gmt_offset / (60 * 60)
      gmt_offset = "#{offset < 0 ? '-' : '+'}#{offset.abs.to_s.rjust(2, "0")}00"
      time.strftime("%a, %d %b %Y %H:%M:%S #{gmt_offset}")
    end

    def author
      @author ||=
        begin
          name, email = ['name', 'email'].map {|f| `git config --get user.#{f}`.strip}
          Author.new(name, email)
        end
    end

    def changelog
      @changelog ||= project.changelog
    end

    def on_release_branch?
      !!/release/.match(Git.cur_branch)
    end

    def data
      @data ||= {}
    end

    def data=(data_hash)
      @data = data_hash
    end

    def data_exists?
      File.exists?(DATAFILE)
    end

    def load_data
      @data = File.open(DATAFILE, 'r') {|f| YAML.load(f) }
    end

    def save_data
      File.open(DATAFILE, 'w') {|f| YAML.dump(@data, f) }
    end

    def remove_data
      File.delete(DATAFILE) if File.exists?(DATAFILE)
    end

    def puts_changelog_info
      puts "OK, please update the change log, then run 'msp_release push' to push your changes for building"
    end

    def fail_if_modified_wc
      annoying_files = Git.modified_files + Git.added_files
      if annoying_files.length > 0
        $stderr.puts("You have modified files in your working copy, and that just won't do")
      annoying_files.each {|f|$stderr.puts("  " + f)}
        exit 1
      end
    end

    def fail_if_push_pending
      if data_exists?
        $stderr.puts("You have a release commit pending to be pushed")
        $stderr.puts("Please push, or reset the operation")
        exit 1
      end
    end
  end

  include Helpers

  require 'msp_release/debian'
  require 'msp_release/git'
  require 'msp_release/options'
  require 'msp_release/project'

  MSP_VERSION_FILE = "lib/msp/version.rb"
  DATAFILE = ".msp_release"

  VERSION_SEGMENTS = [:major, :minor, :bugfix]
  Version = Struct.new(*VERSION_SEGMENTS)
  Version.module_eval do
    def format; "#{major}.#{minor}.#{bugfix}"; end
    alias :to_s :format

    def self.from_string(str)
      match = /([0-9]+)\.([0-9]+)\.([0-9]+)/.match(str)
      match && new(*(1..3).map{|i|match[i]})
    end

    def bump(segment)

      raise ArgumentError, "no such segment: #{segment}" unless VERSION_SEGMENTS.include?(segment)

      new_segments = VERSION_SEGMENTS.map do |cur_seg|
        part = self.send(cur_seg)
        if cur_seg == segment
          part.to_i + 1
        else
          part
        end.to_s
      end

      "new_segments: #{new_segments}"

      self.class.new(*new_segments)
    end
  end
  Author = Struct.new(:name, :email)

  class Command
    include Helpers
    include Exec
    Git = MSPRelease::Git
    def initialize(project, options, arguments)
      @project = project
      @options = options
      @arguments = arguments
    end
    attr_accessor :options, :arguments, :project
  end

  COMMANDS = ['new', 'push', 'branch', 'status', 'reset', 'bump']

  def run(args)
    init_commands
    # TODO there aren't any global options yet, so get rid?
    options, leftovers = MSPRelease::Options.get(args)
    cmd_name, = leftovers
    cmd = @commands[cmd_name]

    unless cmd
      $stderr.puts("Unknown command: #{cmd_name}")
      print_help
      exit 1
    end

    if File.exists?(PROJECT_FILE)
      project = MSPRelease::Project.new(PROJECT_FILE)
    else
      $stderr.puts("No #{PROJECT_FILE} present in current directory")
      exit 1
    end

    cmd.new(project, options, args).run
  end

  def init_commands
    @commands = {}
    COMMANDS.each do |name|
      require "msp_release/#{name}"
      camel_name =
        name.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
      @commands[name] = MSPRelease.const_get(camel_name)
    end
  end

  def print_help
    puts "Usage: msp_release COMMAND [OPTIONS]"
    puts ""
    puts "Available commands:"
    COMMANDS.each do |cmd_name|
      puts "  #{cmd_name.ljust(8)} #{@commands[cmd_name].description}"
    end
  end

  extend self

end

