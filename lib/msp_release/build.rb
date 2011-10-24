class MSPRelease::Build < MSPRelease::Command

  def self.description
    "Build debian packages suitable for deployment"
  end

  def run
    fail_if_modified_wc
    fail_unless_has_build_command

    commit = Git.latest_commit
    fail_unless_release_commit(commit)

    exec build_command

    changes_file = find_changes_file
  end

  private

  def find_changes_file(version)
    Dir["#{output_directory}/*.changes"].find { |fname|
     (m =  changes_pattern.match(fname)) && m && m[1] == version
    }
  end

  def changes_pattern
    /#{changes_prefix}_([^_]+)_([^\.]+)\.changes/
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
    prefix = MSPRelease::Push::RELEASE_COMMIT_PREFIX
    message = commit[:message]

    if message.index(prefix) != 0
      $stderr.puts("HEAD is not a release commit:")
      $stderr.puts("    #{message[0...40]}...")
      exit 1
    end
  end

  def fail_unless_has_build_command
    if build_command.nil? || build_command.empty?
      $stderr.puts("project does not define a build_command, can't build")
      exit 1
    end
  end

end
