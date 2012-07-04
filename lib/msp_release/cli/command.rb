require 'climate'

module MSPRelease
  class CLI::Command < Climate::Command

    # Base class for command line operations
    include Exec::Helpers

  end
end
