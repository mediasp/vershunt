class MSPRelease::Bump < MSPRelease::Command

  def self.description
    "Increase the version number of the project"
  end

  def run
    segment = arguments.last
    new_version = project.bump_version(segment)
    puts "New version: #{new_version}"
  end

end
