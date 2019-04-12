# This migration comes from dev (originally 20190412134028)
class CreateDevDeployTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :dev_deploy_tokens do |t|
      t.references :dev_user, index: true, foreign_key: true
      t.string :token

      t.timestamps
    end
    add_index :dev_deploy_tokens, :token, unique: true
  end
end
