module MSPRelease::Git

  include MSPRelease::Exec

  def on_master?
    cur_branch == 'master'
  end

  def cur_branch
    /^\* (.+)$/.match(exec "git branch")[1]
  end

  def branch_exists?(branch_name)
    # use backticks, we don't want an error
    `git show-branch origin/#{branch_name}`
    $? == 0
  end

  def create_and_switch(branch_name)
    exec "git branch #{branch_name}"
    exec "git push origin #{branch_name}"
    exec "git checkout #{branch_name}"
  end

  def added_files
    status_files("new file")
  end

  def modified_files
    status_files("modified")
  end

  def status_files(status)
    output = exec "git status", [0,256]
    pattern = /#{status}: +(.+)$/
    output.split("\n").map {|l| pattern.match(l) }.compact.map{|m|m[1]}
  end

  extend self
end
