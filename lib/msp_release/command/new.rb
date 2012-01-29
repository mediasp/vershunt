class MSPRelease::Command::New < MSPRelease::Command

  include WorkingCopyCommand

  def self.description
    "Prepare master or a release branch for a release push"
  end

  def run
    fail_if_push_pending
    fail_if_modified_wc
    fail_unless_on_release_branch

    deb_version, suffix = changelog.version_and_suffix
    project_version = project.any_version

    new_suffix = get_next_release_number(suffix)

    puts "Adding new entry to changelog..."
    changelog.add(project_version, "New release", new_suffix)

    self.data = {:version => project_version, :suffix => new_suffix}
    save_data

    puts "Changelog now at #{project_version}-#{new_suffix}"

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
