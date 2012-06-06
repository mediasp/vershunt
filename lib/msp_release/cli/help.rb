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
      puts wrap <<-STR
Manipulate your git repository by creating commits and performing
branch management to create a consistent log of commits to be used
as part of a repeatable build system, as well as encouraging
semantic versioning (see http://semver.org).
STR
      puts ""
      puts wrap <<-STR
Projects must include a .msp_project, which is a yaml file that must at least
not be empty.  If the project file has a ruby_version_file key, then this
file will be considered as well as the debian changelog when updating version
information.
STR
      puts ""
      puts "Available commands:"
      CLI::COMMANDS.each do |cmd_name|
        puts "  #{cmd_name.ljust(8)} #{commands[cmd_name].description}"
      end
      puts ""
      puts "run msp_release help COMMAND for help on a specific command"
    end

    def wrap(string)
      width = (ENV['COLUMNS'] || 80).to_i
      words = string.split(" ")

      words[1..-1].inject([words.first]) { |m, v|
        new_last_line = m.last + " " + v

        if new_last_line.length <= width
          m[0...-1] + [new_last_line]
        else
          m + [v]
        end
      }.join("\n")
    end
  end
end
