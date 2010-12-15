class MSPRelease::Promote < MSPRelease::Command

  include MSPRelease::Project::Status
  include MSPRelease::Exec

  def self.description
    "Promote the status of the project at its current version"
  end

  def run
    if project.status == :Final
      $stderr.puts "This version is already final, perhaps you want to bump?"
      exit 1
#    elsif Git.remote_is_ahead?
#      $stderr.puts "Your branch is lagging behind.  Please rebase and try again."
#      exit 1
else
      old_status = project.status
      project.status = project.next_status
      new_status = project.status
      exec "git add #{project.config_file}"
      exec "git commit -m 'PROMOTE VERSION #{project.any_version} to #{project.status}'"
      puts "Project status #{old_status}=>#{new_status}"
    end
  end
end
