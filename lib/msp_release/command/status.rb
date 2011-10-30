class MSPRelease::Command::Status < MSPRelease::Command

  def self.description
    "Print out discovered release state"
  end

  def run
    puts "Status : #{project.status}"
    if data_exists?
      load_data
      puts "Awaiting push.  Please update the changelog, then run msp_release push "
      puts "Pending : #{data[:version].format}-#{data[:suffix]}"
    else
      version, suffix = changelog.version_and_suffix
      puts "Project says     : #{msp_version}" if msp_version
      if on_release_branch?
        puts "On release branch : #{git_version.format}"
        puts "Changelog says    : #{version.format}-#{suffix}"
      else
        puts "Not on a release branch"
        puts "Changelog says    : #{version.format}-#{suffix}"
      end
    end

    puts "Release commit: #{release_name_for_output}"
  end

  def release_name_for_output
    commit = git.latest_commit(project)
    commit.release_commit? && commit.release_name || '<none>'
  end
end
