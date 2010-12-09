class MSPRelease::Reset < MSPRelease::Command

  def self.description
    "Reset changes made by msp_release new"
  end

  def run
    unless data_exists?
      $stderr.puts("Error: No waiting changes")
      exit 1
    end

    exec "git checkout #{project.changelog_path}"
    remove_data
    puts "Reset"
  end
end
