require 'json'

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

    # From https://stackoverflow.com/a/4136485, because I'm lazy
    def humanize_time secs
      [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)

          "#{n.to_i} #{name}" unless n.to_i==0
        end
      }.compact.reverse.join(' ')
    end

    def zip_tmp_extract entry, &block
      tf = Tempfile.new(entry.name)
      begin
        entry.extract(tf.path) { true }
        block.call(tf.path)
      ensure
        tf.close
        tf.unlink
      end
    end

    def upload_frcdeps_file file
      contents = File.read(file)
      json = JSON.parse!(contents)

      dep = MavenFrcdep.find_or_create_by(uuid: json["uuid"])
      dep.name = json["name"]
      dep.filename = json["fileName"]
      dep.version = json["version"]
      dep.json = contents
      dep.save
    end
  end
end
