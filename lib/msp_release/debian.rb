class Debian

  DEFAULT_PATH = "debian/msp/changelog"

  def initialize(basedir, fname=DEFAULT_PATH)
    @fname = File.join(basedir, fname)
  end

  attr_reader :fname

  def read_top_line
    File.open(@fname, 'r') {|f|f.readline}
  end

  def version_bits
    tline = read_top_line
    match = /msp \(([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([^)]*)\))/.match(tline)
    (1..4).map{|i| match[i] }
  end

  def version_and_suffix
    maj, min, bf, bumf = version_bits
    [MSPRelease::Version.new(maj, min, bf), bumf]
  end

  def matches(version)
    deb_version, bumf = version_and_suffix
    deb_version == version
  end

  def bump(version, extra=MSPRelease.timestamp)
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

  def add(v, stub, extra=MSPRelease.timestamp)
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
    tline = "msp (#{v.major}.#{v.minor}.#{v.bugfix}"
    tline += "-" + extra if extra

    # FIXME, un-hardcode this?
    tline + ") unstable; urgency=low"
  end


end
