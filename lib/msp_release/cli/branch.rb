module MSPRelease
  class CLI::Branch < CLI::Command
    include CLI::WorkingCopyCommand

    def self.description
      "Create and switch to a release branch for the version on HEAD"
    end

    cli_option :allow_non_master_branch, "Allow release branch to be created " +
      "even if you are not on master.  Normally you would not want to do" +
      " this, so this is here to prevent branches from mistakenly being " +
      "created from branches other than master",
    {
      :short => 'a',
      :default => false
    }


    cli_option :no_bump_master, "Do not bump the minor version of master " +
      "as part of creating the release branch.  Typically after creating a " +
      "release branch, the minor version being stabilised now lives on the " +
      "branch and master is now a new version",
    {
      :short => 'n',
      :default => false
    }

    def run
      fail_if_push_pending

      # take the version before we do any bumping
      version = project.any_version

      branch_from =
        if git.on_master?
          bump_and_push_master
        else
          check_branching_ok!
        end

      branch_name = project.branch_name(version)

      begin
        MSPRelease::MakeBranch.new(git, branch_name, :start_point => branch_from).
          perform!
      rescue MSPRelease::MakeBranch::BranchExistsError => e
        raise MSPRelease::ExitException, "A branch already exists for #{version}"
      end

      $stdout.puts("Switched to release branch '#{branch_name}'")
    end

    def check_branching_ok!
      if options[:allow_non_master_branch]
        $stderr.puts("Creating a non-master release branch, --allow-non-master-branch supplied")
        "HEAD@{0}"
      else
        raise MSPRelease::ExitException, "You must be on master to create " +
          "release branches, or pass --allow-non-master-branch"
      end
    end

    def bump_and_push_master

      return "HEAD@{0}" if options[:no_bump_master]

      # don't let this happen with a dirty working copy, because we reset the
      # master branch, which will kill all your changes
      fail_if_modified_wc

      new_version, *changed_files = project.bump_version('minor')
      exec "git add -- #{changed_files.join(' ')}"

      # FIXME dry this part up, perhaps using a bump operation class
      exec "git commit -m 'BUMPED VERSION TO #{new_version}'"

      begin
        $stdout.puts "Bumping master to #{new_version}, pushing to origin..."
        exec "git push origin master"
      rescue
        $stderr.puts "error pushing bump commit to master, undoing bump..."
        exec "git reset --hard HEAD@{1}"
        raise MSPRelease::ExitException, 'could not push bump commit to master, if you do ' +
          'not want to bump the minor version of master, try again with ' +
          '--no-bump-master'
      end

      "HEAD@{1}"
    end
  end
end
