module Dev
  class MavenFrcdep < ApplicationRecord
    def fullpath
      "#{group}:#{name}"
    end
  end
end