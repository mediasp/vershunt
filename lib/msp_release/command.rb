module MSPRelease
  class Command

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

    include Exec::Helpers

    def initialize(options, arguments)
      @options = options
      @arguments, @switches = extract_args(arguments)
    end

    def extract_args(arguments)
      arguments.partition {|a| /^[^\-]/.match(a) }
    end

    attr_accessor :options, :arguments, :switches
  end
end
