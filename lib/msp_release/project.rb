module MSPRelease::Project

  def self.new_from_project_file(filename)
    config = YAML.load_file(filename)
    dirname = File.expand_path(File.dirname(filename))

    project = Base.new(config, dirname)

    # If the directory has a debian folder, treat it as a debian project.
    if File.directory?(File.join(dirname, 'debian'))
      project.extend(Debian)
    end

    # If there is a gemspec, treat it as a gem project.
    if Dir.glob("#{dirname}/*.gemspec").count > 0
      project.extend(Gem)
    end

    if config[:ruby_version_file]
      project.extend(Ruby)
    end

    project
  end

end

require 'msp_release/project/base'
require 'msp_release/project/ruby'
require 'msp_release/project/debian'
require 'msp_release/project/gem'

