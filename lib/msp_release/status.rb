class MSPRelease::Status < MSPRelease::Command

  def self.description
    "Print out discovered release state"
  end

  def run
    if data_exists?
      load_data
      puts "Awaiting push.  Please update the changelog, then run msp_release push "
      puts "Pending : #{data[:version].format}-#{data[:suffix]}"
    else
      if on_release_branch?
        puts "On release branch : #{git_version.format}"
        version, suffix = changelog.version_and_suffix
        puts "Last pushed       : #{version.format}-#{suffix}"
      else
        puts "confused.com"
      end
    end
  end
end
