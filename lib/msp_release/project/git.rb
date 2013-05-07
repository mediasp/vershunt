# Mixin module for git projects.
module MSPRelease
  module Project::Git

    def prepare_for_build(branch_name, options={})
      branch_is_release_branch = !! /^release-.+$/.match(branch_name)
      shallow_output = options[:shallow_output]

      if branch_name && branch_is_release_branch
        LOG.debug("Checking out latest release commit from origin/#{branch_name}#{shallow_output}")
      else
        LOG.debug("Checking out latest commit from origin/#{branch_name}#{shallow_output}")
      end

      pathspec = "origin/#{branch_name}"
      if pathspec != "origin/master"
        move_to(pathspec)
      end
      super if defined?(super)
    end

    def move_to(pathspec)
      Dir.chdir(@dir) do
        begin
          exec("git show #{pathspec} --")
        rescue MSPRelease::Exec::UnexpectedExitStatus => e
          if /^fatal: bad revision/.match(e.stderr)
            raise MSPRelease::CLI::Exit, "Git pathspec '#{pathspec}' does not exist"
          else
            raise
          end
        end

        exec("git checkout --track #{pathspec}")
      end
    end

    def log_command
      Dir.chdir(@dir) do
        "git --no-pager log --no-color --full-index"
      end
    end

    def oneline_pattern
      /^([a-z0-9]+) (.+)$/i
    end

    def find_first_release_commit
      all_commits = exec(log_command +  " --pretty=oneline").
        split("\n")

      all_commits.map { |commit_line|
        match = oneline_pattern.match(commit_line)
        [match[1], match[2]]
      }.find {|hash, message|
        release_name_from_message(message)
      }
    end

    def latest_commit_hash
      output = exec(log_command + " --pretty=oneline -1").split("\n").first
      oneline_pattern.match(output)[1]
    end


    def clean_checkout
      Dir.chdir(@dir) do
        first_commit_hash, commit_message = find_first_release_commit

        exec "git reset --hard #{first_commit_hash}"
      end
    end

  end
end

