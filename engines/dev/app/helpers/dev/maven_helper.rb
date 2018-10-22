module Dev
  module MavenHelper
    FILESIZE_PREFIXES = %w{k M G T P E Z Y}
    def filesize bytes
        if bytes < 1000
           bytes.to_s + "B"
        else
            pos = (Math.log(bytes) / Math.log(1000)).floor
            pos = FILESIZE_PREFIXES.size - 1 if pos > FILESIZE_PREFIXES.size-1

            unit = FILESIZE_PREFIXES[pos-1] + "B"
            (bytes.to_f / 1000**pos).round(2).to_s + unit
        end
    end
  end
end
