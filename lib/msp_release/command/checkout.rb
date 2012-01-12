require 'fileutils'

module MSPRelease
  class Command::Checkout < MSPRelease::Command

    def self.description
      "Checkout a release commit from a git repository"
    end

    def run
      git_url = ARGV[1]
      release_spec_arg = ARGV[2] || 'master'
      pathspec = "origin/#{release_spec_arg}"

      puts("Checking out latest release commit from #{pathspec}...")

      tmp_dir = "msp_release-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:out_to => tmp_dir, :exec => {:quiet => true}})

      project = Project.new(tmp_dir + "/" + Helpers::PROJECT_FILE)

      src_dir = Dir.chdir(tmp_dir) do

        move_to(pathspec) unless pathspec == 'origin/master'

        first_commit_hash, commit_message =
          find_first_release_commit(project)

        if first_commit_hash.nil?
          raise ExitException, "Could not find a release commit on #{pathspec}"
        end

        exec "git reset --hard #{first_commit_hash}"
        release_name = project.release_name_from_message(commit_message)
        project.source_package_name + "-" + release_name
      end

      FileUtils.mv(tmp_dir, src_dir)
      puts("Checked out to #{src_dir}")
    end

    private

    def find_first_release_commit(project)
      all_commits = exec("git --no-pager log --no-color --full-index --pretty=oneline").
        split("\n")

      all_commits.map { |commit_line|
        match = /^([a-z0-9]+) (.+)$/i.match(commit_line)
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
