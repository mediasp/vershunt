module MSPRelease
  module CLI

    require 'trollop'
    require 'msp_release/cli/command'

    # Commands that require a git working copy can include this module
    module WorkingCopyCommand

      include Helpers

      attr_accessor :project, :git

      def initialize(options, leftovers)
        super

        if File.exists?(PROJECT_FILE)
          @project = MSPRelease::Project.new_from_project_file(PROJECT_FILE)
        else
          raise ExitException.
            new("No #{PROJECT_FILE} present in current directory")
        end

        @git = Git.new(@project, @options)
      end

    end

    # hardcoded list of commands
    COMMANDS = ['help', 'new', 'push', 'branch', 'status', 'reset', 'bump', 'checkout']

    # These are available on the CLI module
    module ClassMethods

      attr_reader :commands

      def extract_global_args(args)
        command_index = args.index {|a| /^[^\-]/.match(a) } || 0
        [args[0...command_index], args[command_index], args[command_index+1..-1]]
      end

      def run(args)
        init_commands
        # TODO there aren't any global options yet, so get rid?
        global_args, cmd_name, command_args = extract_global_args(args)
        options, leftovers = MSPRelease::Options.get(global_args)

        cmd = @commands[cmd_name]

        unless cmd
          $stderr.puts("Unknown command: #{cmd_name}")
          cmd = @commands['help']
          command_args = []
        end

        begin
          cmd.new(options, command_args).run
        rescue ExitException => e
          $stderr.puts("Command failed: #{e.message}")
          exit e.exitstatus
        rescue Exec::UnexpectedExitStatus => e
          $stderr.puts("Command failed")
          $stderr.puts("  '#{e.command}' exited with #{e.exitstatus}:")
          $stderr.puts(e.stderr)
          exit 1
        end
      end

      def init_commands
        @commands = {}
        COMMANDS.each do |name|
          require "msp_release/cli/#{name}"
          camel_name =
            name.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join
          @commands[name] = MSPRelease::CLI.const_get(camel_name)
        end
      end
    end

    self.extend(ClassMethods)
  end
end
