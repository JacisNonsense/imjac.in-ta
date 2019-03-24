module Dev
  class MavenFile < ApplicationRecord
    belongs_to :maven_version, foreign_key: :dev_maven_version_id

    has_one_attached :file
  end
end
