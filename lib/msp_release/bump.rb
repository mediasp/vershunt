class MSPRelease::Bump < MSPRelease::Command

  include MSPRelease::Exec

  def self.description
    "Increase the version number of the project"
  end

  def run
    segment = arguments.last
    new_version, changed_file = project.bump_version(segment)
    project.status = :Dev
    [changed_file, project.config_file].each do |file|
      exec "git add #{file}"
    end
    exec "git commit -m 'BUMPED VERSION TO #{new_version}'"
    puts "New version: #{new_version}"
  end

end
