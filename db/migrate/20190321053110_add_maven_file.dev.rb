# This migration comes from dev (originally 20190321050837)
class AddMavenFile < ActiveRecord::Migration[5.2]
  def change
    drop_table :dev_maven_artifacts
    
    create_table :dev_maven_artifacts do |t|
      t.string :path
      t.string :group
      t.string :artifact

      t.string :metadata
      t.string :metadata_md5
      t.string :metadata_sha1

      t.timestamps
    end

    add_index :dev_maven_artifacts, [:group, :artifact], :unique => true

    create_table :dev_maven_versions do |t|
      t.belongs_to :dev_maven_artifact, index: true, foreign_key: true

      t.string :path
      t.string :version

      t.timestamps
    end

    add_index :dev_maven_versions, [:dev_maven_artifact_id, :version], :unique => true

    create_table :dev_maven_files do |t|
      t.belongs_to :dev_maven_version, index: true, foreign_key: true

      t.string :path
      t.string :name
      t.string :md5
      t.string :sha1

      t.timestamps
    end

    add_index :dev_maven_files, [:dev_maven_version_id, :name], :unique => true
  end
end
