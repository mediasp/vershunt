require 'spec/helpers'
require 'stringio'

describe "MSPRelease::Exec" do

  let(:exec_output) { StringIO.new }

  def exec(command, options={})
    exec_output.string = ''
    options[:output] ||= exec_output
    options[:quiet] = false unless options.has_key? :quiet
    MSPRelease::Exec.exec(command, options)
  end

  it 'can return the output' do
    exec('echo hi').should == "hi\n"
    exec_output.string.should == "hi\n"
    exec('echo "cat\ndog"').should == "cat\ndog\n"
    exec_output.string.should == "cat\ndog\n"
  end

  it 'will not output anything if quiet is passed' do
    exec('echo hi', :quiet => true).should == "hi\n"
    exec_output.string.should == ""
  end

  it 'will prefix output with the name if given' do
    exec('echo hi', :name => 'test').should == "hi\n"
    exec_output.string.should == "test: hi\n"

    exec('echo "cat\ndog"', :name => 'git').should == "cat\ndog\n"
    exec_output.string.should == "git: cat\ngit: dog\n"
  end

  it 'can be told to accept a non-zero exit status' do
    exec('false', :status => 1)

    lambda { exec('false') }.
      should raise_exception(MSPRelease::Exec::UnexpectedExitStatus)

    lambda { exec('true', :status => 1) }.
      should raise_exception(MSPRelease::Exec::UnexpectedExitStatus)
  end

  it 'can be told to accept any exit status' do
    exec('false', :status => :any)
    exec('true', :status => :any)
  end

  it 'can be told to accept statuses from a list' do
    exec('sh -c "exit 0"', :status => [0, 2, 3])
    exec('sh -c "exit 2"', :status => [0, 2, 3])
    exec('sh -c "exit 3"', :status => [0, 2, 3])

    lambda { exec('sh -c "exit 1"', :status => [0, 2, 3]) }.
      should raise_exception(MSPRelease::Exec::UnexpectedExitStatus)

  end
end
