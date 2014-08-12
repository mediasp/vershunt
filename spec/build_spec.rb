require 'spec/helpers'

describe 'build' do
  include_context 'project_helpers'

  let :dev_version_regex do
    "([0-9]{14}-git\\+[a-f0-9]{6}~([a-z\.]+))"
  end

  before do
    # change this before you build_init_project
    @deb_exit_code = 0
  end

  describe "no arguments given" do
    it "fails, at least a repository arg is required" do
      run_msp_release "build --verbose"
      last_run.should exit_with(1)
    end
  end

  def build_products
    lines = last_stdout.split("\n")
    if index = lines.index("Build products:")
      # verbose output
      lines[(index + 1)..-1]
    else
      lines
    end
  end

  describe "gem" do
    before do
      init_gem_project('gem_project', {})
    end

    describe "only repository argument given" do
      it "checks out the latest commint from master then builds from it" do
        in_tmp_dir do
          run_msp_release "build --verbose file://#{@remote_repo}"
          last_stdout.should match("Checking out latest commit from origin/master")

          last_run.should exit_with(0)

          package_built_regex =
            /(\/.*\/gem_project-[0-9]+\.[0-9]+\.[0-9]+\.gem)$/

          build_products.count.should == 1
          build_products.any? {|p| p.should match package_built_regex }

          gem_fname = package_built_regex.match(last_stdout)[1]
          File.exists?(gem_fname).should be_true
        end
      end
    end

    describe "in a working directory containing {project_name}_" do
      it 'lets you checkout the latest from master and the builds it' do

        in_tmp_dir 'project_builddir'  do
          run_msp_release "build --verbose file://#{@remote_repo}"

          last_run.should exit_with(0)
          last_stdout.should match("Checking out latest commit from origin/master")

          checked_out_regex = /Checked out to .*vershunt.*\.tmp/
            last_stdout.should match(checked_out_regex)
          package_version = checked_out_regex.match(last_stdout)[1]

          package_built_regex =
            /(\/.*\/gem_project-[0-9]+\.[0-9]+\.[0-9]+\.gem)$/

          last_stdout.should match(package_built_regex)

          gem_fname = package_built_regex.match(last_stdout)[1]
          File.exists?(gem_fname).should be_true
        end
      end
    end
  end

  describe "debian and gem" do
    before do
      build_init_project('project', :gem_project => true)
    end

    it "checks out the latest commit from master then builds from it, giving " +
      "the build a development version string" do

      in_tmp_dir do
        run_msp_release "build --verbose file://#{@remote_repo}"

        last_run.should exit_with(0)
        last_stdout.should match("Checking out latest commit from origin/master")
        version_regex = /Checked out to project\-([0-9]{14}-git\+[a-f0-9]{6}~master)/
          last_stdout.should match(version_regex)

        package_built_regex =
          /\/(project\_#{dev_version_regex}_[a-z0-9]+.changes)$/

          build_products.any? {|f| package_built_regex.match(f)}.should be_true
        build_products.each {|f| File.exists?(f).should be_true }

        package_version = version_regex.match(last_stdout)[1]
        full_package_name = 'project-' + package_version

        File.directory?(full_package_name).should be_true
        Dir.chdir full_package_name do
          run_msp_release 'status'
          last_run.should exit_with(0)
          last_stdout.should include("Changelog says : #{package_version}")
        end
      end
    end
  end

  describe "debian" do
    describe "only repository argument given" do

      before do
        build_init_project('project', {})
      end

      it "checks out the latest commit from master then builds from it, giving " +
        "the build a development version string" do

        in_tmp_dir do
          run_msp_release "build --verbose file://#{@remote_repo}"

          last_run.should exit_with(0)
          last_stdout.should match("Checking out latest commit from origin/master")
          version_regex = /Checked out to project\-([0-9]{14}-git\+[a-f0-9]{6}~master)/
          last_stdout.should match(version_regex)

          package_built_regex =
            /\/(project\_#{dev_version_regex}_[a-z0-9]+.changes)$/

          build_products.any? {|f| package_built_regex.match(f)}.should be_true
          build_products.each {|f| File.exists?(f).should be_true }

          package_version = version_regex.match(last_stdout)[1]
          full_package_name = 'project-' + package_version

          File.directory?(full_package_name).should be_true
          Dir.chdir full_package_name do
            run_msp_release 'status'
            last_run.should exit_with(0)
            last_stdout.should include("Changelog says : #{package_version}")
          end
        end
      end

      it 'lets you specify a different distribution to the one in source control' do
        in_tmp_dir do
          run_msp_release "build --verbose --debian-distribution=tinternet file://#{@remote_repo}"

          last_run.should exit_with(0)
          last_stdout.should match("Checking out latest commit from origin/master")

          checked_out_regex = /Checked out to project\-#{dev_version_regex}/
          last_stdout.should match(checked_out_regex)
          package_version = checked_out_regex.match(last_stdout)[1]

          File.read("project-#{package_version}/debian/changelog").
            first.strip.should ==
            "project (#{package_version}) tinternet; urgency=low"
        end
      end

      describe "in a working directory containing {project_name}_" do
        it 'lets you checkout the latest from master and the builds it' do

          in_tmp_dir 'project_builddir'  do
            run_msp_release "build --verbose file://#{@remote_repo}"

            last_run.should exit_with(0)
            last_stdout.should match("Checking out latest commit from origin/master")

            checked_out_regex = /Checked out to project\-#{dev_version_regex}/
            last_stdout.should match(checked_out_regex)
            package_version = checked_out_regex.match(last_stdout)[1]

            package_built_regex = /\/(project\_#{dev_version_regex}_[a-z0-9]+.changes)/
            last_stdout.should match(package_built_regex)

            changes_fname = package_built_regex.match(last_stdout)[1]
            File.exists?(changes_fname).should be_true
          end
        end
      end
    end

    describe "non-release branch name given" do

      before do
        build_init_project('project', {})

        in_project_dir do
          exec("git checkout -b feature-llama")
          exec("git push origin feature-llama")
          exec("git remote -v")
        end
      end

      it "complains if the branch does not exist" do
        in_tmp_dir do
          run_msp_release "build --verbose  file://#{@remote_repo} feature-alpaca"
          last_run.should exit_with(1)
          last_stderr.should match("Git pathspec 'origin/feature-alpaca' does not exist")
        end
      end

      it "checks out the branch and builds from HEAD, giving the build a spiffy" +
        " development version including the branch info" do
        in_tmp_dir do
          run_msp_release "build --verbose  file://#{@remote_repo} feature-llama"
          last_run.should exit_with(0)
          last_stdout.should match("Checking out latest commit from origin/feature-llama")

          checked_out_regex = /Checked out to project\-#{dev_version_regex}/
          last_stdout.should match(checked_out_regex)
          package_version = checked_out_regex.match(last_stdout)[1]
          branch_part = checked_out_regex.match(last_stdout)[2]

          branch_part.should == 'feature.llama'

          package_built_regex =
            /\/(project\_#{dev_version_regex}_[a-z0-9]+.changes)/
          last_stdout.should match(package_built_regex)

          changes_fname = package_built_regex.match(last_stdout)[1]
          changes_fname.should include("feature.llama")
          File.exists?(changes_fname).should be_true
        end
      end
    end

    describe "release branch name given" do

      before do
        build_init_project('project', {})

        in_project_dir do
          run_msp_release 'branch'
          run_msp_release 'new'
          run_msp_release 'push'
        end
      end

      it "complains if the branch does not exist" do
        in_tmp_dir do
          run_msp_release "build --verbose file://#{@remote_repo} release-2.0"
          last_run.should exit_with(1)
          last_stderr.should match("Git pathspec 'origin/release-2.0' does not exist")
        end
      end

      it "checks out the latest release commit from the branch then builds it" do
        in_tmp_dir do
          run_msp_release "build --verbose file://#{@remote_repo} release-0.0"

          last_run.should exit_with(0)
          last_stdout.should match("Checking out latest release commit from origin/release-0.0")
          last_stdout.should match("Checked out to project-0.0.1-1")

          package_built_regex = /\/(project_0\.0\.1\-1_[a-z0-9]+\.changes)/
          last_stdout.should match(package_built_regex)

          changes_fname = package_built_regex.match(last_stdout)[1]
          File.exists?(changes_fname).should be_true

          File.directory?('project-0.0.1-1').should be_true
          Dir.chdir 'project-0.0.1-1' do
            run_msp_release 'status'
            last_stdout.should match('^Release commit : 0.0.1-1')
            last_stdout.should match('^Release branch : 0.0')
          end
        end
      end
    end

    describe "shallow clone" do
      before do
        build_init_project('project', {:deb =>
            {:build_command => "dpkg-buildpackage -us -uc"}})

        in_project_dir do
          # Create enough commits so that the first one will not show up in a
          # shallow clone
          (0..6).each do |iter|
            exec("echo change >> dummy_file")
            exec("git add dummy_file")
            exec("git commit -m 'change #{iter}'")

          end
          exec("git push origin master")
        end
      end

      it "will checkout the repository with short history (the default)" do
        in_tmp_dir do
          run_msp_release "build --verbose file://#{@remote_repo}"
          last_run.should exit_with(0)
          last_stdout.should match("^Checking out latest commit from origin/master \\(shallow\\)$")
          version_regex = /Checked out to project\-([0-9]{14}-git\+[a-f0-9]{6}~master)/
          last_stdout.should match(version_regex)

          package_version = version_regex.match(last_stdout)[1]
          full_package_name = 'project-' + package_version

          File.directory?(full_package_name).should be_true
          Dir.chdir full_package_name do
            run_msp_release 'status'
            last_run.should exit_with(0)
            last_stdout.should include("Changelog says : #{package_version}")
            exec("git log")
            last_stdout.should match("change 6")
            last_stdout.should_not match("change 0")
          end
        end

      end

      it "can checkout the repository with full history" do
        in_tmp_dir do
          run_msp_release "build --verbose --no-shallow file://#{@remote_repo}"
          last_run.should exit_with(0)
          last_stdout.should match("^Checking out latest commit from origin/master$")
          version_regex = /Checked out to project\-([0-9]{14}-git\+[a-f0-9]{6}~master)/
          last_stdout.should match(version_regex)

          package_version = version_regex.match(last_stdout)[1]
          full_package_name = 'project-' + package_version

          File.directory?(full_package_name).should be_true
          Dir.chdir full_package_name do
            run_msp_release 'status'
            last_run.should exit_with(0)
            last_stdout.should include("Changelog says : #{package_version}")
            exec("git log")
            last_stdout.should match("change 6")
            last_stdout.should match("change 0")
          end
        end

      end

    end
  end

  describe "distribution option" do
  end

  describe "noise levels" do

    before do
      build_init_project('project', {})
    end

    it "defaults to being quiet-ish" do

      in_tmp_dir do
        run_msp_release "build file://#{@remote_repo}"
        last_run.should exit_with(0)

        lines = last_stdout.split("\n")
        lines.length.should == ["deb", "changes", "source tar", "dsc"].length
      end
    end

    it "can be told to shut right up" do
      in_tmp_dir do
        run_msp_release "build --silent file://#{@remote_repo}"
        last_run.should exit_with(0)

        lines = last_stdout.strip.should == ""
      end
    end

    it "will print some helpful output to stdout if you give --verbose" do
      in_tmp_dir do
        run_msp_release "build --verbose file://#{@remote_repo}"
        last_run.should exit_with(0)

        last_stdout.should match("Checking out latest commit from origin/master")
        build_products.length.should == ["deb", "changes", "source tar", "dsc"].length
      end
    end

    it "will print dpkg-buildpackage output to stderr if specified" do
      in_tmp_dir do
        run_msp_release "build --noisy file://#{@remote_repo}"
        last_run.should exit_with(0)

        lines = last_stdout.split("\n")
        lines.length.should == ["deb", "changes", "source tar", "dsc"].length

        last_stderr.strip.should_not == ""
        last_stderr.should include("dpkg-buildpackage: source package project")
      end
    end
  end

end
