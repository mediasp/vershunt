class MSPRelease::New < MSPRelease::Command

  def self.description
    "Prepare master or a release branch for a release push"
  end

  def run
    fail_if_push_pending
    fail_if_modified_wc

    deb_version, suffix = changelog.version_and_suffix
    project_version = project.any_version

    if project.final? && suffix == 'final'
      $stderr.puts("You've already performed a final release on this version")
      exit 1
    end

    next_suffix = if project.final?
      'final'
    elsif project.rc?
      "rc#{get_next_rc_number(suffix)}"
    else
      nil
    end

    used_version, used_suffix = if project.at_version?(deb_version) && next_suffix.nil?
      puts "Amending changelog..."
      changelog.amend(project_version)
    else
      puts "Adding new entry to changelog..."
      changelog.add(project_version, "New release", next_suffix)
    end

    self.data = {:version => project_version, :suffix => used_suffix}
    save_data

    puts "Changelog now at #{used_version}-#{used_suffix}"

    puts_changelog_info
  end

  def get_next_rc_number(suffix)
    suffix && (match = /rc([0-9]+)$/.match(suffix)) && match[1] || 1
  end

end
