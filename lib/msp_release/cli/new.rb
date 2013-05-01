module MSPRelease
  class CLI::New < CLI::Command

    include CLI::WorkingCopyCommand

    description "Prepare master or a release branch for a release push"

    opt :distribution, "Specify a new debian distribution to put in the " +
      "changelog for this new version",
    {
      :short => 'd',
      :long  => 'debian-distribution',
      :type  => :string
    }

    opt :force, "Force creation of a release commit from a non-release branch", {
      :short   => 'f',
      :long    => 'force',
      :default => false
    }

    def run
      fail_if_push_pending
      fail_if_modified_wc
      fail_unless_on_release_branch

      new_version = project.next_version_for_release(options)

      self.data = {:version => new_version}
      save_data
    end

    def not_on_release_branch_msg
      "You must be on a release branch to create " +
      "release commits, or use --force.\nSwitch to a release branch, or build " +
      "from any branch without creating a release commit for development builds"
    end

    def fail_unless_on_release_branch
      if git.cur_branch != project.branch_name
        if options[:force]
          stderr.puts("Not on a release branch, forcing creation of release " +
            "commit.  #{git.cur_branch} != #{project.branch_name}")
        else
          raise CLI::Exit, not_on_release_branch_msg
        end
      end
    end

    def get_next_release_number(suffix)
      suffix_pattern = /([0-9]+)/
      if suffix.nil? || suffix_pattern.match(suffix)
        suffix.to_i + 1
      else
        raise CLI::Exit, "malformed suffix: #{suffix}\n" +
          "Fix the changelog and try again"
      end
    end
  end
end
