module MSPRelease
  class CLI::Reset < CLI::Command

    include CLI::WorkingCopyCommand

    description "Reset changes made by msp_release new"

    def run

      raise CLI::Exit, "No waiting changes" unless data_exists?

      exec "git checkout #{project.changelog_path}"
      remove_data
      puts "Reset"
    end
  end
end
