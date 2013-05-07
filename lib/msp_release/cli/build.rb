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

      LOG.silent if options[:silent]
      LOG.verbose if options[:verbose]
      LOG.noisy if options[:noisy]

      branch_name = release_spec_arg || 'master'

      shallow_output = clone_depth.nil?? '' : ' (shallow)'

      options[:shallow_output] = shallow_output

      # checkout project
      tmp_dir = "vershunt-#{Time.now.to_i}.tmp"
      Git.clone(git_url, {:depth => clone_depth, :out_to => tmp_dir,
                :no_single_branch => true, :exec => {:quiet => true}})

      project = Project.new_from_project_file(tmp_dir + "/" + Helpers::PROJECT_FILE)

      project.prepare_for_build(branch_name, options)

      if project.respond_to?(:build)
        project.build(options)
      else
        raise "I don't know how to build this project"
      end

    end

  end
end
