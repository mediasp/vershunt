class MSPRelease::Git

  # methods that don't require a local clone
  module ClassMethods
    def version()
      MSPRelease::Exec.exec("git version", :output => StringIO.new)
    end

    def version_gte(maj, min=0, bug=0, patch=0)
      match = version.match(/(\d+)\.(\d+)\.(\d+)\.(\d+).*/)
      match[1].to_i >= maj &&
        match[2].to_i >= min &&
        match[3].to_i >= bug &&
        match[4].to_i >= patch
    end

    def clone(git_url, options={})
      out_to = options[:out_to]
      exec_options = options[:exec] || {}
      depth_arg = options[:depth].nil?? '' : "--depth #{options[:depth]}"
      branch = options[:branch].nil?? '' : "--branch #{options[:branch]}"

      single_branch = if version_gte(1, 7, 10)
        options[:no_single_branch] ? '--no-single-branch' :
          options[:single_branch] ? '--single-branch' :
          ''
      end

      MSPRelease::Exec.
        exec("git clone #{depth_arg} #{single_branch} #{branch} #{git_url} #{out_to.nil?? '' : out_to}", exec_options)
    end
  end

  class << self
    include ClassMethods
  end

  class Commit
    include MSPRelease::Exec::Helpers
    attr_reader :message
    attr_reader :author
    attr_reader :hash

    def initialize(project, attributes)
      @project = project
      attributes.each do |k, v|
        instance_variable_set(:"@#{k}", v)
      end
    end

    def release_commit?
      !! (release_name || tag)
    end

    def tag
      tag = exec "git tag --contains #{hash}"
      (m = /^release-([0-9.]*)$/.match(tag)) && m[1]
    end

    def release_name
      @project.release_name_from_message(message) || tag
    end
  end

  include MSPRelease::Exec::Helpers

  def initialize(project, options)
    @project = project
    @options = options
  end

  def exec_name; 'git'; end

  attr_reader :options

  def on_master?
    cur_branch == 'master'
  end

  def cur_branch
    /^\* (.+)$/.match(exec "git branch")[1]
  end

  def last_release_tag
    a = exec "git describe --tags --match 'release-*'"
  end

  def branch_exists?(branch_name)
    # use backticks, we don't want an error
    `git show-branch origin/#{branch_name}`
    $? == 0
  end

  def create_and_switch(branch_name, options={})
    start_point = options[:start_point]
    exec "git branch #{branch_name} #{start_point}"
    exec "git push origin #{branch_name}"
    exec "git checkout #{branch_name}"
  end

  def added_files
    status_files("new file")
  end

  def modified_files
    status_files("modified")
  end

  def status_files(status)
    output = exec "git status", :status => :any
    pattern = /#{status}: +(.+)$/
    output.split("\n").map {|l| pattern.match(l) }.compact.map{|m|m[1]}
  end

  def latest_commit(project)
    commit_output =
      exec("git --no-pager log -1 --no-color --full-index --pretty=short").split("\n")

    commit_pattern = /^commit ([a-z0-9]+)$/
    author_pattern = /^Author: (.+)$/
    message_pattern = /^    (.+)$/

    hash = commit_output.grep(commit_pattern) {|m| commit_pattern.match(m)[1] }.first
    author = commit_output.grep(author_pattern) {|m| author_pattern.match(m)[1] }.first
    message = commit_output.grep(message_pattern).
      map {|row| message_pattern.match(row)[1] }.
      join(" ")

    Commit.new(project, {:hash => hash, :author => author, :message => message})
  end

  def remote_is_ahead?
    raise NotImplementedError
    branch_name = cur_branch
    exec "git fetch"
    exec "git --no-pager log origin/#{branch_name} --no-color --oneline -1".split("")
  end

end
