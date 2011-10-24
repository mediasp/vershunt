require 'spec/helpers'

describe 'MSPRelease::Project' do
  include_context 'project_helpers'

  describe 'reading the project file' do

    it 'can return the status of the project' do
      project = write_project('dev_project', <<YAML
---
:status: :Dev
:changelog_path: debian/changelog
:ruby_version_file: lib/my_project/version.rb
YAML
)

      project.dev?.should be_true

      project = write_project('rc_project', <<YAML
---
:status: :RC
:changelog_path: debian/changelog
:ruby_version_file: lib/my_project/version.rb
YAML
)

      project.rc?.should be_true

      project = write_project('final_project', <<YAML
---
:status: :Final
:changelog_path: debian/changelog
:ruby_version_file: lib/my_project/version.rb
YAML
)

      project.final?.should be_true
    end

  end
end
