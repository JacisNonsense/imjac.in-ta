module Dev
  class MavenArtifact < ApplicationRecord
    has_many :maven_versions, foreign_key: :dev_maven_artifact_id
  end
end
