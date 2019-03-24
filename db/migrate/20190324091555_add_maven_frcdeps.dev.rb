# This migration comes from dev (originally 20190324091334)
class AddMavenFrcdeps < ActiveRecord::Migration[5.2]
  def change
    create_table :dev_maven_frcdeps do |t|
      t.string :uuid
     
      t.string :name
      t.string :filename
      t.string :version
      t.string :json
    end
  end
end

