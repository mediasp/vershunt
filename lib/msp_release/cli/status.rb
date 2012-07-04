module MSPRelease
  class CLI::Status < CLI::Command

    include CLI::WorkingCopyCommand

    description "Print out discovered release state"

    def run
      bits = []

      if data_exists?
        load_data
        puts "Awaiting push.  Please update the changelog, then run msp_release push "
        bits.push(["Pending", data[:version]])
      else
        changelog_version = changelog.version

        bits.push(["Project says", msp_version]) if msp_version
        bits.push(["Release branch", on_release_branch?? git_version : nil])
        bits.push(["Changelog says", changelog_version])
      end

      bits.push(["Release commit", release_name_for_output])

      format_bits(bits)
    end

    private

    def format_bits(bits)
      bits = bits.map {|header, value| [header, value.nil?? '<none>' : value.to_s ]}
      widths = bits.transpose.map { |column| column.map {|v| v.length }.max }
      bits.each do |row|
        puts row.zip(widths).map {|val, width| val.ljust(width) }.join(" : ").strip
      end
    end

    def release_name_for_output
      commit = git.latest_commit(project)
      commit.release_commit? && commit.release_name || nil
    end
  end
end
