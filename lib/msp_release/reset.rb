class MSPRelease::Reset < MSPRelease::Command
  def run
    unless data_exists?
      $stderr.puts("Error: No waiting changes")
      exit 1
    end

    exec "git checkout #{Debian::DEFAULT_PATH}"
    remove_data
    puts "Reset"
  end
end
