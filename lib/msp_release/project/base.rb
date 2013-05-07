class MSPRelease::Project::Base

  include MSPRelease::Exec::Helpers

  RELEASE_COMMIT_PREFIX = "RELEASE COMMIT - "

  attr_reader :config, :config_file

  def initialize(config, dir='.')
    @dir = dir
    @config = config
    config.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
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
    "release-#{version.format(:without_bugfix => true)}"
  end

  def at_version?(rhs_version)
    any_version == rhs_version
  end

  def version
  end

  def write_version(segment)
  end

  def bump_version(segment)
    new_version = version.bump(segment.to_sym)
    written_files = write_version(new_version)
    [new_version, *written_files]
  end

end
