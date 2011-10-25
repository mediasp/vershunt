module MSPRelease
  class Command
    include Helpers
    include Exec

    Git = MSPRelease::Git

    def initialize(project, options, arguments)
      @project = project
      @options = options
      @arguments = arguments
    end

    attr_accessor :options, :arguments, :project
  end
end
