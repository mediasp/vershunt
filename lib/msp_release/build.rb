module MSPRelease
  class Build

    class Result
      def initialize(changes_file)
        @changes_file = changes_file
      end

      attr_reader :changes_file
    end

    class NoChangesFileError < StandardError ; end

    include Helpers

    def initialize(basedir, project)
      @basedir = basedir
      @project = project
    end

    def perform!
      Dir.chdir(@basedir) do
        exec build_command
      end

      looking_for = @project.changelog.version.to_s
      changes_file = find_changes_file(looking_for)
    end

    def available_changes_files
      Dir["#{output_directory}/*.changes"]
    end

    def output_directory
      File.expand_path(project.config[:deb_output_directory] ||
        File.join(@basedir, '..'))
    end

    private

    def build_command
      @project.config[:deb_build_command] || 'dpkg-buildpackage'
    end

    def changes_pattern(project)
      /#{@project.source_package_name}_([^_]+)_([^\.]+)\.changes/
    end

    def find_changes_file(version_string)
      available_changes_files.find { |fname|
        (m = changes_pattern.match(fname)) && m && (m[1] == version_string)
      }
    end

  end
end
