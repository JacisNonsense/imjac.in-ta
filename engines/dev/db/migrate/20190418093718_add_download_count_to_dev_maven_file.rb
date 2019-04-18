class AddDownloadCountToDevMavenFile < ActiveRecord::Migration[5.2]
  def change
    add_column :dev_maven_files, :download_count, :integer, default: 0
  end
end
