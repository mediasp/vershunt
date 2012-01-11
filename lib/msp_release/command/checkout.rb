module MSPRelease
  class Command::Checkout < MSPRelease::Command

    def self.description
      "Checkout a release commit from a git repository"
    end

    def run
      git_url = ARGV[1]

      $stderr.puts("Checking out latest release commit from #{git_url}...")

      tmp_dir = "msp_release-#{Time.now.to_i}.tmp"
      Git.clone(git_url, tmp_dir)
      Dir.chdir(tmp_dir) do
        all_commits = exec("git --no-pager --no-color --full-index --pretty=oneline").
          split("\n")

        first_commit_hash, _ = all_commits.map { |commit_line|
          match = /^([a-z0-9]) (.+)$/i.match(commit_line)
          [match[1], match[2]]
        }.find {|hash, message|
          project.release_name_from_message(message)
        }

        exec "git reset --hard #{first_commit_hash}"
      end
    end

  end

end
