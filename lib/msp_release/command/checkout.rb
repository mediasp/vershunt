require 'fileutils'

module MSPRelease
  class Command::Checkout < MSPRelease::Command

    include Debian::Versions

    # When cloning repositories, limit to this many commits from each head
    CLONE_DEPTH = 5

    def self.description
      "Checkout a release commit from a git repository"
    end

    def run
      git_url = arguments[0]
      release_spec_arg = arguments[1]
      do_build = switches.include?("--build")
      clone_depth = switches.include?("--shallow") ? CLONE_DEPTH : nil

      branch_name = release_spec_arg || 'master'
      pathspec = "origin/#{branch_name}"
      branch_is_release_branch = !! /^release-.+$/.match(branch_name)

      shallow_output = clone_depth.nil?? '' : ' (shallow)'
      if release_spec_arg && branch_is_release_branch
        puts("Checking out latest release commit from #{pathspec}#{shallow_output}")
      else
        puts("Checking out latest commit from #{pathspec}#{shallow_output}")
      end

      tmp_dir = "msp_release-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:depth => clone_depth, :out_to => tmp_dir,
          :exec => {:quiet => true}})

      project = Project.new_from_project_file(tmp_dir + "/" + Helpers::PROJECT_FILE)

      src_dir = Dir.chdir(tmp_dir) do

        if pathspec != "origin/master"
          move_to(pathspec)
        end

        if branch_is_release_branch
          first_commit_hash, commit_message =
            find_first_release_commit(project)

          if first_commit_hash.nil?
            raise ExitException, "Could not find a release commit on #{pathspec}"
          end

          exec "git reset --hard #{first_commit_hash}"
        else
          dev_version = Development.
            new_from_working_directory(branch_name, latest_commit_hash)

          project.changelog.amend(dev_version)
        end
        src_dir = project.source_package_name + "-" + project.changelog.version.to_s
      end

      FileUtils.mv(tmp_dir, src_dir)
      project = Project.new_from_project_file(src_dir + "/" + Helpers::PROJECT_FILE)
      $stdout.puts("Checked out to #{src_dir}")

      if do_build
        $stdout.puts("Building package...")
        build = Build.new(src_dir, project)
        begin
          result = build.perform!
          $stdout.puts("Package built: #{result.changes_file}")
        rescue Build::NoChangesFileError => e
          raise ExitException.new(
            "Unable to find changes file with version: #{e.message}\n" +
            "Available: \n" +
            build.available_changes_files.map { |f| "  #{f}" }.join("\n"))
        end
      end

    end

    private

    def oneline_pattern
      /^([a-z0-9]+) (.+)$/i
    end

    def log_command
      "git --no-pager log --no-color --full-index"
    end

    def latest_commit_hash
      output = exec(log_command + " --pretty=oneline -1").split("\n").first
      oneline_pattern.match(output)[1]
    end

    def find_first_release_commit(project)
      all_commits = exec(log_command +  " --pretty=oneline").
        split("\n")

      all_commits.map { |commit_line|
        match = oneline_pattern.match(commit_line)
        [match[1], match[2]]
      }.find {|hash, message|
        project.release_name_from_message(message)
      }
    end

    def move_to(pathspec)
      begin
        exec("git show #{pathspec} --")
      rescue Exec::UnexpectedExitStatus => e
        if /^fatal: bad revision/.match(e.stderr)
          raise ExitException, "Git pathspec '#{pathspec}' does not exist"
        else
          raise
        end
      end

      exec("git checkout --track #{pathspec}")
    end
  end

end
