module MSPRelease::Git

  include MSPRelease::Exec

  def on_master?
    cur_branch == 'master'
  end

  def cur_branch
    /^\* (.+)$/.match(exec "git branch")[1]
  end

  def branch_exists?(branch_name)
    exec "git show-branch origin/#{branch_name}"
    $? == 0
  end

  def create_and_switch(branch_name)
    exec "git branch #{branch_name}"
    exec "git push origin #{branch_name}"
    exec "git checkout #{branch_name}"
  end

  extend self
end
