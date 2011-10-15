class MSPRelease::Project

  DEFAULT_PATH = "debian/msp/changelog"

  module Status

    def self.all
      [:Dev, :RC, :Final]
    end

    def self.[](const)
      self.const_get(const)
    end

    def self.next(const)
      cur_index = all.index(const)
      all[cur_index + 1]
    end

    all.each_with_index do |sym, idx|
      const_set(sym, idx)
    end

  end

  attr_reader :changelog_path, :ruby_version_file, :config, :config_file

  def initialize(project_config_file)
    @config_file = project_config_file
    @config = YAML.load_file(project_config_file)
    config.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def changelog
    Debian.new(".", changelog_path)
  end

  def status
    @status || :Dev
  end

  def status=(status)
    @status = status
    config[:status] = status
    File.open(@config_file, 'w') {|f| f.write(YAML.dump(config)) }
  end

  def next_status
    Status.next(status)
  end

  def final?; status == :Final; end
  def rc?; status == :RC; end
  def dev?; status == :Dev; end

  def at_version?(rhs_version)
    any_version == rhs_version
  end

  def version_pattern
    /VERSION = '([0-9]+)\.([0-9]+)\.([0-9]+)'/
  end

  def any_version
    version || changelog.version
  end

  def version

    return nil unless ruby_version_file

    @msp_version ||=
      File.open(ruby_version_file, 'r') do |f|
      v_line = f.readlines.map {|l|version_pattern.match(l)}.compact.first
      raise "Couldn't parse version from #{ruby_version_file}" unless v_line
      MSPRelease::Version.new(* (1..3).map {|i|v_line[i]} )
    end
  end

  def bump_version(segment)
    new_version = (version || changelog.version).bump(segment.to_sym)

    changed_file = if version
      lines = File.open(ruby_version_file, 'r')  { |f| f.readlines }
      lines = lines.map do |line|
        if match = version_pattern.match(line)
          line.gsub(/( *VERSION = )'.+'$/, "\\1'#{new_version.to_s}'")
        else
          line
        end
      end
      File.open(ruby_version_file, 'w')  { |f| f.write(lines) }
      ruby_version_file
    else
      changelog.add(new_version, "New development version")
      changelog.fname
    end

    [new_version, changed_file]
  end

end