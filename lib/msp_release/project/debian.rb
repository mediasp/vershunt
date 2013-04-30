#
# This kind of project stores the version in the debian changelog
#
module MSPRelease::Project::Debian

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

end
