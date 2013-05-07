# simple class for keeping output in one place
module MSPRelease
  class Log
    @@log_levels = {
      :error => $stderr,
      :warn => $stderr,
      :info => $stdout,
      :debug => StringIO.new,
      :trace => StringIO.new
    }

    def initialize
    end

    def verbose
      @@log_levels[:debug] = $stdout
    end

    def noisy
      @@log_levels[:debug] = $stderr
    end

    def silent
      @@log_levels.keys.each do |level|
        @@log_levels[level] = StringIO.new
      end
    end

    @@log_levels.keys.each do |level|
      define_method level do |msg|
        @@log_levels[level].puts(msg)
      end

      define_method "set_#{level}" do
        @@log_levels[level] = $stdout
      end

      define_method "set_#{level}_err" do
        @@log_levels[level] = $stderr
      end

      define_method "unset_#{level}" do
        @@log_levels[level] = self.nil_log
      end
    end

  end
end
