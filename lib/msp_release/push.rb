class MSPRelease::Push < MSPRelease::Command

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
    exec "git add #{changelog.fname}"
    exec "git commit -m\"RELEASE COMMIT - #{release_name}\""
    exec "git tag release-#{release_name}"
    exec "git push origin release-#{release_name}"

    remove_data
  end

end
