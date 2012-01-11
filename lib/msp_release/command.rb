module MSPRelease
  class Command

    module WorkingCopyCommand

      include Helpers

      attr_accessor :project, :git

      def initialize(options, leftovers)
        super

        if File.exists?(PROJECT_FILE)
          @project = MSPRelease::Project.new(PROJECT_FILE)
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
      @arguments = arguments
    end

    attr_accessor :options, :arguments
  end
end
