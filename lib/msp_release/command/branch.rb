class MSPRelease::Command::Branch < MSPRelease::Command

  include WorkingCopyCommand

  def self.description
    "Create a release branch for MSP::VERSION"
  end

  def run
    fail_if_push_pending

    unless git.on_master?
      $stderr.puts("You must be on master to create release branches")
      exit 1
    end

    version = project.any_version

    branch_name = project.branch_name(version)

    begin
      MSPRelease::MakeBranch.new(git, branch_name).
        perform!
    rescue MSPRelease::MakeBranch::BranchExistsError => e
      raise MSPRelease::ExitException, "A branch already exists for #{version}"
    end
  end
end
