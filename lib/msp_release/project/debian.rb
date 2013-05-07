#
# This kind of project stores the version in the debian changelog
#
module MSPRelease
  module Project::Debian

    DEFAULT_PATH = "debian/msp/changelog"

    def write_version(new_version)
      debian_version = Debian::Versions::Unreleased.new_from_version(new_version)
      changelog.add(debian_version, "New version")

      defined?(super) ?
        Array(super).push(changelog.fname) :
        [ruby_version_file]
    end

    def version
      changelog.version.to_version
    end

    def changelog_path
      @changelog_path || 'debian/changelog'
    end

    def source_package_name
      debian_dir = File.dirname(File.join(@dir, changelog_path))
      control_file = File.join(debian_dir + '/control')
      source_line = MSPRelease::Exec.exec("grep Source: #{control_file}")
      match = /^Source: (.+)$/.match(source_line)
      match && match[1]
    end

    def name
      source_package_name
    end

    def changelog
      Debian.new(@dir, changelog_path)
    end

    def next_version_for_release(options = {})
      deb_version = changelog.version
      distribution = options[:distribution] || changelog.distribution

      new_version =
        if deb_version.to_version != version
          LOG.warn "Warning: project version (#{version.to_s}) " +
            "did not match changelog version (#{deb_version.to_s}), project " +
              "version wins"
          changelog.reset_at(version)
        else
          deb_version.bump
        end

      LOG.debug "Adding new entry to changelog..."
      changelog.add(new_version, "New release", distribution)

      LOG.debug "Changelog now at #{new_version}"
      puts_changelog_info

      new_version
    end

    def puts_changelog_info
      LOG.debug "OK, please update the change log, then run 'vershunt push' to"\
        " push your changes for building"
    end

    def project_specific_push(release_name)
      # Create a release commit.
      commit_message = release_commit_message(release_name)
      exec "git add #{changelog.fname}"
      exec "git commit -m\"#{commit_message}\""
    end

    def prepare_for_build(branch_name, options={})
      branch_is_release_branch = !! /^release-.+$/.match(branch_name)
      distribution = options[:distribution] || changelog.distribution

      rename_dir_for_build(branch_name, distribution)

      super if defined?(super)
    end

    def rename_dir_for_build(branch_name, distribution)
      branch_is_release_branch = !! /^release-.+$/.match(branch_name)
      new_dir = Dir.chdir(@dir) do
        if branch_is_release_branch
          first_commit_hash, commit_message =
            find_first_release_commit

          if first_commit_hash.nil?
            raise CLI::Exit, "Could not find a release commit on #{pathspec}"
          end

          clean_checkout
        else
          dev_version = Debian::Versions::Development.
            new_from_working_directory(branch_name, latest_commit_hash)

          changelog.amend(dev_version, distribution)
        end
        name + "-" + changelog.version.to_s
      end
      FileUtils.mv(@dir, new_dir)
      @dir = new_dir
    end

    def build(options={})
      LOG.debug("Checked out to #{@dir}")

      LOG.debug("Building package...")
      build = Build.new(@dir, self, :output_to_stderr => !!options[:noisy], :sign => options[:sign])

      result = build.perform_from_cli!
      LOG.debug("Build products:")
      result.files.each {|f| LOG.info(f) }
    end

  end

end
