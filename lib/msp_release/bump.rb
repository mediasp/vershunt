class MSPRelease::Bump < MSPRelease::Command

  def self.description
    "Increase the version number of the project"
  end

  def run
    segment = arguments.last
    new_version = project.version.bump(segment.to_sym)

    puts "New version #{new_version}"
    project.bump_version(new_version)
  end

end
