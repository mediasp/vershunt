module MSPRelease
  class Command
    include Helpers
    include Exec::Helpers

    def initialize(project, options, arguments)
      @project = project
      @options = options
      @git = Git.new(@project, @options)
      @arguments = arguments
    end

    attr_accessor :options, :arguments, :project, :git
  end
end
