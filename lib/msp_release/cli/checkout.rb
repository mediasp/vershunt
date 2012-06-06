require 'fileutils'

module MSPRelease
  class CLI::Checkout < CLI::Command
    include Debian::Versions

    # When cloning repositories, limit to this many commits from each head
    CLONE_DEPTH = 5

    def self.description
      "Checkout a specific commit from a git repository suitable for building"
    end

    cli_argument :git_url, "URL used to clone the git repository"
    cli_argument :branch_name, "Name of a branch on master to switch to once checked out",
      :required => false

    cli_option :build, "Build a debian package immediately after checking " +
      "out, using the dpkg-buildpackage command",
    {
      :short   => 'b',
      :default => false
    }

    cli_option :tar, "Create a tarfile containing all the debian build " +
      "products when using --build",
    {
      :short   => 't',
      :default => false
    }

    cli_option :shallow, "Only perform a shallow checkout to a depth of five" +
      "commits from each head.  See git documentation for more details",
    {
      :short   => 's',
      :default => false
    }

    cli_option :distribution, "Specify the debian distribution to put in the " +
      "changelog when checking out a development version",
    {
      :short => 'd',
      :long  => 'debian-distribution',
      :type  => :string
    }

    def run
      git_url          = arguments[:git_url]
      release_spec_arg = arguments[:branch_name]

      do_build         = options[:build]
      tar_it           = options[:tar]
      clone_depth      = options[:shallow] ? CLONE_DEPTH : nil

      branch_name = release_spec_arg || 'master'
      pathspec = "origin/#{branch_name}"
      branch_is_release_branch = !! /^release-.+$/.match(branch_name)

      shallow_output = clone_depth.nil?? '' : ' (shallow)'
      if release_spec_arg && branch_is_release_branch
        puts("Checking out latest release commit from #{pathspec}#{shallow_output}")
      else
        puts("Checking out latest commit from #{pathspec}#{shallow_output}")
      end

      tmp_dir = "msp_release-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:depth => clone_depth, :out_to => tmp_dir,
          :exec => {:quiet => true}})

      project = Project.new_from_project_file(tmp_dir + "/" + Helpers::PROJECT_FILE)
      distribution = options[:distribution] || project.changelog.distribution

      src_dir = Dir.chdir(tmp_dir) do

        if pathspec != "origin/master"
          move_to(pathspec)
        end

        if branch_is_release_branch
          first_commit_hash, commit_message =
            find_first_release_commit(project)

          if first_commit_hash.nil?
            raise ExitException, "Could not find a release commit on #{pathspec}"
          end

          exec "git reset --hard #{first_commit_hash}"
        else
          dev_version = Development.
            new_from_working_directory(branch_name, latest_commit_hash)

          project.changelog.amend(dev_version, distribution)
        end
        src_dir = project.source_package_name + "-" + project.changelog.version.to_s
      end

      FileUtils.mv(tmp_dir, src_dir)
      project = Project.new_from_project_file(src_dir + "/" + Helpers::PROJECT_FILE)
      $stdout.puts("Checked out to #{src_dir}")

      if do_build
        $stdout.puts("Building package...")
        build = Build.new(src_dir, project)

        result =
          begin
            result = build.perform!
          rescue Build::NoChangesFileError => e
            raise ExitException.new(
            "Unable to find changes file with version: #{e.message}\n" +
            "Available: \n" +
            build.available_changes_files.map { |f| "  #{f}" }.join("\n"))
          end

        $stdout.puts("Package built: #{result.changes_file}")
        tar_it_up(project, result) if tar_it
      end
    end

    private

    def tar_it_up(project, result)
      changes = File.read(result.changes_file).split("\n")
      files_start = changes.index {|l| /^Files: $/.match(l) } + 1
      files = changes[files_start..-1].map {|l| l.split(" ").last } +
        [result.changes_file]

      tarfile = "#{project.source_package_name}-#{project.changelog.version}.tar"
      exec("tar -cf #{tarfile} #{files.join(' ')}")
      $stdout.puts("Build products archived in to #{tarfile}")
    end

    def oneline_pattern
      /^([a-z0-9]+) (.+)$/i
    end

    def log_command
      "git --no-pager log --no-color --full-index"
    end

    def latest_commit_hash
      output = exec(log_command + " --pretty=oneline -1").split("\n").first
      oneline_pattern.match(output)[1]
    end

    def find_first_release_commit(project)
      all_commits = exec(log_command +  " --pretty=oneline").
        split("\n")

      all_commits.map { |commit_line|
        match = oneline_pattern.match(commit_line)
        [match[1], match[2]]
      }.find {|hash, message|
        project.release_name_from_message(message)
      }
    end

    def move_to(pathspec)
      begin
        exec("git show #{pathspec} --")
      rescue Exec::UnexpectedExitStatus => e
        if /^fatal: bad revision/.match(e.stderr)
          raise ExitException, "Git pathspec '#{pathspec}' does not exist"
        else
          raise
        end
      end

      exec("git checkout --track #{pathspec}")
    end
  end

end
