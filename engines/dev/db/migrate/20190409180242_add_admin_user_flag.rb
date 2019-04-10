class AddAdminUserFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :dev_users, :admin, :boolean, default: false
  end
end
