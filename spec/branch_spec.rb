require 'spec/helpers'

describe 'branch' do

  include_examples 'project_helpers'

  before do
    init_project('project', {:ruby_version_file => nil,
        :version => '0.1.0'})
  end

  describe 'on master' do

    it 'will create a release branch automatically bumping the minor' +
      'version on master and pushing it behind the release branch' do

      in_project_dir do
        run_msp_release 'branch'
        last_run.should exit_with(0)
        last_stdout.should match('Bumping master to 0.2.0, pushing to origin...')
        last_stdout.should match("Switched to release branch 'release-0.1.0'")
        release_branch_should_match('0.1.0')

        exec "git checkout master"
        project_version_should_match('0.2.0')
        exec "git --no-pager log -1"
        last_stdout.should match("BUMPED VERSION TO 0.2.0")

        exec "git --no-pager log -1 origin/master"
        last_stdout.should match("BUMPED VERSION TO 0.2.0")
      end
    end

    it 'will fail to create a release branch if pushing the new ' +
      'minor version on master to origin would fail' do
      in_project_dir do
        # this pushes a commit to origin/master so that it is one commit ahead
        # of the local master
        exec "echo cats > cats.log"
        exec "git add cats.log"
        exec "git commit -m 'new cats'"
        exec "git push origin master"
        exec "git reset --hard HEAD@{1}"

        run_msp_release 'branch'
        last_run.should exit_with(1)
        last_stderr.should match('could not push bump commit to master')
        last_stderr.should match('try again with --no-bump-master')

        release_branch_should_match('<none>')

        proc { exec "git checkout release-0.1.0" }.should raise_error
        proc { exec "git checkout origin/release-0.1.0" }.should raise_error
      end
    end

    it 'will create a release branch from master without bumping the minor ' +
      'version on master if you pass --no-bump-master' do
      in_project_dir do
        run_msp_release 'branch --no-bump-master'
        last_run.should exit_with(0)
        release_branch_should_match('0.1.0')

        exec "git checkout master"
        project_version_should_match('0.1.0')
        exec "git --no-pager log -1"
        last_stdout.should_not match("BUMPED VERSION TO 0.2.0")

        exec "git --no-pager log -1 origin/master"
        last_stdout.should_not match("BUMPED VERSION TO 0.2.0")
      end

    end

    it 'will fail if you try to create a release branch not on master' do
      in_project_dir do
        exec "git branch ovum"
        exec "git checkout ovum"

        run_msp_release 'branch'
        last_run.should exit_with(1)
        last_stderr.should match("You must be on master to create release branches")
        last_stderr.should match("or pass --allow-non-master-branch")

        release_branch_should_match('<none>')
      end
    end

    it 'will create a release branch from a branch other than master if you ' +
      'pass --allow-non-master-branch, but it will not bump the version from' +
      ' your original branch' do
      in_project_dir do
        exec "git branch ovum"
        exec "git checkout ovum"

        run_msp_release 'branch --allow-non-master-branch'
        last_run.should exit_with(0)
        last_stderr.should match("Creating a non-master release branch")

        release_branch_should_match('0.1.0')

        # check it did not mess with original branch
        exec "git checkout ovum"
        release_branch_should_match('<none>')
        exec "git show"
        last_stdout.should_not match("BUMPED VERSION")
      end
    end

  end

end
