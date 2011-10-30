class MSPRelease::Command::Branch < MSPRelease::Command

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

    branch_name = "release-#{version.format}"

    if git.branch_exists?(branch_name)
      puts "A branch for #{version} already exists"
      exit 1
    end

    git.create_and_switch(branch_name)
  end
end
