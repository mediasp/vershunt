class MSPRelease::Command::Status < MSPRelease::Command

  include WorkingCopyCommand

  def self.description
    "Print out discovered release state"
  end

  def run
    if data_exists?
      load_data
      puts "Awaiting push.  Please update the changelog, then run msp_release push "
      puts "Pending : #{data[:version].format}-#{data[:suffix]}"
    else
      version, suffix = changelog.version_and_suffix
      changelog_version = [version.format, suffix].compact.join("-")

      puts "Project says     : #{msp_version}" if msp_version
      if on_release_branch?
        puts "On release branch : #{git_version.format}"
      else
        puts "Not on a release branch"
      end

      puts "Changelog says : #{changelog_version}"
    end

    puts "Release commit: #{release_name_for_output}"
  end

  def changelog_version
  end

  def release_name_for_output
    commit = git.latest_commit(project)
    commit.release_commit? && commit.release_name || '<none>'
  end
end
