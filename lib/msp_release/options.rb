require 'optparse'

class MSPRelease::Options

  def self.get(given_args)
    args = given_args.clone
    opt = new(args)
    [opt, args]
  end

  def initialize(args)
    @store = {
      :verbose => false
    }
    opts = OptionParser.new do |opts|
      opts.on("-v", "--[no-]verbose", "Run with verbose output") do |v|
        @store[:verbose] = v
      end
    end.parse!(args)
  end

  def [](key)
    @store.fetch(key)
  end

  def []=(key, value)
    $stderr.puts("Warning, overiding config key #{key}") if @store[key]
    @store[key] = value
  end

  def verbose?
    self[:verbose]
  end

end
