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

  require 'msp_release/debian'
  require 'msp_release/git'
  require 'msp_release/options'

  MSP_VERSION_FILE = "lib/msp/version.rb"
  DATAFILE = ".msp_release"

  Version = Struct.new(:major, :minor, :bugfix)
  Version.module_eval do
    def format; "#{major}.#{minor}.#{bugfix}"; end
    alias :to_s :format
    def self.from_string(str)
      match = /([0-9]+)\.([0-9]+)\.([0-9]+)/.match(str)
      match && new(*(1..3).map{|i|match[i]})
    end
  end
  Author = Struct.new(:name, :email)

  COMMANDS = {
    'new' => proc {|s,o,a|s.new_release(o,a)},
    'push' => proc {|s,o,a|s.push(o,a)},
    'branch' => proc {|s,o,a|s.branch(o,a)},
    'status' => proc {|s,o,a|s.status(o,a)},
    'reset' => proc {|s,o,a|s.reset(o,a)}
  }

  def run(args)
    options, leftovers = MSPRelease::Options.get(args)
    command, = leftovers
    cmd_proc = COMMANDS[command]

    unless cmd_proc
      $stderr.puts("Unknown command: #{command}")
      exit 1
    end

    cmd_proc.call(self, options, args)
  end

  def reset(o,a)
    unless data_exists?
      $stderr.puts("Error: No waiting changes")
      exit 1
    end

    exec "git checkout #{Debian::DEFAULT_PATH}"
    remove_data
    puts "Reset"
  end

  def status(o,a)
    if data_exists?
      load_data
      puts "Awaiting push.  Please update the changelog, then run msp_release push "
      puts "Pending : #{data[:version].format}-#{data[:suffix]}"
    else
      if on_release_branch?
        puts "On release branch : #{git_version.format}"
        version, suffix = changelog.version_and_suffix
        puts "Last pushed       : #{version.format}-#{suffix}"
      else
      end
    end
  end

  def new_release(options, args)

    fail_if_push_pending
    fail_if_modified_wc

    opts = OptionParser.new do |opts|
      opts.on("--final", TrueClass, "Mark this release as final") do |n|
        options[:final] = true
      end
      opts.on("--rc=NUM", Integer, "Force move to RC stage") do |n|
        options[:rc] = n
      end
    end
    opts.parse(args)

    if on_release_branch?
      release_from_branch(options)
    else
      release_from_master(options)
    end
  end

  def release_from_branch(options)
    deb_version, suffix = changelog.version_and_suffix

    if msp_version != git_version
      $stderr.puts("Error: MSP::Version shows #{msp_version.format}, but git branch says #{git_version.format}")
      exit 1
    end

    next_rc_number =
      if options[:final]
        nil
      elsif suffix == 'final'
        $stderr.puts("Managing bug fix releases not yet implemented")
        exit 1
      elsif /[0-9]{14}$/.match(suffix) || options[:rc]
        options[:rc] || 1
      elsif match = /rc([0-9]+)$/.match(suffix)
        match[1].to_i + 1
      else
        $stderr.puts("Error: Can't recognise changelog suffix: #{suffix}")
        exit 1
      end

    suffix, blurb =
      next_rc_number ? ["rc#{next_rc_number}", "New release candidate"] :
      ['final', "Final release"]

    changelog.add(msp_version, blurb, suffix)
    self.data = {:version => msp_version, :suffix => suffix}
    save_data


    puts_changelog_info
  end

  def release_from_master(options)
    timestamp
    msp_version

    version, suffix = if changelog.matches(msp_version)
      puts "Bumping changelog..."
      changelog.bump(msp_version)
    else
      puts "Adding new dev entry to changelog..."
      changelog.add(msp_version, "New dev version")
    end

    self.data = {:version => version, :suffix => suffix}
    save_data

    puts_changelog_info
  end

  def push(options, args)

    unless data_exists?
      $stderr.puts("You need to stage a new release before you can push it")
      exit 1
    end

    load_data
    release_name = "#{data[:version].format}-#{data[:suffix]}"
    exec "git add #{changelog.fname}"
    exec "git commit -m\"RELEASE COMMIT - #{release_name}\""
    exec "git tag release-#{release_name}"
    exec "git push origin release-#{release_name}"
    File.delete(DATAFILE)
  end

  def branch(options, args)

    fail_if_push_pending

    unless Git.on_master?
      $stderr.puts("You must be on master to create release branches")
      exit 1
    end

    branch_name = "release-#{msp_version.format}"

    if Git.branch_exists?(branch_name)
      puts "A branch for #{msp_version} already exists"
      exit 1
    end

    Git.create_and_switch(branch_name)
  end

  def add_changelog_entry(stub_comment)
    changelog = Debian.new(".")
    changelog.add(msp_version, timestamp, stub_comment)
  end

  def msp_version
    version_pattern = /VERSION = '([0-9]+)\.([0-9]+)\.([0-9]+)'/
    @msp_version ||=
      File.open(MSP_VERSION_FILE, 'r') do |f|
      v_line = f.readlines.map {|l|version_pattern.match(l)}.compact.first
      raise "Couldn't parse version from #{MSP_VERSION_FILE}" unless v_line
      Version.new(* (1..3).map {|i|v_line[i]} )
    end
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
    @author ||= begin
      name, email = ['name', 'email'].map {|f| `git config --get user.#{f}`.strip}
      Author.new(name, email)
    end
  end

  def changelog
    @changelog ||= Debian.new(".")
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

  extend self

end

