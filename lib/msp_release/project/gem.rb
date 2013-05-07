
module MSPRelease::Project::Gem
  include MSPRelease::Exec::Helpers

  def gemspec_file
    @gemspec_file ||= begin
      files = Dir.glob("#{@dir}/*.gemspec")

      $stderr.puts "Warning: more than one gemspec found" if files.count > 1
      raise "Can't find gemspec" if files.count < 0

      gemspec_file = files.first

      # puts "Using gemspec #{gemspec_file}"

      gemspec_file
    end
  end

  def gemspec_name
    File.new(gemspec_file, 'r').readlines.find { |l|
      l =~ /\w+\.name\s*=\s*(['"])(\w+)\1/
    }
    $2
  end

  def name
    gemspec_name
  end

  def next_version_for_release(options={})
    tag = "release-#{version}"
    check_tag = exec("git show-ref --tags #{tag}", :status => [0,1])
    unless check_tag == ""
       $stderr.puts "Tag #{tag} already exists, you must bump the version before the next release"
       exit(1)
    end
    version
  end

end

