module MSPRelease::Project

  def self.new_from_project_file(filename)
    config = YAML.load_file(filename)
    dirname = File.expand_path(File.dirname(filename))

    project = Base.new(filename, dirname)

    # TODO: make it so that this doesn't have to know about all the possible
    # mixins.

    # If the directory has a debian folder, treat it as a debian project.
    if File.directory?(File.join(dirname, 'debian'))
      project.extend(Debian)
    elsif Dir.glob("#{dirname}/*.gemspec").count > 0
      project.extend(Gem)
      # If its a gem project, it must also be a ruby project.
      project.extend(Ruby)
    end

    # If there is a ruby version file, we treat it as a
    if config[:ruby_version_file]
      project.extend(Ruby)
    end

    # Git project
    if File.directory?(File.join(dirname, '.git'))
      project.extend(Git)
    end

    project
  end

end

require 'msp_release/project/base'
require 'msp_release/project/ruby'
require 'msp_release/project/debian'
require 'msp_release/project/gem'
require 'msp_release/project/git'

