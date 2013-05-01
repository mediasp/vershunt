#
# This kind of project stores the version in the debian changelog
#
module MSPRelease::Project::Debian

  include MSPRelease::Exec::Helpers

  DEFAULT_PATH = "debian/msp/changelog"

  def write_version(new_version)
    debian_version = Debian::Versions::Unreleased.new_from_version(new_version)
    changelog.add(debian_version, "New version")

    defined?(super) ?
      Array(super).push(changelog.fname) :
      [ruby_version_file]
  end

  def version
    puts changelog.version.to_version.inspect
    changelog.version.to_version
  end

  def changelog_path
    @changelog_path || 'debian/changelog'
  end

  def source_package_name
    debian_dir = File.dirname(File.join(@dir, changelog_path))
    control_file = File.join(debian_dir + '/control')
    source_line = MSPRelease::Exec.exec("grep Source: #{control_file}")
    match = /^Source: (.+)$/.match(source_line)
    match && match[1]
  end

  def changelog
    Debian.new(@dir, changelog_path)
  end

  def next_version_for_release(options = {})
    deb_version = changelog.version
    distribution = options[:distribution] || changelog.distribution

    new_version =
      if deb_version.to_version != version
        $stderr.puts "Warning: project version (#{version.to_s}) " +
          "did not match changelog version (#{deb_version.to_s}), project " +
            "version wins"
        changelog.reset_at(version)
      else
        deb_version.bump
      end

    puts "Adding new entry to changelog..."
    changelog.add(new_version, "New release", distribution)

    puts "Changelog now at #{new_version}"
    puts_changelog_info

    new_version
  end

  def puts_changelog_info
    $stdout.puts "OK, please update the change log, then run 'vershunt push' to push your changes for building"
  end

  def project_specific_push(release_name)
    # Create a release commit.
    commit_message = release_commit_message(release_name)
    exec "git add #{changelog.fname}"
    exec "git commit -m\"#{commit_message}\""
  end

end
