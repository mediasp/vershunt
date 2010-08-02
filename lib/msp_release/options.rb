require 'optparse'

class MSPRelease::Options

  def self.get(args)
    opt = new(args)
    [opt, args]
  end

  def initialize(args)
    args
    @store = {}
    opts = OptionParser.new do |opts|
    end
  end

  def [](key)
    @store[key]
  end

  def []=(key, value)
    $stderr.puts("Warning, overiding config key #{key}") if @store[key]
    @store[key] = value
  end
end
