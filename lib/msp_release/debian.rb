class Debian

  def initialize(basedir, fname)
    @fname = File.join(basedir, fname)
  end

  attr_reader :fname

  def read_top_line
    File.open(@fname, 'r') {|f|f.readline}
  end

  def package_name
    /[a-z\-]+/.match(read_top_line)
  end

  def version_bits
    tline = read_top_line
    match = /[a-z\-]+ \(([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([^)]*)\))/.match(tline)
    raise "couldn't read version info from #{tline}" unless match
    (1..4).map{|i| match[i] }
  end

  def version_and_suffix
    maj, min, bf, bumf = version_bits
    [MSPRelease::Version.new(maj, min, bf), bumf]
  end

  def version
    version_and_suffix.first
  end

  def matches(version)
    deb_version, bumf = version_and_suffix
    deb_version == version
  end

  def amend(version, extra=MSPRelease.timestamp)
    # replace the first line
    tline, *all = File.open(@fname, 'r') {|f|f.readlines}
    cur_version = /^[^\(]+\(([^\)]+).+/.match(tline)[1]
    tline = tline.gsub(cur_version, "#{version.format}-#{extra}")
    all.unshift(tline)

    signoff_idx = all.index {|l| /^ -- .+$/.match(l) }
    all[signoff_idx] = create_signoff

    File.open(@fname, 'w') { |f| all.each {|l|f.puts(l) } }

    [version, extra]
  end

  def add(v, stub, extra=nil)
    extra = MSPRelease.timestamp unless extra

    tline = create_top_line(v, extra)
    all = File.open(@fname, 'r') {|f| f.readlines }
    new =
      [
       tline,
       "",
       "  * #{stub}",
       "",
       create_signoff + "\n",
       ""
      ]

    File.open(@fname, 'w') {|f| f.write(new.join("\n")); f.write(all.join) }

    [v, extra]
  end

  def create_signoff
    date = MSPRelease.time_rfc
    author = MSPRelease.author
    " -- #{author.name} <#{author.email}>  #{date}"
  end

  def create_top_line(v, extra=nil)
    tline = "#{package_name} (#{v.major}.#{v.minor}.#{v.bugfix}"
    tline += "-" + extra if extra

    # FIXME, un-hardcode this?
    tline + ") unstable; urgency=low"
  end


end
