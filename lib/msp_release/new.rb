class MSPRelease::New < MSPRelease::Command

  def self.description
    "Prepare master or a release branch for a release push"
  end

  def run
    fail_if_push_pending
    fail_if_modified_wc

    opts = OptionParser.new do |opts|
      opts.on("--final", TrueClass, "Mark this release as final") do |n|
        options[:final] = true
      end
      opts.on("--rc=NUM", Integer, "Force move to RC stage") do |n|
        options[:rc] = n
      end
    end
    opts.parse(arguments)

    if on_release_branch?
      release_from_branch(options)
    else
      release_from_master(options)
    end
  end

  def release_from_branch(options)
    deb_version, suffix = changelog.version_and_suffix

    if msp_version != git_version
      $stderr.puts("Error: MSP::Version shows #{msp_version.format}, but git branch says #{git_version.format}")
      exit 1
    end

    next_rc_number =
      if options[:final]
        nil
      elsif suffix == 'final'
        $stderr.puts("Managing bug fix releases not yet implemented")
        exit 1
      elsif /[0-9]{14}$/.match(suffix) || options[:rc]
        options[:rc] || 1
      elsif match = /rc([0-9]+)$/.match(suffix)
        match[1].to_i + 1
      else
        $stderr.puts("Error: Can't recognise changelog suffix: #{suffix}")
        exit 1
      end

    suffix, blurb =
      next_rc_number ? ["rc#{next_rc_number}", "New release candidate"] :
      ['final', "Final release"]

    changelog.add(msp_version, blurb, suffix)
    self.data = {:version => msp_version, :suffix => suffix}
    save_data


    puts_changelog_info
  end

  def release_from_master(options)
    timestamp
    msp_version

    version, suffix = if changelog.matches(msp_version)
      puts "Amending changelog..."
      changelog.amend(msp_version)
    else
      puts "Adding new dev entry to changelog..."
      changelog.add(msp_version, "New dev version")
    end

    self.data = {:version => version, :suffix => suffix}
    save_data

    puts_changelog_info
  end

end
