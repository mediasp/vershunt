module MSPRelease
  class Build

    class Result
      def initialize(changes_file)
        @changes_file = changes_file
      end

      attr_reader :changes_file
    end

    class NoChangesFileError < StandardError ; end

    include Exec::Helpers

    def initialize(basedir, project)
      @basedir = basedir
      @project = project
    end

    def perform!
      dir = File.expand_path(@basedir)
      raise "directory does not exist: #{dir}" unless
        File.directory?(dir)

      e = Exec.new(:name => 'build', :quiet => false, :status => :any)
      Dir.chdir(dir) do
        e.exec(build_command)
      end

      if e.last_exitstatus != 0
        $stderr.puts("Warning: #{build_command} exited with #{e.last_exitstatus}")
      end

      looking_for = @project.changelog.version.to_s
      changes_file = find_changes_file(looking_for)
      if changes_file && File.exists?(changes_file)
        Result.new(changes_file)
      else
        raise NoChangesFileError, looking_for
      end
    end

    def available_changes_files
      Dir["#{output_directory}/*.changes"]
    end

    def output_directory
      File.expand_path(@project.config[:deb_output_directory] ||
        File.join(@basedir, '..'))
    end

    private

    def build_command
      if cmd = @project.config[:deb_build_command]
        cmd
      else
        'dpkg-buildpackage'
      end
    end

    def changes_pattern
      /#{@project.source_package_name}_([^_]+)_([^\.]+)\.changes/
    end

    def find_changes_file(version_string)
      available_changes_files.find { |fname|
        (m = changes_pattern.match(File.basename(fname))) && m && (m[1] == version_string)
      }
    end

  end
end
