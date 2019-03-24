module Dev
  class MavenVersion < ApplicationRecord
    belongs_to :maven_artifact, foreign_key: :dev_maven_artifact_id
    has_many :maven_files, foreign_key: :dev_maven_version_id
  end
end
