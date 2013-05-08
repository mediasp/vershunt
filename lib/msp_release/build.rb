module MSPRelease
  class Build

    class NoChangesFileError < StandardError ; end

    include Exec::Helpers

    def initialize(basedir, project, options={})
      @basedir = basedir
      @project = project
      @options = options

      @sign = options.fetch(:sign, true)
    end

    def perform_from_cli!
      LOG.debug("Building package...")

      result =
        begin
          self.perform!
        rescue Exec::UnexpectedExitStatus => e
          raise CLI::Exit, "build failed:\n#{e.stderr}"
        rescue Build::NoChangesFileError => e
          raise CLI::Exit, "Unable to find changes file with version: " +
            "#{e.message}\nAvailable: \n" +
            self.available_changes_files.map { |f| "  #{f}" }.join("\n")
        end

      result.tap do
        LOG.debug("Package built: #{result.package}")
      end
    end

    def perform!
      dir = File.expand_path(@basedir)
      raise "directory does not exist: #{dir}" unless
        File.directory?(dir)

      e = Exec.new(:name => 'build', :quiet => false, :status => :any)
      Dir.chdir(@project.dir) do
        e.exec(build_command)
      end

      if e.last_exitstatus != 0
        LOG.warn("Warning: #{build_command} exited with #{e.last_exitstatus}")
      end

      @project.build_result(output_directory)
    end

    def output_directory
      File.expand_path(@project.config[:deb_output_directory] ||
        File.join(@basedir, '..'))
    end

    private

    def build_command
      @project.build_command
    end

  end
end
