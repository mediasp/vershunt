class MSPRelease::Command::Bump < MSPRelease::Command

  include WorkingCopyCommand

  def self.description
    "Increase the version number of the project"
  end

  def run
    segment = arguments.last
    new_version, changed_file = project.bump_version(segment)
    [changed_file, project.config_file].each do |file|
      exec "git add #{file}"
    end
    exec "git commit -m 'BUMPED VERSION TO #{new_version}'"
    puts "New version: #{new_version}"
  end

end
