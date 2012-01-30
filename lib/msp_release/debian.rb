class Debian

  module Versions

    class Base

      def self.new_if_matches(string)
        pattern.match(string) && new_from_string(string)
      end

      def self.new_from_string(string)
        match = pattern.match(string)
        parts = (1...match.length).map {|idx| match[idx] }
        begin
          new(*parts)
        rescue => e
          raise "Unable to construct #{self} from #{string}\n#{e.to_s}"
        end
      end

    end

    class Unreleased < Base

      def self.pattern
        /^([0-9]+)\.([0-9]+)\.([0-9]+)$/
      end

      def initialize(major, minor, bugfix)
        @major  = major
        @minor  = minor
        @bugfix = bugfix
      end

      def bump
        Stable.new(@major, @minor, @bugfix, "1")
      end

      def to_s
        [@major, @minor, @bugfix].join(".")
      end
    end

    class Stable < Base

      def self.pattern
        /^([0-9]+)\.([0-9]+)\.([0-9]+)-([0-9]+)$/
      end

      def initialize(major, minor, bugfix, revision)
        @major    = major
        @minor    = minor
        @bugfix   = bugfix
        @revision = revision
      end

      def bump
        self.class.new(@major, @minor, @bugfix, @revision.to_i + 1).to_s
      end

      def to_s
        [@major, @minor, @bugfix].join(".") + "-#{@revision}"
      end

    end

    class Development < Base

      class << self
        include MSPRelease::Helpers

        def pattern
          /^([0-9]+)-git\+([a-f0-9]+)~([a-z0-9\+\.]+)$/
        end

        def new_from_working_directory(branch_name, commit_hash)
          safe_branch_name = branch_name.gsub(/[^a-z0-9]/i, ".")
          new(timestamp, commit_hash[0...6], safe_branch_name)
        end
      end

      def initialize(timestamp, hash, branch_name)
        @timestamp   = timestamp
        @hash        = hash
        @branch_name = branch_name
      end

      def to_s
        "#{@timestamp}-git+#{@hash}~#{@branch_name}"
      end
    end
  end

  def default_distribution ; "msp" ; end

  def initialize(basedir, fname)
    @fname = File.join(basedir, fname)
  end

  attr_reader :fname

  def read_top_line
    File.open(@fname, 'r') {|f|f.readline}
  end

  def version_classes
    [Versions::Unreleased, Versions::Stable, Versions::Development]
  end

  def version
    version_classes.each do |c|
      v = c.new_if_matches(version_string_from_top_line) and
        return v
    end
  end

  def package_name
    /[a-z\-]+/.match(read_top_line)
  end

  def version_string_from_top_line
    tline = read_top_line
    match = /[a-z\-]+ \(([^\)]+)\)/.match(tline)

    match && match[1] or
      raise "could not parse version info from #{tline}"
  end

  def matches(version)
    self.version == version
  end

  def amend(version, distribution=default_distribution)
    # replace the first line
    tline, *all = File.open(@fname, 'r') {|f|f.readlines}
    cur_version = /^[^\(]+\(([^\)]+).+/.match(tline)[1]
    tline = tline.gsub(cur_version, "#{version}")
    all.unshift(tline)

    signoff_idx = all.index {|l| /^ -- .+$/.match(l) }
    all[signoff_idx] = create_signoff

    File.open(@fname, 'w') { |f| all.each {|l|f.puts(l) } }

    version
  end

  def add(version, stub, distribution=default_distribution)
    tline = create_top_line(version, distribution)
    all = File.open(@fname, 'r') {|f| f.readlines }
    new =
      [
       tline,
       "",
       "  * #{stub}",
       "",
       create_signoff + "\n",
       ""
      ]

    File.open(@fname, 'w') {|f| f.write(new.join("\n")); f.write(all.join) }

    version
  end

  def create_signoff
    date = MSPRelease.time_rfc
    author = MSPRelease.author
    " -- #{author.name} <#{author.email}>  #{date}"
  end

  def create_top_line(v, distribution)
    tline = "#{package_name} (#{v})"

    # FIXME, un-hardcode this?
    tline + ") #{distribution}; urgency=low"
  end


end
