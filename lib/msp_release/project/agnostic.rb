#
# This kind of project stores the version in the debian changelog
#
class MSPRelease::Project
  class Agnostic < MSPRelease::Project

    def write_version(new_version)
      debian_version = Debian::Versions::Unreleased.new_from_version(new_version)
      changelog.add(debian_version, "New version")

      [changelog.fname]
    end

    def version
      changelog.version.to_version
    end

  end
end
