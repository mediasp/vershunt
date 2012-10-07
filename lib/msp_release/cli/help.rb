module MSPRelease
  class CLI::Help < CLI::Command

    description "Show help for vershunt and its sub-commands"

    arg :command_name, "Name of command to see help for", :required => false

    def run
      command_name = arguments[:command_name]
      command_class = MSPRelease::CLI.commands[command_name]
      raise Climate::HelpNeeded.new(command_class || self)
    end
  end
end
