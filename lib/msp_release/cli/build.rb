module MSPRelease
  class CLI::Build < CLI::Command

    include CLI::WorkingCopyCommand

    description "Build debian packages suitable for deployment"

    def run
      fail_if_modified_wc
      fail_unless_has_build_command

      commit = git.latest_commit(project)
      fail_unless_release_commit(commit)

      build = Build.new('.', project)
      build.perform_from_cli!
    end

    private

    def available_changes_files
      Dir["#{output_directory}/*.changes"]
    end

    def find_changes_file(version)
      available_changes_files.find { |fname|
        (m = changes_pattern.match(fname)) && m && (m[1] == version)
      }
    end

    def changes_pattern
      /#{package_name}_([^_]+)_([^\.]+)\.changes/
    end

    def package_name
      project.config[:deb_package_name]
    end

    def output_directory
      @output_directory ||= File.expand_path(project.config[:deb_output_directory])
    end

    def build_command
      project.config[:deb_build_command]
    end

    def fail_unless_release_commit(commit)
      if ! commit.release_commit?
        raise CLI::Exit, "HEAD is not a release commit:\n" +
          "    #{commit.message[0...40]}..."
      end
    end

    def fail_unless_has_build_command
      if build_command.nil? || build_command.empty?
        raise CLI::Exit, "project does not define a build_command, can't build"
      end
    end
  end
end
