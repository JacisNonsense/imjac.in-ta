# This migration comes from dev (originally 20190412142532)
class AddDescriptionToDevDeployToken < ActiveRecord::Migration[5.2]
  def change
    add_column :dev_deploy_tokens, :description, :string
  end
end
