module MSPRelease
  module CLI

    # Base class for command line operations
    class Command < Climate::Command
      include Exec::Helpers
    end

    # alias this class for shorter lines
    Exit = Climate::ExitException

    # root of the command hierarchy
    class Root < Climate::Command('vershunt')

      description """
Manipulate your git repository by creating commits and performing
branch management to create a consistent log of commits to be used
as part of a repeatable build system, as well as encouraging
semantic versioning (see http://semver.org).

Projects must include a .msp_project, which is a yaml file that must at least
not be empty.  If the project file has a ruby_version_file key, then this
file will be considered as well as the debian changelog when updating version
information.
"""

    end

    # Commands that require a git working copy can include this module
    module WorkingCopyCommand

      include Helpers

      attr_accessor :project, :git

      def initialize(options, leftovers)
        super

        if File.exists?(PROJECT_FILE)
          @project = MSPRelease::Project.new_from_project_file(PROJECT_FILE)
        else
          raise Climate::ExitException.
            new("No #{PROJECT_FILE} present in current directory")
        end

        @git = Git.new(@project, @options)
      end

    end

    # hardcoded list of commands
    COMMANDS = ['help', 'new', 'push', 'branch', 'status', 'reset', 'bump', 'checkout', 'build']

    # These are available on the CLI module
    module ClassMethods

      attr_reader :commands

      def run(args)
        init_commands

        Climate.with_standard_exception_handling do
          begin
            Root.run(args)
          rescue Exec::UnexpectedExitStatus => e
            $stderr.puts(e.message)
            $stderr.puts(e.stderr)
            exit 1
          end
        end
      end

      def init_commands
        @commands = {}
        COMMANDS.each do |name|
          require "msp_release/cli/#{name}"
          camel_name =
            name.split(/[^a-z0-9]/i).map{|w| w.capitalize}.join

          command = MSPRelease::CLI.const_get(camel_name)
          @commands[name] = command
          command.set_name(name)
          command.subcommand_of(Root)
        end
      end
    end

    self.extend(ClassMethods)
  end
end
