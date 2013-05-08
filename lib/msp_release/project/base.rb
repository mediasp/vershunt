module MSPRelease
  class Project::Base

    include MSPRelease::Exec::Helpers

    RELEASE_COMMIT_PREFIX = "RELEASE COMMIT - "

    attr_reader :config, :config_file, :dir

    def initialize(filename, dir='.')
      @config_file = filename
      @dir = dir
      @config = YAML.load_file(@config_file)
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

    def bump_version(segment)
      new_version = version.bump(segment.to_sym)
      written_files = write_version(new_version)
      [new_version, *written_files]
    end

    def build(options={})
      unless self.respond_to?(:build_command)
        raise "Don't know how to build this project"
      end

      build_opts(options) if self.respond_to?(:build_opts)

      LOG.debug("Checked out to #{@dir}")

      LOG.debug("Building...")
      build = Build.new(@dir, self, options)

      result = build.perform_from_cli!
      LOG.debug("Build products:")
      result.files.each {|f| LOG.info(f) }
    end

  end
end
