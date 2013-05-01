module MSPRelease
  class CLI::Push < CLI::Command

    include CLI::WorkingCopyCommand

    description "Push a new release to origin"

    def run
      unless data_exists?
        raise CLI::Exit, "You need to stage a new release before you can push it"
      end

      load_data
      release_name = "#{data[:version]}"
      tagname = "release-#{release_name}"

      if project.respond_to?(:project_specific_push)
        project.project_specific_push(release_name)
      end

      exec "git tag #{tagname}"
      exec "git push origin #{git.cur_branch}"
      stdout.puts "Pushing new release tag: #{tagname}"
      exec "git push origin #{tagname}"

      remove_data
    end
  end
end
