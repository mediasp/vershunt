require 'thread'
require 'popen4'

module MSPRelease
  class Exec

    class UnexpectedExitStatus < StandardError
      def initialize(expected, actual, cmd, output, stdout, stderr)
        @expected = expected
        @actual = actual
        @command = cmd
        @stdout = stdout
        @stderr = stderr
        super("command '#{command}' exited with #{actual}, expected #{expected}")
      end

      attr_reader :expect, :actual, :command, :output, :stdout, :stderr
      # this marries up with what popen et al return
      alias :exitstatus :actual
    end

    module Helpers
      def exec(command, options={})
        # use the options we were constructed with if they exist
        if respond_to?(:options)
          options[:quiet] = !self.options.verbose? unless options.has_key? :quiet
        end

        if respond_to? :exec_name
          options[:name] = exec_name unless options.has_key? :name
        end

        MSPRelease::Exec.exec(command, options)
      end
    end

    def self.exec(command, options={})
      new(options).exec(command, options)
    end

    attr_reader :name

    def initialize(options={})
      @name   = options.fetch(:name,   nil)
    end

    def last_stdout
      @last_stdout
    end

    def last_stderr
      @last_stderr
    end

    def last_output
      @last_output
    end

    def last_exitstatus
      @last_exitstatus
    end

    def exec(command, options={})

      expected = to_expected_array(options.fetch(:status, 0))

      @last_stdout = ""
      @last_stderr = ""
      @last_output = ""

      output_semaphore = Mutex.new

      start = name.nil? ? '' : "#{name}: "

      status = POpen4::popen4(command) do |stdout, stderr, stdin, pid|
        t1 = Thread.new do
          stdout.each_line do |line|
            @last_stdout += line
            output_semaphore.synchronize { @last_output += line }
            LOG.debug("#{start}#{line}")
          end
        end

        t2 = Thread.new do
          stderr.each_line do |line|
            @last_stderr += line
            output_semaphore.synchronize { @last_output += line }
            LOG.error("#{start}#{line}")
          end
        end

        t1.join
        t2.join
      end

      @last_exitstatus = status.exitstatus

      unless expected.nil? || expected.include?(status.exitstatus)
        raise UnexpectedExitStatus.new(expected, status.exitstatus, command, @last_output, @last_stdout, @last_stderr)
      end

      @last_stdout
    end

    private

    def to_expected_array(value)
      case value
      when :any   then nil
      when Array  then value
      when Numeric then [value]
      else raise ArgumentError, "#{value} is not an acceptable exit status"
      end
    end
  end
end
