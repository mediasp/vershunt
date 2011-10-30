class MSPRelease::Command::Push < MSPRelease::Command

  include MSPRelease::Helpers
  include MSPRelease::Exec


  def self.description
    "Push a new release to origin"
  end

  def run
    unless data_exists?
      $stderr.puts("You need to stage a new release before you can push it")
      exit 1
    end

    load_data
    release_name = "#{data[:version].format}-#{data[:suffix]}"
    tagname = "release-#{release_name}"

    commit_message = project.release_commit_message(release_name)
    exec "git add #{changelog.fname}"
    exec "git commit -m\"#{commit_message}\""
    exec "git tag #{tagname}"
    exec "git push origin #{git.cur_branch}"
    $stdout.puts "Pushing new release tag: #{tagname}"
    exec "git push origin #{tagname}"

    remove_data
  end

end
