#
# This kind of project uses a ruby file with a VERSION constant to be the
# authorative source for the version
#
module MSPRelease::Project::Ruby

  attr_reader :ruby_version_file

  def version_pattern
    /VERSION = '([0-9]+)\.([0-9]+)\.([0-9]+)'/
  end

  def write_version(new_version)
    lines = File.open(ruby_version_file, 'r')  { |f| f.readlines }
    lines = lines.map do |line|
      if match = version_pattern.match(line)
        line.gsub(/( *VERSION = )'.+'$/, "\\1'#{new_version.to_s}'")
      else
        line
      end
    end

    File.open(ruby_version_file, 'w')  { |f| f.write(lines) }

    defined?(super) ?
      Array(super).push(ruby_version_file) :
      [ruby_version_file]
  end

  def version
    Dir.chdir(@dir) do
      File.open(ruby_version_file, 'r') do |f|
        v_line = f.readlines.map {|l|version_pattern.match(l)}.compact.first
        raise "Couldn't parse version from #{ruby_version_file}" unless v_line
        MSPRelease::Version.new(* (1..3).map {|i|v_line[i]} )
      end
    end
  end

end
