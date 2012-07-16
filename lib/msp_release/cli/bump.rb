module MSPRelease
  class CLI::Bump < CLI::Command

    include CLI::WorkingCopyCommand

    description "Increase the version number of the project"

    arg :segment, "One of major, minor or bugfix"

    opt :force, "Force bumping of version segments other than bugfix " +
      "if you are not on master.  By default, you bump minor and major from" +
      " master, and you bump the bugfix version while on a branch.",
    {
      :short => 'f',
      :default => false
    }

    def run
      segment = arguments[:segment]

      check_bump_allowed!(segment)

      new_version, *changed_files = project.bump_version(segment)

      [project.config_file, *changed_files].each do |file|
        exec "git add #{file}"
      end
      exec "git commit -m 'BUMPED VERSION TO #{new_version}'"
      puts "New version: #{new_version}"
    end

    def check_bump_allowed!(segment)
      force = options[:force]
      not_on_master = !git.on_master?

      if not_on_master && segment != 'bugfix' && ! force
        raise CLI::Exit, "You must be on master to bump the #{segment} version" +
          ", or pass --force if you are sure this is what you want to do"
      end
    end

    def revert_bump(changed_files)
      exec "git checkout -- #{project.config_file} #{changed_files.join(' ')}"
    end

  end
end
