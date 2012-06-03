module MSPRelease
  class MakeBranch

    class BranchExistsError < StandardError ; end

    include Exec::Helpers

    attr_reader :branch_name
    attr_reader :git

    def initialize(git, branch_name)
      @git = git
      @branch_name = branch_name
    end

    def perform!
      if git.branch_exists?(branch_name)
        raise BranchExistsError, branch_name
      end

      git.create_and_switch(branch_name)
    end
  end


end
