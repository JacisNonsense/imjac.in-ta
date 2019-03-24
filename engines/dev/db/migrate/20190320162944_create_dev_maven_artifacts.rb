class CreateDevMavenArtifacts < ActiveRecord::Migration[5.2]
  def change
    create_table :dev_maven_artifacts do |t|
      t.string :group
      t.string :name
      t.string :version
      t.string :path

      t.timestamps

    end
    add_index :dev_maven_artifacts, [:group, :name, :version], :unique => true
  end
end
