require 'msp_release/project/ruby'
require 'msp_release/project/agnostic'

class MSPRelease::Project

  DEFAULT_PATH = "debian/msp/changelog"
  RELEASE_COMMIT_PREFIX = "RELEASE COMMIT - "

  attr_reader :changelog_path, :config, :config_file

  def self.new_from_project_file(filename)
    config = YAML.load_file(filename)

    if config[:ruby_version_file]
      Ruby.new(config)
    else
      Agnostic.new(config)
    end
  end

  def initialize(config)
    @config = config
    config.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def source_package_name
    debian_dir = File.dirname(changelog_path)
    control_file = File.join(debian_dir + '/control')
    source_line = MSPRelease::Exec.exec("grep Source: #{control_file}")
    match = /^Source: (.+)$/.match(source_line)
    match && match[1]
  end

  def changelog
    Debian.new(".", changelog_path)
  end

  # Produce the name of a release using the data that is created with
  # msp_release new
  def release_name(release_data)
    "#{data[:version].format}-#{data[:suffix]}"
  end

  def release_name_from_message(commit_message)
    idx = commit_message.index(RELEASE_COMMIT_PREFIX)
    return nil unless idx == 0

    commit_message[RELEASE_COMMIT_PREFIX.length..-1]
  end

  # Returns the commit message that should be used for a given release
  def release_commit_message(release_name)
    "#{RELEASE_COMMIT_PREFIX}#{release_name}"
  end

  def branch_name(version=self.version)
    "release-#{version.format}"
  end

  def at_version?(rhs_version)
    any_version == rhs_version
  end

  def any_version
    version || changelog.version
  end

  def version
    raise NotImplementedError
  end

  def write_version(segment)
    raise NotImplementedError
  end

  def bump_version(segment)
    new_version = version.bump(segment.to_sym)
    written_file = write_version(new_version)
    [new_version, written_file]
  end

end
