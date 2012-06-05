module MSPRelease
  class CLI::Help < CLI::Command
    def self.description
      "Show help for msp_release and its sub-commands"
    end

    cli_argument :command_name, "Name of command to see help for", :required => false

    def run
      cmd_name = arguments[:command_name]
      if cmd_name
        if CLI::COMMANDS.include?(cmd_name)
          print_command_help(cmd_name)
        else
          $stderr.puts("Unknown command: #{cmd_name}")
          print_help
        end
      else
        print_help
      end
    end

    def print_command_help(cmd_name)
      cmd_class = CLI.commands[cmd_name]
      trollop_parser = cmd_class.trollop_parser
      puts cmd_class.usage_line
      puts ""
      trollop_parser.educate($stdout)
    end

    def print_help
      commands = CLI.commands
      puts "Usage: msp_release COMMAND [OPTIONS]"
      puts ""
      puts "Available commands:"
      CLI::COMMANDS.each do |cmd_name|
        puts "  #{cmd_name.ljust(8)} #{commands[cmd_name].description}"
      end
    end
  end
end
