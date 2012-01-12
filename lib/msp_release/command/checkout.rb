require 'fileutils'

module MSPRelease
  class Command::Checkout < MSPRelease::Command

    def self.description
      "Checkout a release commit from a git repository"
    end

    def run
      git_url = ARGV[1]

      puts("Checking out latest release commit from #{git_url}...")

      tmp_dir = "msp_release-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:out_to => tmp_dir, :exec => {:quiet => true}})

      project = Project.new(tmp_dir + "/" + Helpers::PROJECT_FILE)

      src_dir = Dir.chdir(tmp_dir) {

        all_commits = exec("git --no-pager log --no-color --full-index --pretty=oneline").
        split("\n")

        first_commit_hash, commit_message = all_commits.map { |commit_line|
          match = /^([a-z0-9]+) (.+)$/i.match(commit_line)
          [match[1], match[2]]
        }.find {|hash, message|
          project.release_name_from_message(message)
        }

        if first_commit_hash.nil?
          raise ExitException, "Could not find a release commit on master"
        end

        exec "git reset --hard #{first_commit_hash}"
        release_name = project.release_name_from_message(commit_message)
        project.source_package_name + "-" + release_name
      }

      FileUtils.mv(tmp_dir, src_dir)
    end

  end

end
