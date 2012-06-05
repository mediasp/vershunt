module MSPRelease
  class MakeBranch

    class BranchExistsError < StandardError ; end

    include Exec::Helpers

    attr_reader :branch_name
    attr_reader :git
    attr_reader :options

    def initialize(git, branch_name, options={})
      @git = git
      @branch_name = branch_name
      @options = options
    end

    def perform!
      if git.branch_exists?(branch_name)
        raise BranchExistsError, branch_name
      end

      git.create_and_switch(branch_name,
        :start_point => options[:start_point])
    end
  end


end
