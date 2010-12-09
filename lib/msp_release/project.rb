class MSPRelease::Project

  DEFAULT_PATH = "debian/msp/changelog"

  module Status
    DEV = 0
    RC = 1
    FINAL = 2
  end

  attr_reader :changelog_path, :ruby_version_file

  def initialize(project_config_file)
    config = YAML.load_file(project_config_file)
    config.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def changelog
    Debian.new(".", changelog_path)
  end

  def version
    version_pattern = /VERSION = '([0-9]+)\.([0-9]+)\.([0-9]+)'/

    return nil unless ruby_version_file

    @msp_version ||=
      File.open(ruby_version_file, 'r') do |f|
      v_line = f.readlines.map {|l|version_pattern.match(l)}.compact.first
      raise "Couldn't parse version from #{ruby_version_file}" unless v_line
      MSPRelease::Version.new(* (1..3).map {|i|v_line[i]} )
    end
  end

end
