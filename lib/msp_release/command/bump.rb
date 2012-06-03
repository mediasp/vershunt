class MSPRelease::Command::Bump < MSPRelease::Command

  include WorkingCopyCommand

  def self.description
    "Increase the version number of the project"
  end

  def run
    segment = arguments.last

    check_bump_allowed!(segment)

    new_version, *changed_files = project.bump_version(segment)

    perform_branch_if_bump_bugfix(segment, new_version, changed_files)

    [project.config_file, *changed_files].each do |file|
      exec "git add #{file}"
    end
    exec "git commit -m 'BUMPED VERSION TO #{new_version}'"
    puts "New version: #{new_version}"
  end

  def check_bump_allowed!(segment)
    force = switches.include?('--force')
    not_on_master = !git.on_master?

    if not_on_master && segment != 'bugfix' && ! force
      raise MSPRelease::ExitException, "You must be on master to bump " +
        "the #{segment} version, or pass --force if you are sure this is " +
        "what you want to do"
    end
  end

  def perform_branch_if_bump_bugfix(segment, new_version, changed_files)
    do_branch = ! switches.include?('--no-branch')
    on_branch = on_release_branch?

    if on_branch && segment == 'bugfix' && do_branch
      branch_name = project.branch_name(new_version)
      begin
        puts "Making and switching to release branch: #{branch_name}"
        MSPRelease::MakeBranch.new(git, branch_name).perform!
      rescue MSPRelease::MakeBranch::BranchExistsError => e
        revert_bump
        raise MSPRelease::ExitException, "Can't bump to #{new_version}, a release branch already exists for this version.  If you are sure this is what you want to do, pass --no-branch to bump without creating a new release branch"
      end
    end
  end

  def revert_bump(changed_files)
    exec "git checkout -- #{project.config_file} #{changed_files.join(' ')}"
  end

end
