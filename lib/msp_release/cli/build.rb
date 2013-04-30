module MSPRelease
  class CLI::Build < CLI::Command
    include Debian::Versions

    # When cloning repositories, limit to this many commits from each head
    CLONE_DEPTH = 5

    description """Build debian packages suitable for deployment fresh from
source control using a build commit or a development version.

When no BRANCH_NAME is given, or that branch is not a release branch, the
latest commit from that branch is checked out and the changelog version is
adjusted to show this is a development build.

If BRANCH_NAME denotes a release branch (i.e release-1.1) then the latest
/release/ commit is checked out, even if there are commits after it.
The changelog remains unaltered in this case - the source tree should have
the correct version information in it.
"""

    arg :git_url, "URL used to clone the git repository"

    arg :branch_name, "Name of a branch to build from, defaults to ${default}",
    :default => "master"

    opt :sign, "Pass options to dpkg-buildpackage to tell it whether or not to sign the build products",
    {
      :short => 'S',
      :default => false
    }

    opt :shallow, "Only perform a shallow checkout to a depth of five" +
      "commits from each head.  See git documentation for more details",
    {
      :short   => 's',
      :default => true
    }

    opt :distribution, "Specify the debian distribution to put in the " +
      "changelog when checking out a development version",
    {
      :short => 'd',
      :long  => 'debian-distribution',
      :type  => :string
    }

    opt :verbose, "Print some useful debugging output to stdout",
    {
      :long => 'verbose',
      :short => 'v', :default => false
    }

    opt :noisy, "Output dpkg-buildpackage output to stderr",
    {
      :short => 'n', :default => false
    }

    opt :silent, "Do not print out build products to stdout", {
      :default => false
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
        log("Checking out latest release commit from #{pathspec}#{shallow_output}")
      else
        log("Checking out latest commit from #{pathspec}#{shallow_output}")
      end

      tmp_dir = "vershunt-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:depth => clone_depth, :out_to => tmp_dir,
                :no_single_branch => true, :exec => {:quiet => true}})

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
            raise CLI::Exit, "Could not find a release commit on #{pathspec}"
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
      log("Checked out to #{src_dir}")

      log("Building package...")
      out = options[:noisy] ? stderr : StringIO.new
      build = Build.new(src_dir, project, :out => out, :sign => options[:sign])

      result = build.perform_from_cli!
      log("Build products:")
      result.files.each {|f| stdout.puts(f) } unless options[:silent]
    end

    private

    def log(message)
      stdout.puts(message) if options[:verbose]
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
          raise CLI::Exit, "Git pathspec '#{pathspec}' does not exist"
        else
          raise
        end
      end

      exec("git checkout --track #{pathspec}")
    end

  end
end
