module MSPRelease
  class CLI::New < CLI::Command

    include CLI::WorkingCopyCommand

    def self.description
      "Prepare master or a release branch for a release push"
    end

    def run
      fail_if_push_pending
      fail_if_modified_wc
      fail_unless_on_release_branch

      deb_version = changelog.version
      project_version = project.version
      distribution = distribution_from_switches || changelog.distribution

      new_version =
        if deb_version.to_version != project_version
          $stderr.puts("Warning: project version (#{project_version.to_s}) did not match changelog version (#{deb_version.to_s}), project version wins")
          changelog.reset_at(project_version)
        else
          deb_version.bump
        end

      puts "Adding new entry to changelog..."
      changelog.add(new_version, "New release", distribution)

      self.data = {:version => new_version}
      save_data

      puts "Changelog now at #{new_version}"

      puts_changelog_info
    end

    def fail_unless_on_release_branch
      if git.cur_branch != project.branch_name
        $stderr.puts("You must be on a release branch to create release commits")
        $stderr.puts("Switch to a release branch, or build from any branch without creating a release commit for development builds")
        exit 1
      end
    end

    def get_next_release_number(suffix)
      suffix_pattern = /([0-9]+)/
      if suffix.nil? || suffix_pattern.match(suffix)
        suffix.to_i + 1
      else
        raise ExitException, "malformed suffix: #{suffix}\Fix the changelog and try again"
      end
    end
  end
end
