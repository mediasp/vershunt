
module MSPRelease
  module Project::Gem
    include MSPRelease::Exec::Helpers

    class BuildResult
      def initialize(dir, project)
        @dir = dir
        @project = project
      end

      def package
        "#{@dir}/#{@project.gemspec_name}-#{@project.version}.gem"
      end

      def files
        [package]
      end
    end

    def gemspec_file
      files = Dir.glob("#{@dir}/*.gemspec")

      LOG.warn "Warning: more than one gemspec found" if files.count > 1
      raise "Can't find gemspec" if files.count < 0

      files.first
    end

    def gemspec_name
      @gemspec_name ||= Dir.chdir(@dir) do
        File.new(gemspec_file, 'r').readlines.find { |l|
          l =~ /\w+\.name\s*=\s*(['"])(\w+)\1/
        }
        $2
      end
    end

    def name
      gemspec_name
    end

    def next_version_for_release(options={})
      tag = "release-#{version}"
      check_tag = exec("git show-ref --tags #{tag}", :status => [0,1])
      unless check_tag == ""
         LOG.error "Tag #{tag} already exists, you must bump the version before"\
           " the next release"
         exit(1)
      end
      version
    end

    def prepare_for_build(branch_name, options={})
      # new_dir = "#{gemspec_name}"

      # FileUtils.mv(@dir, new_dir)
      # @dir = new_dir

      clean_checkout

      super if defined?(super)
    end

    def build_command
      "gem build #{gemspec_file}"
    end

    def build_result(output_directory)
      BuildResult.new(@dir, self)
    end

  end
end
